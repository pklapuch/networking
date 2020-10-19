//
//  URL+Query.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/19/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension URL {

    mutating func appendQueryItem(name: String, value: String?) throws {

        guard var urlComponents = URLComponents(string: absoluteString) else { return }

        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        let queryItem = URLQueryItem(name: name, value: value)

        queryItems.append(queryItem)
        urlComponents.queryItems = queryItems

        guard let updatedURL = urlComponents.url else { throw APISession.Error.invalidURL }
        self = updatedURL
    }
}
