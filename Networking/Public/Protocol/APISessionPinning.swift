//
//  APISessionPinning.swift
//  Networking
//
//  Created by Pawel Klapuch on 28/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

protocol APISessionPinning {
    
    func evaluate(host: String, certificates: [Data]) -> Bool
}
