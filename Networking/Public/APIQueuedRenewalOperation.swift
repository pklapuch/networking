//
//  APIQueuedRenewalOperation.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/7/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public class APIQueuedRenewalOperation: NSObject {
    
    public let onSuccess: VoidBlock
    public let onFailure: ErrorBlock
    
    public init(onSuccess:@escaping VoidBlock, onFailure:@escaping ErrorBlock) {
        
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
}
