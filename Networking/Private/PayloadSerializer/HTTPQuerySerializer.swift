//
//  HTTPQuerySerializer.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct HTTPQuerySerializer {

    enum Error: CustomNSError, LocalizedError {
        
        case invalidFormat
        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Data cannot be represented as url query"
            }
        }
    }
    
    func encode(object: Any) throws -> Data {
        
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
}

extension URLComponents {
    
    fileprivate static func create(with queryItems: [URLQueryItem]) -> URLComponents {
        
        var components = URLComponents()
        components.queryItems = queryItems
        return components
    }
}
