//
//  PayloadUtility.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/2/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct PayloadUtility {
    
    static func getLogDescription(for data: Data?) -> String? {
        
        /** NOTE:
            This is preferential - but in short: if response is JSON, we might want to see the whole structure (regardless of length - as it's human readable)
            In other cases (content not readable - either raw bytes or encyrpted) let's limit output to specific length.
         */
        let outputMaxLengthIfNotJSON = 1000000
        
        guard let data = data else { return nil }
        var formattedJSON: String?
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if (!(json is NSNull) && json is [String: Any]) {
                
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let jsonString = String(data: prettyData, encoding: .utf8) {
                    return jsonString
                }
            }
        } catch { }
            
        if (formattedJSON == nil) {
            if let tmp = String(data: data, encoding: .utf8), !tmp.isEmpty {
                formattedJSON = tmp
            }
        }
        
        if (formattedJSON == nil) {
            formattedJSON = data.hexString
        }
        
        if let formattedJSON = formattedJSON {
            
            var output = "\(formattedJSON.prefix(outputMaxLengthIfNotJSON))"
            if formattedJSON.count > outputMaxLengthIfNotJSON {
                output.append("... (total bytes: \(data.count))")
            }
            return output
            
        } else {
            
            return "--"
        }
    }
}
