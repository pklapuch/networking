//
//  APITokenActionProtocol.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APITokenActionProtocol {
    
    func authenticate(credential: APIAuthCredential, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock)
    
    func refresh(token: APISessionTokenProtocol, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock)
    
    func extract(from response: APIResponse, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock)
    
    func validate(token: APISessionTokenProtocol?, onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock)
}
