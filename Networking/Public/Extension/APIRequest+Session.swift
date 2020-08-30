//
//  APIRequest+Session.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

extension APIRequest.APICallback {
    
    static func create(with resolver: Resolver<APIResponse>) -> APIRequest.APICallback {
        return APIRequest.APICallback(onSuccess: { response in
            resolver.fulfill(response)
        }) { error in
            resolver.reject(error)
        }
    }
}

extension APIRequest {
        
    func createURLRequest(sessionHeaders: APIHTTPHeaders? = nil) -> Promise<URLRequest> {
     
        return Promise<URLRequest> { r in
            
            do {
                
                var urlRequset = URLRequest(url: url,
                                            cachePolicy: policy,
                                            timeoutInterval: TimeInterval(timeout))
                
                urlRequset.httpMethod = method.rawValue
                sessionHeaders?.forEach { urlRequset.setValue($0.value, forHTTPHeaderField: $0.name) }
                headers.forEach { urlRequset.setValue($0.value, forHTTPHeaderField: $0.name) }
                urlRequset.httpBody = try payload?.encode()
                
                r.fulfill(urlRequset)
                
            } catch {
                
                r.reject(error)
            }
        }
    }
    
    func parse(data: Data, httpCode: APIHttpCode) throws -> Codable? {
     
        switch httpCode {

        case .group2xx: return try parseModel(data: data)
        case .group3xx, .unknown: return nil
        case .group4xx, .group5xx: return try parseError(data: data)
        }
    }
        
    func parseModel(data: Data) throws -> Codable? {
        return try modelParser?.decode(data: data)
    }
    
    func parseError(data: Data) throws -> Codable? {
        return try errorParser?.decode(data: data)
    }
    
    func getHeadersDescription() -> String {
        let params = headers.map { header -> String in return "\(header.name): \(header.value)" }
        return params.joined(separator: "; ")
    }
}

