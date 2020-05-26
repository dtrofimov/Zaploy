//
//  CurrencyField.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 21.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Then

extension Decimal: Then { }

class CurrencyField: BaseField {
    let scale: Int

    init(moField: MOField, sfField: SFField, warningLogger: WarningLogger, scale: Int) {
        self.scale = scale
        super.init(moField: moField, sfField: sfField, warningLogger: warningLogger)
    }

    private lazy var roundingBehavior = NSDecimalNumberHandler(roundingMode: .plain,
                                                               scale: Int16(scale),
                                                               raiseOnExactness: false,
                                                               raiseOnOverflow: false,
                                                               raiseOnUnderflow: false,
                                                               raiseOnDivideByZero: true)

    override func kvcValue(forSoupEntryValue soupEntryValue: Any) -> Any? {
        guard let number: NSNumber = warningLogger.checkType(soupEntryValue, "CurrencyField decoding") else { return nil }
        return NSDecimalNumber(decimal: number.decimalValue).rounding(accordingToBehavior: roundingBehavior)
    }

    override func soupEntryValue(forKvcValue kvcValue: Any?) -> Any {
        guard let decimalNumber: NSDecimalNumber = warningLogger.checkType(kvcValue, "CurrencyField encoding") else { return NSNull() }
        return decimalNumber.rounding(accordingToBehavior: roundingBehavior)
    }
}
