//
//  Error+NSError.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension Swift.Error {
    
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
