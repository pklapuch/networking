//
//  Callback.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

extension APIRequest {
    
    public class APICallback {
        
        let onSuccess: ResponseBlock
        let onError: ErrorBlock
        
        init(onSuccess:@escaping ResponseBlock, onError:@escaping ErrorBlock) {
            
            self.onSuccess = onSuccess
            self.onError = onError
        }
    }
}
