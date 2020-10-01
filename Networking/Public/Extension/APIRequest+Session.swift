//
//  APIRequest+Session.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension APIRequest {
    
    func urlRequest(with url: URL, sessionHeaders: APIHTTPHeaders? = nil) throws -> URLRequest {
     
        var request = URLRequest(url: url,
                                 cachePolicy: policy,
                                 timeoutInterval: TimeInterval(timeout))
        
        request.httpMethod = method.rawValue
        sessionHeaders?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.name) }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.name) }
        request.httpBody = try payload?.encode()
        
        return request
    }
    
    func parse(data: Data, httpGroupCode: APIHTTPGroupCode) throws -> Codable? {
     
        switch httpGroupCode {

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

