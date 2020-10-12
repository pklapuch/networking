//
//  HTTPQuerySerializer.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public struct HTTPQuerySerializer {

    enum Error: CustomNSError, LocalizedError {
        
        case invalidFormat
        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Data cannot be represented as url query"
            }
        }
    }
    
    public init() {
        
    }
    
    public func encode(object: Any) throws -> Data {
        
        guard let dictionary = object as? [String: String] else { throw Error.invalidFormat }
        
        let items = try dictionary.map { item -> URLQueryItem in
            
            if let value = item.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URLQueryItem(name: item.key, value: value)
            } else {
                throw Error.invalidFormat
            }
        }
        
        let components = URLComponents.create(with: items)
        
        if let data = components.query?.data(using: .utf8) {
            return data
        } else {
            throw Error.invalidFormat
        }
    }
    
    public func decode(_ data: Data) throws -> [String: Any] {
        
        guard let query = String(data: data, encoding: .utf8) else { throw Error.invalidFormat }
        
        let keyValues = query.components(separatedBy: "&")
        var dict = [String: Any]()
        keyValues.forEach {
            
            let components = $0.components(separatedBy: "=")
            if components.count == 2 {
                dict[components[0]] = components[1]
            }
        }
        
        return dict
    }
}

extension URLComponents {
    
    fileprivate static func create(with queryItems: [URLQueryItem]) -> URLComponents {
        
        var components = URLComponents()
        components.queryItems = queryItems
        return components
    }
}
