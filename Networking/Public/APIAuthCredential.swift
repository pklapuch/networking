//
//  APIAuthCredential.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public struct APIAuthCredential: Codable {

    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        
        self.username = username
        self.password = password
    }
}
