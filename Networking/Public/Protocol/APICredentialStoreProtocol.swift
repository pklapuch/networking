//
//  APICredentialStoreProtocol.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APICredentialStoreProtocol {

    func store(token: APISessionTokenProtocol, onSuccess:@escaping VoidBlock, onError:@escaping ErrorBlock)
    
    func token(onSuccess:@escaping OptionalTokenBlock, onError:@escaping ErrorBlock)
    
    func invalidate(onCompleted: VoidBlock)
}
