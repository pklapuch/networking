//
//  APICredentialStoreProtocol.swift
//  Networking
//
//  Created by Pawel Klapuch on 30/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

protocol APICredentialStoreProtocol {

    func store(token: APISessionTokenProtocol) -> Promise<Void>
    func token() -> Promise<APISessionTokenProtocol?>
    func invalidate() -> Promise<Void>
}
