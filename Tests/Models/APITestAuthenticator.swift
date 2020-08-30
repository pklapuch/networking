//
//  APITestAuthenticator.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit
@testable import Networking

class APITestAuthenticator: NSObject, APITokenActionProtocol {
    
    enum Error: CustomNSError {
        
        case invalidResponse
        case invalidToken
    }

    struct GrantType {
        static let password = "password"
        static let refresh = "refresh_token"
    }
    
    struct Key {
        static let clientID = "app-client"
    }
    
    let session: APISession
    
    init(session: APISession) {
        
        self.session = session
    }
    
    func authenticate(credential: APIAuthCredential) -> Promise<APISessionTokenProtocol> {
        
        do {
            
            let request = try APITestAuthenticateRequest(credential: credential)
            return session.execute(request).map { response -> APISessionTokenProtocol in
                
                if let token = response.model as? APITestSessionToken {
                    return token
                } else {
                    throw Error.invalidResponse
                }
            }
            
        } catch {
            return Promise<APISessionTokenProtocol>.instantError(error)
        }
    }
    
    func refresh(token: APISessionTokenProtocol) -> Promise<APISessionTokenProtocol> {
                   
        do {
            
            let request = try APITestRefreshTokenRequest(token: token)
            return session.execute(request).then { resposne in
                self.extract(from: resposne)
            }
            
        } catch {
            return Promise<APISessionTokenProtocol>.instantError(error)
        }
    }
    
    func extract(from response: APIResponse) -> Promise<APISessionTokenProtocol> {
        
        return Promise<APISessionTokenProtocol> { r in
            if let token = response.model as? APITestSessionToken {
                r.fulfill(token)
            } else {
                r.reject(Error.invalidResponse)
            }
        }
    }
    
    func validate(token: APISessionTokenProtocol?) -> Promise<APISessionTokenProtocol> {
        
        return Promise<APISessionTokenProtocol> { r in
         
            if let token = token {
                r.fulfill(token)
            } else {
                r.reject(Error.invalidToken)
            }
        }
    }
}
