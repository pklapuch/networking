//
//  APITestAuthStore.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit
@testable import Networking

class APITestAuthStore: NSObject, APICredentialStoreProtocol {
    
    var storedToken: APISessionTokenProtocol?
    
    init(token: APISessionTokenProtocol? = nil) {
        self.storedToken = token
    }
    
    func store(token: APISessionTokenProtocol) -> Promise<Void> {
     
        return Promise<Void> { r in
            self.storedToken = token
            r.fulfill_()
        }
    }
    
    func token() -> Promise<APISessionTokenProtocol?> {
        
        return Promise<APISessionTokenProtocol?> { r in
            r.fulfill(storedToken)
        }
    }
    
    func invalidate() -> Promise<Void> {
        return Promise<Void> { r in
            self.storedToken = nil
            r.fulfill_()
        }
    }
}
