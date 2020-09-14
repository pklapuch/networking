//
//  Tests.swift
//  Tests
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import XCTest
@testable import Networking

class Tests: XCTestCase {
    
    var expectation: XCTestExpectation!

    func test() throws {
        
        expectation = XCTestExpectation(description: "session")
        APINetworking.log = TestAPILogger()
        
        let body = ["username": "tester",
                    "password": "password"]
        
        let request = APIRequest(url: URL(string: "https://pawelklapuch.pl/testAPI")!,
                                 method: .post,
                                 payload: .plainJSON(body),
                                 headers: APIHTTPHeaders(),
                                 authentication: APIRequestAuthentication.none)
        
        let session = APISession(configuration: URLSessionConfiguration.default)
        session.execute(request, onSuccess: { response in
            self.expectation.fulfill()
        }) { _ in
            XCTFail()
        }
        
        wait(for: [expectation], timeout: 5)
    }
}

//extension Tests {
//
//    fileprivate class TestModelParser: ModelParsing {
//        func decode(data: Data) throws -> Codable? {
//
//            return try JSONUtility.decodeArray(data: data, type: User.self)
//        }
//    }
//
//    fileprivate class TestErrorParser: ErrorParsing {
//        func decode(data: Data) throws -> Codable? {
//
//            return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? Codable
//        }
//    }
//}
