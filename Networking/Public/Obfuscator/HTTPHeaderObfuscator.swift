//
//  HTTPHeaderObfuscator.swift
//  Networking
//
//  Created by Pawel Klapuch on 2/15/21.
//  Copyright © 2021 Pawel Klapuch. All rights reserved.
//

import Foundation

open class HTTPHeaderObfuscator: APIHeaderLogging {
    
    private let substitute = "*"
    private let sensitiveKeys: [String]
    
    public init(sensitiveKeys: [String]) {
        
        self.sensitiveKeys = sensitiveKeys
    }
    
    open func getHeadersDescription(for headers: [String : String]) -> String? {
        
        return createDescription(headers: obfuscate(headers: headers))
    }
    
    private func obfuscate(headers: [String: String]) -> [String: String] {
        
        var obfuscated = headers
        sensitiveKeys.forEach { obfuscated[$0] = substitute }
        return obfuscated
    }
    
    public func createDescription(headers: [String: String]) -> String {
        
        let components = headers.map { "\($0.key): \($0.value)" }
        return components.joined(separator: "; ")
    }
}
