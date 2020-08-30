//
//  APISession+InternalError.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension APISession {
    
    private enum InternalError: CustomNSError {
        
        static var errorDomain: String { "APISession.InternalError" }
        var errorCode: Int {
            switch self {
            case .tokenExpired: return 1
            }
        }
        case tokenExpired
    }
}
