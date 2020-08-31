//
//  TestAPILogger.swift
//  Tests
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
@testable import Networking

class TestAPILogger: NSObject, APILogging {

    func apiLog(message: String, type: APILoggingType) {
        
        print("\(message)")
    }
}
