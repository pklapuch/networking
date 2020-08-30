//
//  APISessionTask.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

class APISessionTask: NSObject {
    
    var task: URLSessionTask? = nil
    var resolver: Resolver<(Data?, URLResponse?)>?
    var cancelled: Bool
    
    init(request: URLRequest, session: URLSession) {
        
        cancelled = false
        super.init()
        
        task = session.dataTask(with: request) { [weak self] (data, urlResopnse, error) in
            self?.taskDidComplete(data: data, urlResponse: urlResopnse, error: error)
        }
    }
    
    typealias RET = (Data?, URLResponse?)
    func resume() -> Promise<RET> {
        
        return Promise<RET> { [weak self] r in
            self?.resolver = r
            self?.task?.resume()
        }
    }
    
    func cancel() {
        guard !cancelled else { return }
        cancelled = true
        task?.cancel()
    }
    
    private func taskDidComplete(data: Data?, urlResponse: URLResponse?, error: Swift.Error?) {
        
        if let error = error {
            resolver?.reject(error)
        } else {
            resolver?.fulfill((data, urlResponse))
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
        
        return formattedJSON ?? String(data: data, encoding: .utf8) ?? data.hexString
    }
}
