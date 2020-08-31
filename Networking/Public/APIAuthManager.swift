//
//  APIAuthManager.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public class APIAuthManager: NSObject {
    
    public enum Error: CustomNSError, LocalizedError {
        
        case authenticationRequired
        case cancelled
        
        public static var errorDomain: String { return "APIAuthManager.Error" }
        
        public var errorCode: Int {
            switch self {
            case .authenticationRequired: return 0
            case .cancelled: return 1
            }
        }
        
        public var errorDescription: String? {
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
    
    public init(authenticator: APITokenActionProtocol, store: APICredentialStoreProtocol) {
        self.authenticator = authenticator
        self.store = store
    }
}

extension APIAuthManager: APIAuthenticating {
    
    public func refresh(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
        queue.async { [weak self] in
            self?.refreshOrQueue(onSuccess: onSuccess, onError: onError)
        }
    }
    
    public func getCurrentToken(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
        self.queue.async { [weak self] in
            self?.getCurrentTokenOrQueue(onSuccess: onSuccess, onError: onError)
        }
    }
}

extension APIAuthManager {
    
    private func refreshOrQueue(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {

        queuedSessions.append(APIQueuedSession(onSuccess: onSuccess, onError: onError))

        if isRefreshing  {

            APINetworking.log?.apiLog(message: "refresh token in progress -> wait", type: .info)

        } else {

            if failedAttempts > 0 {

                APINetworking.log?.apiLog(message: "refresh token has failed too many times -> critial error", type: .info)
                notify(error: Error.authenticationRequired)

            } else {

                APINetworking.log?.apiLog(message: "execute refresh token", type: .info)
                isRefreshing = true
                executeRefresh()
            }
        }
    }
    
    private func getCurrentTokenOrQueue(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {

        if isRefreshing {
            queuedSessions.append(APIQueuedSession(onSuccess: onSuccess, onError: onError))
        } else {
            store.token(onSuccess: { [weak self] token in
                self?.authenticator.validate(token: token, onSuccess: onSuccess, onError: onError)
            }, onError: onError)
        }
    }
    
    private func executeRefresh() {
        
        store.token(onSuccess: { [weak self] storedToken in
            
            if let storedToken = storedToken {
                self?.didLoad(storedToken: storedToken)
            } else {
                self?.executeRefreshDidFail(with: Error.authenticationRequired)
            }
        }, onError: executeRefreshDidFail(with:))
    }
    
    private func didLoad(storedToken: APISessionTokenProtocol) {
        
        authenticator.validate(token: storedToken, onSuccess: { [weak self] token in
            self?.didValidate(storedToken: token)
        }, onError: executeRefreshDidFail(with:))
    }
    
    private func didValidate(storedToken: APISessionTokenProtocol) {
    
        authenticator.refresh(token: storedToken, onSuccess: { [weak self] token in
            self?.didObtain(newToken: token)
        }, onError: executeRefreshDidFail(with:))
    }
    
    private func didObtain(newToken: APISessionTokenProtocol) {
        
        authenticator.validate(token: newToken, onSuccess: { [weak self] token in
            self?.didValidate(newToken: token)
        }, onError: executeRefreshDidFail(with:))
    }
        
    private func didValidate(newToken: APISessionTokenProtocol) {
     
        store.store(token: newToken, onSuccess: { [weak self] in
            self?.didStore(newToken: newToken)
        }, onError: executeRefreshDidFail(with:))
    }
    
    private func didStore(newToken: APISessionTokenProtocol) {
        
        queue.async { [weak self] in
            
            APINetworking.log?.apiLog(message: "did refresh token", type: .info)
            self?.failedAttempts = 0
            self?.notify(newToken: newToken)
        }
    }
    
    private func executeRefreshDidFail(with error: Swift.Error) {
        
        queue.async { [weak self] in
            
            APINetworking.log?.apiLog(message: "did fail to refresh token", type: .info)
            self?.failedAttempts += 1
            self?.notify(error: error)
        }
    }
    
    private func notify(newToken: APISessionTokenProtocol) {

        self.queue.async {

            self.isRefreshing = false
            self.queuedSessions.forEach { $0.onSuccess(newToken) }
            self.queuedSessions.removeAll()
        }
    }

    private func notify(error: Swift.Error) {

        self.queue.async {

            self.isRefreshing = false
            self.queuedSessions.forEach { $0.onError(error) }
            self.queuedSessions.removeAll()
        }
    }
}
