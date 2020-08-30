//
//  APIActiveRequest.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class APIActiveRequest {
    
    let request: APIRequest
    let callback: APIRequest.APICallback
    let sessionTask: APISessionTask
    
    init(request: APIRequest, sessionTask: APISessionTask, callback: APIRequest.APICallback) {
        self.request = request
        self.sessionTask = sessionTask
        self.callback = callback
    }
    
    var ID: String { return request.identifier }
}

extension APIActiveRequest {
    
    static func create(fromQueuedRequest queuedRequest: APIQueuedRequest, sessionTask: APISessionTask) -> APIActiveRequest {
        
        return APIActiveRequest(request: queuedRequest.request,
                                sessionTask: sessionTask,
                                callback: queuedRequest.callback)
    }
}
