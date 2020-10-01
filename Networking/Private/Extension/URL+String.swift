//
//  URL+String.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/1/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension URL {
    
    static func create(from path: String) throws -> URL {
        
        if let url = URL(string: path) {
            return url
        } else {
            throw URLError.invalidPath
        }
    }
}
