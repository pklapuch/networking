//
//  Request.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

open class APIRequest: NSObject {
    
    struct Configuration {
        
        static let defaultCachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        static let defaultTimeoutSeconds = 60
    }
    
    public let identifier: String
    public let path: String
    
    let method: HTTPMethod
    let payload: APIPayload?
    let urlParameters: [String: String]
    let headers: APIHTTPHeaders
    let policy: URLRequest.CachePolicy
    let timeout: Int
    let authentication: APIRequestAuthentication
    let resolver: APIEndpointResolver?
    var modelParser: APIModelParsing?
    var errorParser: APIModelParsing?
    
    public init(path: String,
         method: HTTPMethod,
         payload: APIPayload? = nil,
         headers: APIHTTPHeaders? = nil,
         urlParameters: [String: String]? = nil,
         modelParser: APIModelParsing? = nil,
         errorParser: APIModelParsing? = nil,
         authentication: APIRequestAuthentication? = nil,
         resolver: APIEndpointResolver? = nil,
         policy: URLRequest.CachePolicy? = nil,
         timeout: Int? = nil) {
        
        self.identifier = UUID().uuidString
        self.path = path
        self.method = method
        self.payload = payload
        self.headers = headers ?? APIHTTPHeaders()
        self.urlParameters = urlParameters ?? [String: String]()
        self.modelParser = modelParser
        self.errorParser = errorParser
        self.authentication = authentication ?? APIRequestAuthentication.oauth
        self.resolver = resolver
        self.policy = policy ?? Configuration.defaultCachePolicy
        self.timeout = timeout ?? Configuration.defaultTimeoutSeconds
    }
    
    func copyWithNewIdentifier() -> APIRequest {
        
        return APIRequest(path: path,
                          method: method,
                          payload: payload,
                          headers: headers,
                          modelParser: modelParser,
                          errorParser: errorParser,
                          authentication: authentication,
                          resolver: resolver,
                          policy: policy,
                          timeout: timeout)
    }
}
