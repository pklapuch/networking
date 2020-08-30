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
        let request = APIRequest(url: URL(string: "https://learnappmaking.com/ex/users.json")!,
                                 method: .get,
                                 payload: nil,
                                 headers: APIRequest.HTTPHeaders(),
                                 modelParser: TestModelParser(),
                                 errorParser: TestErrorParser())
        
        let session = APISession(configuration: URLSessionConfiguration.default)
        session.execute(request).done { response in
            self.expectation.fulfill()
        }.catch { error in
            XCTFail()
        }

        wait(for: [expectation], timeout: 5)
    }
}

extension Tests {
    
    fileprivate class TestModelParser: ModelParsing {
        func decode(data: Data) throws -> Codable? {
            
            return try JSONUtility.decodeArray(data: data, type: User.self)
        }
    }
    
    fileprivate class TestErrorParser: ErrorParsing {
        func decode(data: Data) throws -> Codable? {
            
            return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? Codable
        }
    }
}
