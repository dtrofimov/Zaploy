//
//  SFField.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class SFField {
    enum CustomError: Error {
        case nameNotFound
    }

    enum FieldType: String {
        case anyType = "anyType"
        case base64 = "base64"
        case boolean = "boolean"
        case byte = "byte"
        case currency = "currency"
        case date = "date"
        case dateTime = "dateTime"
        case double = "double"
        case email = "email"
        case id = "id"
        case int = "int"
        case percent = "percent"
        case picklist = "picklist"
        case phone = "phone"
        case reference = "reference"
        case string = "string"
        case textarea = "textarea"
        case time = "time"
        case url = "url"
    }

    let metadata: [AnyHashable: Any]
    let name: String

    init(metadata: [AnyHashable: Any]) throws {
        self.metadata = metadata
        guard let name = metadata["name"] as? String else {
            throw CustomError.nameNotFound
        }
        self.name = name
    }

    lazy var type: FieldType? = (metadata["type"] as? String).flatMap { FieldType(rawValue: $0) }
    lazy var scale = metadata["scale"] as? Int
    lazy var referenceTo = metadata["referenceTo"] as? String
    lazy var relationshipName = metadata["relationshipName"] as? String
}
