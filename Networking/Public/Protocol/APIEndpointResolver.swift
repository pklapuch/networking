//
//  APIEndpointResolver.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/1/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APIEndpointResolver {
    
    func resolve(relativePath: String) throws -> URL
}
