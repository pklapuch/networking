//
//  APISessionTask.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class APISessionTask: NSObject {
    
    var task: URLSessionTask? = nil
    var urlRequest: URLRequest
    var onSuccess: URLResponseBlock?
    var onError: ErrorBlock?
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
    
    func getPayloadDescription() -> String {
        
        guard let task = task else { return "--" }
        guard let request = task.currentRequest else { return "" }
        guard let data = request.httpBody else { return "--" }
        
        
        var formattedJSON: String?
        if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
            if let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                formattedJSON = String(data: prettyData, encoding: .utf8)
            }
        }
        
        if let formattedJSON = formattedJSON {
            return formattedJSON
        }
        
        if data.count < 400 {
            
            if let value = String(data: data, encoding: .utf8), !value.isEmpty {
                return value
            } else {
                return data.hexString
            }
        } else {
            return "\(data.count) bytes"
        }
    }
}
