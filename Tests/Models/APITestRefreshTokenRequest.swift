//
//  APITestRefreshTokenRequest.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
@testable import Networking

class APITestRefreshTokenRequest: APIRequest {

    convenience init(token: APISessionTokenProtocol) throws {
        
        let path = "iam/auth/realms/device-realm/protocol/openid-connect/token"
        
        let object = ["refresh_token": token.getRefreshToken(),
                      "grant_type": "refresh_token",
                      "client_id": "app-client"]
        
        let headers = APIHTTPHeaders(["Content-Type": "application/x-www-form-urlencoded"])
        
        try self.init(path: path,
                   method: .post,
                   payload: APIPayload.httpQuery(object),
                   headers: headers,
                   modelParser: APITestTokenParser(),
                   authentication: APIRequestAuthentication.none)
    }
}
