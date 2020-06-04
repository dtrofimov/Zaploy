//
//  BaseField.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 20.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class BaseField: BaseFieldMapper, HavingSFField {
    let sfField: SFField

    init(moField: MOField, sfField: SFField, warningLogger: WarningLogger) {
        self.sfField = sfField
        super.init(moField: moField, sfKey: sfField.name, warningLogger: warningLogger)
    }
}
