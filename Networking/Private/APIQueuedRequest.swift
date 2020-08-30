//
//  APIQueuedRequest.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class APIQueuedRequest {
    
    let request: APIRequest
    let callback: APIRequest.APICallback
    
    init(request: APIRequest, callback: APIRequest.APICallback) {
        self.request = request
        self.callback = callback
    }
    
    var ID: String { return request.identifier }
}
