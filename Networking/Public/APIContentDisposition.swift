//
//  APIContentDisposition.swift
//  Networking
//
//  Created by Pawel Klapuch on 9/30/20.
//

import Foundation

public struct ContentDisposition {
    
    private(set) var content: String
    
    public init() {
        
        content = "Content-Disposition: form-data"
    }
    
    public mutating func add(key: String, value: String) {
        
        content.append("; \(key)=\"\(value)\"")
    }
}
