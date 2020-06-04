//
//  SFChildRelationship.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 01.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class SFChildRelationship {
    enum CustomError: Error {
        case nameNotFound
    }

    let metadata: [AnyHashable: Any]
    let name: String

    init(metadata: [AnyHashable : Any]) throws {
        self.metadata = metadata
        guard let name = metadata["relationshipName"] as? String else {
            throw CustomError.nameNotFound
        }
        self.name = name
    }

    lazy var childSObject: String? = metadata["childSObject"] as? String
    lazy var field: String? = metadata["field"] as? String
}
