//
//  APITestAuthenticator.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
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
    
    func authenticate(credential: APIAuthCredential, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
    
        do {
            
            let request = try APITestAuthenticateRequest(credential: credential)
            
            session.execute(request, onSuccess: { response in
                
                if let token = response.model as? APITestSessionToken {
                    onSuccess(token)
                } else {
                    onError(Error.invalidResponse)
                }
                
            }, onError: onError)
            
        } catch {
            
            return onError(error)
        }
    }

    func refresh(token: APISessionTokenProtocol, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
                   
        do {
            
            let request = try APITestRefreshTokenRequest(token: token)
            
            session.execute(request, onSuccess: { response in
                
                if let token = response.model as? APITestSessionToken {
                    onSuccess(token)
                } else {
                    onError(Error.invalidResponse)
                }
                
            }, onError: onError)
            
        } catch {
            
            return onError(error)
        }
    }
    
    func extract(from response: APIResponse, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
    
        if let token = response.model as? APITestSessionToken {
            onSuccess(token)
        } else {
            onError(Error.invalidResponse)
        }
    }
    
    func validate(token: APISessionTokenProtocol?, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
        
        if let token = token {
            onSuccess(token)
        } else {
            onError(Error.invalidToken)
        }
    }
}
