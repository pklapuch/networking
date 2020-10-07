//
//  APISession+InternalError.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension APISession {
    
    enum InternalError: CustomNSError {
        
        static var errorDomain: String { "APISession.InternalError" }
        var errorCode: Int {
            switch self {
            case .signatureExpired: return 1
            }
        }
        
        case signatureExpired
    }
}
