//
//  APIQueuedSession.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class APIQueuedSession: NSObject {
    
    let onSuccess: TokenBlock
    let onError: ErrorBlock
    
    init(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock) {
        
        self.onSuccess = onSuccess
        self.onError = onError
    }
}
