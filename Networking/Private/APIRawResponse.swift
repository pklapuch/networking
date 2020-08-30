//
//  APIRawResponse.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public struct APIRawResponse {

    public let status: Int?
    public let headers: APIHTTPHeaders
    public let data: Data?
}
