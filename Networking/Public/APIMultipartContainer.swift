//
//  APIMultipartContainer.swift
//  Networking
//
//  Created by Pawel Klapuch on 9/29/20.
//

import Foundation

public struct APIMultipartContainer {
    
    public enum ContentType: String {
        
        case plainText = "text/plain"
        case jpeg = "image/jpeg"
        case zip = "application/zip"
    }
    
    public enum Error: CustomNSError {
        
        case contentWasSealed
        case contentIsNotCompleted
        case containsInvalidCharacters
    }
    
    private let boundary: String
    private var content = Data()
    private var didEndBody = false
    
    public init(boundary: String) throws {
        
        self.boundary = boundary
    }
    
    public mutating func add(descriptor name: String, value: String) throws {
        
        guard !didEndBody else { throw Error.contentWasSealed}
        
        var disposition = ContentDisposition()
        disposition.add(key: "name", value: name)
        
        content.append(try Data.from(text: "--\(boundary)\r\n", encoding: .utf8))
        content.append(try Data.from(text: "\(disposition.content)\r\n\r\n", encoding: .utf8))
        content.append(try Data.from(text: "\(value)", encoding: .utf8))
        content.append(try Data.from(text: "\r\n", encoding: .utf8))
    }
    
    public mutating func add(data: Data,
                      contentType: ContentType,
                      name: String,
                      filename: String) throws {
        
        guard !didEndBody else { throw Error.contentWasSealed}
        
        var disposition = ContentDisposition()
        disposition.add(key: "name", value: name)
        disposition.add(key: "filename", value: filename)
        
        content.append(try Data.from(text: "--\(boundary)\r\n", encoding: .utf8))
        content.append(try Data.from(text: "\(disposition.content)\r\n", encoding: .utf8))
        content.append(try Data.from(text: "Content-Type: \(contentType.rawValue)\r\n\r\n", encoding: .utf8))
        content.append(data)
        content.append(try Data.from(text: "\r\n", encoding: .utf8))
    }
    
    public mutating func end() throws {
        
        guard !didEndBody else { throw Error.contentWasSealed }
        
        didEndBody = true
        content.append(try Data.from(text: "\r\n--\(boundary)--\r\n", encoding: .utf8))
    }
    
    public func getContent() throws -> Data {
        
        guard didEndBody else { throw Error.contentIsNotCompleted }
        
        return content
    }
    
    public func getContentLength() throws -> Int {
        
        guard didEndBody else { throw Error.contentIsNotCompleted }
        
        return content.count
    }
}
