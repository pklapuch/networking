//
//  APIAuthManager.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

class APIAuthManager: NSObject {
    
    enum Error: CustomNSError, LocalizedError {
        
        case authenticationRequired
        case cancelled
        
        static var errorDomain: String { return "APIAuthManager.Error" }
        
        var errorCode: Int {
            switch self {
            case .authenticationRequired: return 0
            case .cancelled: return 1
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .authenticationRequired: return "Authentication required"
            case .cancelled: return "Authentication cancelled"
            }
        }
    }

    private let queue = DispatchQueue(label: "auth_manager")
    private let authenticator: APITokenActionProtocol
    private let store: APICredentialStoreProtocol
    
    private var queuedSessions = [APIQueuedSession]()
    private var isRefreshing = false
    private var failedAttempts = 0
    
    init(authenticator: APITokenActionProtocol, store: APICredentialStoreProtocol) {
        self.authenticator = authenticator
        self.store = store
    }
    
    func refresh() -> Promise<APISessionTokenProtocol> {
        
        return Promise<APISessionTokenProtocol> { resolver in

            self.queue.async {

                self.refreshOrQueue(resolver: resolver)
            }
        }
    }
    
    func getCurrentToken() -> Promise<APISessionTokenProtocol> {
        
        return Promise<APISessionTokenProtocol> { resolver in
            
            self.queue.async {
                
                self.getCurrentTokenOrQueue(resolver: resolver)
            }
        }
    }
}

extension APIAuthManager {
    
    private func refreshOrQueue(resolver: Resolver<APISessionTokenProtocol>) {

        queuedSessions.append(APIQueuedSession(resolver: resolver))

        if isRefreshing  {

            APINetworking.log?.log(message: "refresh token in progress -> wait", type: .info)

        } else {

            if failedAttempts > 0 {

                APINetworking.log?.log(message: "refresh token has failed too many times -> critial error", type: .info)
                notify(error: Error.authenticationRequired)

            } else {

                APINetworking.log?.log(message: "execute refresh token", type: .info)
                isRefreshing = true
                executeRefresh()
            }
        }
    }
    
     private func notify(newToken: APISessionTokenProtocol) {

         self.queue.async {

             self.isRefreshing = false
             self.queuedSessions.forEach { $0.resolver.fulfill(newToken) }
             self.queuedSessions.removeAll()
         }
     }

     private func notify(error: Swift.Error) {

         self.queue.async {

             self.isRefreshing = false
             self.queuedSessions.forEach { $0.resolver.reject(error) }
             self.queuedSessions.removeAll()
         }
     }
    
    private func getCurrentTokenOrQueue(resolver: Resolver<APISessionTokenProtocol>) {

        if isRefreshing {

            queuedSessions.append(APIQueuedSession(resolver: resolver))

        } else {

            store.token().then { token in

                self.authenticator.validate(token: token)

            }.done { token in

                resolver.fulfill(token)

            }.catch { error in

                resolver.reject(Error.authenticationRequired)
            }
        }
    }
    
    private func executeRefresh() {
        
        store.token().then { [weak self] token -> Promise<APISessionTokenProtocol> in
            
            guard let self = self else { throw Error.cancelled}
            return self.authenticator.validate(token: token)

        }.then { [weak self] token -> Promise<APISessionTokenProtocol> in
            
            guard let self = self else { throw Error.cancelled}
            return self.authenticator.refresh(token: token)

        }.then { [weak self] newToken -> Promise<APISessionTokenProtocol> in

            guard let self = self else { throw Error.cancelled}
            return self.authenticator.validate(token: newToken)

        }.then { [weak self] newToken -> Promise<APISessionTokenProtocol> in

            guard let self = self else { throw Error.cancelled}
            return self.store.store(token: newToken).map { newToken }

        }.done(on: self.queue) { [weak self] newToken in

            APINetworking.log?.log(message: "did refresh token", type: .info)
            guard let self = self else { throw Error.cancelled}
            self.failedAttempts = 0
            self.notify(newToken: newToken)

        }.catch(on: self.queue) { [weak self] error in

            APINetworking.log?.log(message: "did fail to refresh token", type: .info)
            guard let self = self else { return }
            
            self.failedAttempts += 1
            self.notify(error: error)
        }
    }
}
