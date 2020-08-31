//
//  APISessionProtocol.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APISessionProtocol {

    func execute(_ request: APIRequest, onSuccess:@escaping ResponseBlock, onError: @escaping ErrorBlock)
}
