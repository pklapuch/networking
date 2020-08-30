//
//  AuthTests.swift
//  Tests
//
//  Created by Pawel Klapuch on 28/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import XCTest
import PromiseKit
@testable import Networking

class AuthTests: XCTestCase {

    var expectation: XCTestExpectation!
    var authManager: APIAuthManager?
    
    func test() throws {
        
        expectation = XCTestExpectation(description: "session")
        APINetworking.log = TestAPILogger()
        
        let credential = APIAuthCredential(username: "pkl_test_ios_user", password: "test1234")
        let authSession = APISession(configuration: URLSessionConfiguration.default)
        
        let authenticator = APITestAuthenticator(session: authSession)
        
        authenticator.authenticate(credential: credential).then { token -> Promise<APISessionTokenProtocol> in
            
            let store = APITestAuthStore(token: token)
            self.authManager = APIAuthManager(authenticator: authenticator, store: store)
            return self.authManager!.refresh()
            
        }.done { token in
            
            self.expectation.fulfill()
            
        }.catch { error in
            
            XCTFail()
        }
    
        wait(for: [expectation], timeout: 5)
    }
}

extension AuthTests: APISessionPinning {
    
    func evaluate(host: String, certificates: [Data]) -> Bool {
        
        return true
    }
}
