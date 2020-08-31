//
//  APITestTokenParser.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
@testable import Networking

struct APITestTokenParser: APIModelParsing {
    
    func decode(data: Data) throws -> Codable? {
        
        return try JSONUtility.decode(data: data, type: APITestSessionToken.self)
    }
}
