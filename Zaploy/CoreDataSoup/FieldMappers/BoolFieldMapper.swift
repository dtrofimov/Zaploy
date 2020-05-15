//
//  BoolFieldMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 13.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class BoolFieldMapper: BaseFieldMapper {
    override func kvcValue(forSoupEntryValue soupEntryValue: Any?) -> Any? {
        return checkType(soupEntryValue, expected: Bool.self)
    }
}
