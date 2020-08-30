//
//  APILogging.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

enum APILoggingType {
    
    case info
    
    case error
}

protocol APILogging {
    
    func log(message: String, type: APILoggingType)
}
