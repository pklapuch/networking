//
//  APISessionGlobalErrorConsumer.swift
//  Networking
//
//  Created by Pawel Klapuch on 1/25/21.
//  Copyright © 2021 Pawel Klapuch. All rights reserved.
//

import Foundation

public enum APISessionGlobalErrorPolicy {
    
    case `default`
    case cancelCurrentRequest
    case cancellAllAndDisable
}

public protocol APISessionGlobalErrorConsumer: class {
    
    func getPolicy(session: APISession, rawResponse: APIRawResponse) -> APISessionGlobalErrorPolicy
}
