//
//  ModelParsing.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

protocol ModelParsing {

    func decode(data: Data) throws -> Codable?
}
