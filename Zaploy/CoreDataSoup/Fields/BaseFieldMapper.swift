//
//  BaseFieldMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class BaseFieldMapper: EntryMapper, HavingMOField {
    let moField: MOField
    let sfKey: String
    let warningLogger: WarningLogger

    init(moField: MOField, sfKey: String, warningLogger: WarningLogger) {
        self.moField = moField
        self.sfKey = sfKey
        self.warningLogger = warningLogger
    }

    func kvcValue(forSoupEntryValue soupEntryValue: Any?) -> Any? {
        soupEntryValue
    }

    func soupEntryValue(forKvcValue kvcValue: Any?) -> Any? {
        kvcValue
    }

    func kvcValue(from managedObject: NSManagedObject) -> Any? {
        managedObject.value(forKey: moField.name)
    }

    func setKvcValue(_ kvcValue: Any?, to managedObject: NSManagedObject) {
        managedObject.setValue(kvcValue, forKey: moField.name)
    }

    func soupEntryValue(from soupEntry: SoupEntry) -> Any? {
        soupEntry[sfKey]
    }

    func setSoupEntryValue(_ soupEntryValue: Any?, to soupEntry: inout SoupEntry) {
        soupEntry[sfKey] = soupEntryValue
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        let kvcValue = self.kvcValue(from: managedObject)
        let soupEntryValue = self.soupEntryValue(forKvcValue: kvcValue)
        setSoupEntryValue(soupEntryValue, to: &soupEntry)
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        let soupEntryValue = self.soupEntryValue(from: soupEntry)
        let kvcValue = self.kvcValue(forSoupEntryValue: soupEntryValue)
        setKvcValue(kvcValue, to: managedObject)
    }
}

extension BaseFieldMapper: FetchableField {
    func predicateByValues(_ values: [Any]) -> NSPredicate {
        // TODO: Rewrite the predicate with a type-safe expression.
        NSPredicate(format: "self.\(moField.name) in %@", values)
    }

    func value(from soupEntry: SoupEntry) -> Any? {
        let soupEntryValue = self.soupEntryValue(from: soupEntry)
        return kvcValue(forSoupEntryValue: soupEntryValue)
    }

    func value(from managedObject: NSManagedObject) -> Any? {
        kvcValue(from: managedObject)
    }
}
