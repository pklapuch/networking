//
//  APIQueuedSignOperation.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public class APIQueuedSignOperation: NSObject {
    
    public let urlRequest: URLRequest
    public let onSuccess: SignBlock
    public let onFailure: ErrorBlock
    
    public init(urlRequest: URLRequest, onSuccess:@escaping SignBlock, onFailure:@escaping ErrorBlock) {
        
        self.urlRequest = urlRequest
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
}
