//
//  APIAuthenticating.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APIAuthenticating {

    func refresh(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock)
    
    func getCurrentToken(onSuccess:@escaping TokenBlock, onError:@escaping ErrorBlock)
}
