//
//  APITestAuthenticateRequest.swift
//  Tests
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
@testable import Networking

class APITestAuthenticateRequest: APIRequest {

    convenience init(credential: APIAuthCredential) throws {
        
        let path = "https://pkl.westeurope.cloudapp.azure.com/iam/auth/realms/device-realm/protocol/openid-connect/token"
        
        let object = ["username": credential.username,
                      "password": credential.password,
                      "grant_type": "password",
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
