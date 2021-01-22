//
//  APISessionTask.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class APISessionTask: NSObject {
    
    var onSuccess: URLResponseBlock?
    var onError: ErrorBlock?
    
    var task: URLSessionTask? = nil
    var urlRequest: URLRequest
    var cancelled: Bool
        
    init(request: URLRequest, session: URLSession) {
        
        cancelled = false
        urlRequest = request
        super.init()
        
        task = session.dataTask(with: request) { [weak self] (data, urlResopnse, error) in
            self?.taskDidComplete(data: data, urlResponse: urlResopnse, error: error)
        }
    }
    
    func resume(onSuccess:@escaping URLResponseBlock, onError:@escaping ErrorBlock) {
        
        self.onSuccess = onSuccess
        self.onError = onError
        self.task?.resume()
    }
    
    func cancel() {
        guard !cancelled else { return }
        cancelled = true
        task?.cancel()
    }
    
    private func taskDidComplete(data: Data?, urlResponse: URLResponse?, error: Swift.Error?) {
        
        if let error = error {
            onError?(error)
        } else {
            onSuccess?((data, urlResponse))
        }
    }
    
    /** LOG -  OUT */
    func getPayloadDescription() -> String {
        
        guard let data = urlRequest.httpBody else { return "--" }
        return PayloadUtility.getLogDescription(for: data) ?? "--"
    }
}
