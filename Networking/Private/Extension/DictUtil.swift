//
//  DictUtil.swift
//  Networking
//
//  Created by Pawel Klapuch on 11/22/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class DictUtil {
    
    static func json(info: [String: Any]?) -> String? {
        
        guard let info = info else { return nil }
        
        let descriptions = info.map { "\($0.key): \(String(describing: $0.value))" }
            
        return descriptions.joined(separator: "; ")
    }
}
