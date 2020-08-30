//
//  APIHTTPHeaders.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public struct APIHTTPHeaders {
    private var headers: [APIHTTPHeader] = []

    public init() {}

    public init(_ headers: [APIHTTPHeader]) {
        self.init()
        headers.forEach { update($0) }
    }

    public init(_ dictionary: [String: String]) {
        self.init()
        dictionary.forEach { update(APIHTTPHeader(name: $0.key, value: $0.value)) }
    }

    public mutating func add(name: String, value: String) {
        update(APIHTTPHeader(name: name, value: value))
    }

    public mutating func add(_ header: APIHTTPHeader) {
        update(header)
    }

    public mutating func update(name: String, value: String) {
        update(APIHTTPHeader(name: name, value: value))
    }

    public mutating func update(_ header: APIHTTPHeader) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }

        headers.replaceSubrange(index...index, with: [header])
    }

    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else { return }

        headers.remove(at: index)
    }

    public mutating func sort() {
        headers.sort { $0.name.lowercased() < $1.name.lowercased() }
    }

    public func sorted() -> APIHTTPHeaders {
        var headers = self
        headers.sort()
        return headers
    }

    public func value(for name: String) -> String? {
        guard let index = headers.index(of: name) else { return nil }
        return headers[index].value
    }

    public subscript(_ name: String) -> String? {
        get { value(for: name) }
        set {
            if let value = newValue {
                update(name: name, value: value)
            } else {
                remove(name: name)
            }
        }
    }

    public var dictionary: [String: String] {
        let namesAndValues = headers.map { ($0.name, $0.value) }

        return Dictionary(namesAndValues, uniquingKeysWith: { _, last in last })
    }
}

extension APIHTTPHeaders: Sequence {
    public func makeIterator() -> IndexingIterator<[APIHTTPHeader]> {
        headers.makeIterator()
    }
}
