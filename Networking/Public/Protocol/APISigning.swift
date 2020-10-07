//
//  APISigning.swift
//  Networking
//
//  Created by Pawel Klapuch on 10/6/20.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public protocol APISigning {
    
    func sign(_ urlRequset: URLRequest, onSuccess:@escaping SignBlock, onFailure:@escaping ErrorBlock)
    
    func renewSignature(onSuccess:@escaping VoidBlock, onFailure:@escaping ErrorBlock)
    
    func isSignatureRejected(_ data: Data?, status: Int?) -> Bool
}
