//
//  APIAuthenticating.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

protocol APIAuthenticating {

    func refresh() -> Promise<APISessionTokenProtocol>
    
    func getCurrentToken() -> Promise<APISessionTokenProtocol>
}
