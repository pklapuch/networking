//
//  Request.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

class APIRequest: NSObject {
    
    typealias HTTPHeaders = [String: String]
    
    enum Error: CustomNSError, LocalizedError {
        
        case invalidPath
        
        var errorDescription: String? {
            switch self {
            case .invalidPath: return "invalid path"
            }
        }
    }
    
    struct Configuration {
        
        static let defaultCachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        static let defaultTimeoutSeconds = 60
    }
    
    let identifier: String
    let url: URL
    let method: HTTPMethod
    let payload: APIPayload?
    let headers: HTTPHeaders
    let policy: URLRequest.CachePolicy
    let timeout: Int
    let authentication: APIRequestAuthentication
    var modelParser: ModelParsing?
    var errorParser: ErrorParsing?
    
    convenience init(path: String,
                     method: HTTPMethod,
                     payload: APIPayload?,
                     headers: HTTPHeaders,
                     modelParser: ModelParsing? = nil,
                     errorParser: ErrorParsing? = nil,
                     authentication: APIRequestAuthentication? = nil,
                     policy: URLRequest.CachePolicy? = nil,
                     timeout: Int? = nil) throws {
        
        guard let url = URL(string: path) else { throw Error.invalidPath }
        self.init(url: url,
                  method: method,
                  payload: payload,
                  headers: headers,
                  modelParser: modelParser,
                  errorParser: errorParser,
                  authentication: authentication,
                  policy: policy,
                  timeout: timeout)
    }
    
    init(url: URL,
         method: HTTPMethod,
         payload: APIPayload?,
         headers: HTTPHeaders,
         modelParser: ModelParsing? = nil,
         errorParser: ErrorParsing? = nil,
         authentication: APIRequestAuthentication? = nil,
         policy: URLRequest.CachePolicy? = nil,
         timeout: Int? = nil) {
        
        self.identifier = UUID().uuidString
        self.url = url
        self.method = method
        self.payload = payload
        self.headers = headers
        self.modelParser = modelParser
        self.errorParser = errorParser
        self.authentication = authentication ?? APIRequestAuthentication.none
        self.policy = policy ?? Configuration.defaultCachePolicy
        self.timeout = timeout ?? Configuration.defaultTimeoutSeconds
    }
    
    func copyWithNewIdentifier() -> APIRequest {
        
        return APIRequest(url: url,
                          method: method,
                          payload: payload,
                          headers: headers,
                          modelParser: modelParser,
                          errorParser: errorParser,
                          authentication: authentication,
                          policy: policy,
                          timeout: timeout)
    }
}
