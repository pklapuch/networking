//
//  APITestAuthStore.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
@testable import Networking

class APITestAuthStore: NSObject, APICredentialStoreProtocol {

    var storedToken: APISessionTokenProtocol?
    
    init(token: APISessionTokenProtocol? = nil) {
        self.storedToken = token
    }
    
    func store(token: APISessionTokenProtocol, onSuccess:@escaping VoidBlock, onError:@escaping ErrorBlock) {
        
        self.storedToken = token
        onSuccess()
    }
    
    func token(onSuccess:@escaping OptionalTokenBlock, onError:@escaping ErrorBlock) {
        
        onSuccess(storedToken)
    }
    
    func invalidate(onCompleted: VoidBlock) {

        self.storedToken = nil
        onCompleted()
    }
}
