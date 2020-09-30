//
//  APILogging.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public enum APILoggingType {
    
    case debug
    
    case info
    
    case error
}

public protocol APILogging {
    
    func apiLog(message: String, type: APILoggingType)
}
