//
//  APITestSessionToken.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
@testable import Networking

struct APITestSessionToken: Codable {

    let scope: String
    let tokenType: String
    let notBeforePolicy: Int
    let sessionState: String
    
    let refreshToken: String
    let accessToken: String
    
    let refreshExpiresIn: Double
    let expiresIn: Double
    
    enum CodingKeys : String, CodingKey {
        
        case scope
        case tokenType = "token_type"
        case notBeforePolicy = "not-before-policy"
        case sessionState = "session_state"
        
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
        case refreshExpiresIn = "refresh_expires_in"
        case expiresIn = "expires_in"
    }
    
    static func decode(data: Data) throws -> APITestSessionToken? {
        
        return try JSONUtility.decode(data: data, type: APITestSessionToken.self)
    }
}

extension APITestSessionToken: APISessionTokenProtocol {
    
    func getAccessToken() -> String { return accessToken }
    
    func getRefreshToken() -> String { return refreshToken }
}
