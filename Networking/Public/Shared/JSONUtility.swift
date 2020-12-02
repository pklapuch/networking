//
//  JSONUtility.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct JSONUtility {
    
    enum Error: CustomNSError {
        
        case dataDoesNotContainJsonArray
        case modelNotEncodable
    }
    
    static func decode<T: Decodable>(data: Data, type: T.Type) throws -> T {
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    static func decodeArray<T: Decodable>(data: Data, type: T.Type) throws -> [T] {
        
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        guard let jsonArray = json as? [[String : Any]] else { throw Error.dataDoesNotContainJsonArray }
    
        let dataArray = try jsonArray.map { try JSONSerialization.data(withJSONObject: $0, options: .prettyPrinted) }
        
        return try dataArray.map { try JSONUtility.decode(data: $0, type: T.self) }
    }
    
    static func encode<T: Encodable>(object: T) throws -> Data {
        
        return try JSONEncoder().encode(object)
    }
    
    static func encodeJson<T: Encodable>(object: T) throws -> [String: Any] {
        
        let data = try encode(object: object)
        
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        guard let jsonDict = json as? [String: Any] else { throw Error.modelNotEncodable }
        
        return jsonDict
    }
}
