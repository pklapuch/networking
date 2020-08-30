//
//  User.swift
//  Tests
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct User: Codable {

    let firstName: String
    let lastName: String
    let age: Int
    
    enum CodingKeys: String, CodingKey {
        
        case firstName = "first_name"
        case lastName = "last_name"
        case age
    }
    
    
}
