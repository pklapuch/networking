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
                
                var urlSafeValue = value
                if urlSafeValue.contains("+") {
                    urlSafeValue = urlSafeValue.replacingOccurrences(of: "+", with: "%2B")
                }
                
                return URLQueryItem(name: item.key, value: urlSafeValue)
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
            
            if let separatorIndex = $0.firstIndex(of: "=") {
                
                let key = String($0[$0.startIndex..<separatorIndex])
                
                let separatorIndexInt = $0.distance(from: $0.startIndex, to: separatorIndex)
                let valueFirstIndexInt = separatorIndexInt + 1
                let lastIndexInt = $0.distance(from: $0.startIndex, to: $0.endIndex) 
                let valueLength = lastIndexInt - valueFirstIndexInt
                
                if (valueLength > 0) {
                
                    let startIndex = $0.index($0.startIndex, offsetBy: valueFirstIndexInt)
                    let endIndex = $0.endIndex
                    
                    let value = String($0[startIndex..<endIndex])
                    
                    var urlUnsafeValue = value
                    if urlUnsafeValue.contains("%2B") {
                        urlUnsafeValue = urlUnsafeValue.replacingOccurrences(of: "%2B", with: "+")
                    }
                    
                    dict[key] = urlUnsafeValue
                    
                } else {
                    
                    dict[key] = ""
                }
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
