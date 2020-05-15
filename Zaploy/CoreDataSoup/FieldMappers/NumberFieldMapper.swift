//
//  NumberFieldMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class NumberFieldMapper: BaseFieldMapper {
    override func kvcValue(forSoupEntryValue soupEntryValue: Any?) -> Any? {
        return checkType(soupEntryValue, expected: NSNumber.self)
    }
}
