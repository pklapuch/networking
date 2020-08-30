//
//  APITokenActionProtocol.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

public protocol APITokenActionProtocol {
    
    func authenticate(credential: APIAuthCredential) -> Promise<APISessionTokenProtocol>
    
    func refresh(token: APISessionTokenProtocol) -> Promise<APISessionTokenProtocol>
    
    func extract(from response: APIResponse) -> Promise<APISessionTokenProtocol>
    
    func validate(token: APISessionTokenProtocol?) -> Promise<APISessionTokenProtocol>
}
