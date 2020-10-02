//
//  APIPayloadLogging.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/2/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APIURLLogging {
    
    func getURLDescription(for url: URL) -> String?
}

public protocol APIHeaderLogging {
    
    func getHeadersDescription(for headers: APIHTTPHeaders) -> String?
}

public protocol APIPayloadLogging {
    
    func getPayloadDescription(for data: Data?) -> String?
}

public protocol APIRequestLogging {
    
    var url: APIURLLogging? { get }
    var headers: APIHeaderLogging? { get }
    var payload: APIPayloadLogging? { get }
}
