//
//  DataError.swift
//  Networking
//
//  Created by Pawel Klapuch on 9/30/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

enum DataError: CustomNSError {

    case invalidBase64String
    
    case invalidData
}
