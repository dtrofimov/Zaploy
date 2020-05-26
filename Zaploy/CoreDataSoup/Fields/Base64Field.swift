//
//  Base64Field.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 21.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class Base64Field: EntryMapper, HavingMOField {
    let bodyMoField: MOField
    let urlMoField: MOField
    var moField: MOField { bodyMoField }
    let sfField: SFField
    let warningLogger: WarningLogger

    internal init(bodyMoField: MOField, urlMoField: MOField, sfField: SFField, warningLogger: WarningLogger) {
        self.bodyMoField = bodyMoField
        self.urlMoField = urlMoField
        self.sfField = sfField
        self.warningLogger = warningLogger
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        soupEntry[sfField.name] = {
            if let url: String = warningLogger.checkType(managedObject.value(forKey: urlMoField.name), "Base64Field.url encoding") {
                return url
            } else if let body: Data = warningLogger.checkType(managedObject.value(forKey: bodyMoField.name), "Base64Field.body encoding") {
                return body.base64EncodedString()
            } else {
                return NSNull()
            }
        }()
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        guard let soupEntryValue = soupEntry[sfField.name] else { return }
        if let string: String = warningLogger.checkType(soupEntryValue, "Base64Field decoding") {
            if let body = Data(base64Encoded: string) {
                let oldBody: Data? = warningLogger.checkType(managedObject.value(forKey: bodyMoField.name), "Base64Field.oldBody getting")
                if body != oldBody {
                    managedObject.setValue(body, forKey: bodyMoField.name)
                    managedObject.setValue(nil, forKey: urlMoField.name)
                }
            } else {
                let url = string
                let oldUrl: String? = warningLogger.checkType(managedObject.value(forKey: urlMoField.name), "Base64Field.oldUrl getting")
                if url != oldUrl {
                    managedObject.setValue(nil, forKey: bodyMoField.name)
                    managedObject.setValue(url, forKey: urlMoField.name)
                }
            }
        } else {
            managedObject.setValue(nil, forKey: bodyMoField.name)
            managedObject.setValue(nil, forKey: urlMoField.name)
        }
    }
}
