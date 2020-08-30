//
//  APIQueuedSession.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import UIKit
import PromiseKit

class APIQueuedSession: NSObject {

    let resolver: Resolver<APISessionTokenProtocol>
    
    init(resolver: Resolver<APISessionTokenProtocol>) {
        
        self.resolver = resolver
    }
}
