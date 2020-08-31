//
//  AuthTests.swift
//  Tests
//
//  Created by Pawel Klapuch on 28/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import XCTest
@testable import Networking

class AuthTests: XCTestCase {

    var expectation: XCTestExpectation!
    
    let credential = APIAuthCredential(username: "pkl_test_ios_user", password: "test1234")
    let authenticator = APITestAuthenticator(session: APISession(configuration: URLSessionConfiguration.default))
    var authManager: APIAuthManager?
    
    override func setUp() {
        
        expectation = XCTestExpectation(description: "session")
        APINetworking.log = TestAPILogger()
    }
    
    func test() throws {
        
        authenticator.authenticate(credential: credential, onSuccess: { [weak self] token in
            self?.didAuthenticate(token: token)
        }) { _ in
            XCTFail()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    private func didAuthenticate(token: APISessionTokenProtocol) {
        
        let store = APITestAuthStore(token: token)
        self.authManager = APIAuthManager(authenticator: authenticator, store: store)
        
        self.authManager!.refresh(onSuccess: { newToken in
            self.expectation.fulfill()
        }) { _ in
            XCTFail()
        }
    }
}

extension AuthTests: APISessionPinning {
    
    func evaluate(host: String, certificates: [Data]) -> Bool {
        
        return true
    }
}
