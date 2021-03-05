//
//  JSONPayloadObfuscator.swift
//  Networking
//
//  Created by Pawel Klapuch on 3/5/21.
//  Copyright © 2021 Pawel Klapuch. All rights reserved.
//

import Foundation

open class JSONPayloadObfuscator: APIPayloadLogging  {
    
    private let substitute = "*"
    private let sensitiveKeys: [String]
    
    public init(sensitiveKeys: [String]) {
        
        self.sensitiveKeys = sensitiveKeys
    }
    
    open func getPayloadDescription(for data: Data?) -> String? {
        
        guard let data = data else { return nil }
        guard var json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        
        obfuscate(json: &json)
        return createDescription(json: json)
    }
    
    private func obfuscate(json: inout [String: Any]) {
        
        sensitiveKeys.forEach { json[$0] = "*" }
    }
    
    private func createDescription(json: [String: Any]) -> String? {
        
        guard let data = try? JSONSerialization.data(withJSONObject: json,
                                                     options: .prettyPrinted) else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
}
