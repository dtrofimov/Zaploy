//
//  StringField.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class StringField: BaseField {
    override func kvcValue(forSoupEntryValue soupEntryValue: Any) -> Any? {
        Optional(soupEntryValue)
            .checkType(warningLogger, "StringField decoding")
            as String?
    }
}
