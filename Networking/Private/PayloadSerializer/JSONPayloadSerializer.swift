//
//  JSONPayloadSerializer.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct JSONPayloadSerializer {

    func encode(object: Any) throws -> Data {
        
        return try JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed)
    }
}
