//
//  APIPayload+Serializer.swift
//  Networking
//
//  Created by Pawel Klapuch on 28/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension APIPayload {
    
    func encode() throws -> Data {
        
        switch self {
            
        case .plainJSON(let object):
            return try JSONPayloadSerializer().encode(object: object)
            
        case .httpQuery(let object):
            return try HTTPQuerySerializer().encode(object: object)
            
        case .custom(let data):
            return data
        }
    }
}
