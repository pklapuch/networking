//
//  Data+String.swift
//  Networking
//
//  Created by Pawel Klapuch on 9/30/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension Data {
    
    func toString(_ encoding: String.Encoding ) throws -> String {
        
        guard let value = String(data: self, encoding: encoding) else {
            throw DataError.invalidData
        }
        return value
    }
    
    static func from(text: String, encoding: String.Encoding) throws -> Data {
        
        guard let value = text.data(using: encoding) else {
            throw DataError.invalidData
        }
        return value
    }
}
