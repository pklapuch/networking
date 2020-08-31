//
//  Blocks.swift
//  Networking
//
//  Created by Pawel Klapuch on 31/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public typealias ResponseBlock = (APIResponse) -> Void
public typealias VoidBlock = () -> Void
public typealias OptionalErrorBlock = (Swift.Error?) -> Void
public typealias HeadersBlock = (APIHTTPHeaders) -> Void
public typealias TokenBlock = (APISessionTokenProtocol) -> Void
public typealias OptionalTokenBlock = (APISessionTokenProtocol?) -> Void
public typealias ErrorBlock = (Swift.Error) -> Void

typealias URLResponseBlock = ((Data?, URLResponse?)) -> Void



