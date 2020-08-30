//
//  APIRawResponse.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct APIRawResponse {

    let status: Int?
    let headers: APIRequest.HTTPHeaders
    let data: Data?
}
