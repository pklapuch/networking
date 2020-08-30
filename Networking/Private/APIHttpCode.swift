//
//  HTTPStatusGroup.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

enum APIHttpCode {

    case group2xx
    case group3xx
    case group4xx
    case group5xx
    case unknown
    
    static func create(from value: Int?) -> APIHttpCode {
        
        guard let value = value else { return APIHttpCode.unknown }
        if (200...299).contains(value) { return APIHttpCode.group2xx }
        if (300...399).contains(value) { return APIHttpCode.group3xx }
        if (400...499).contains(value) { return APIHttpCode.group4xx }
        if (500...599).contains(value) { return APIHttpCode.group5xx }
        return APIHttpCode.unknown
    }
}
