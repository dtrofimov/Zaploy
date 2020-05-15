//
//  SoupEntryIdMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class SoupEntryIdMapper: FieldMapper {
    let soupEntryIdConverter: SoupEntryIdConverter
    let warningLogger: WarningLogger

    internal init(soupEntryIdConverter: SoupEntryIdConverter, warningLogger: WarningLogger) {
        self.soupEntryIdConverter = soupEntryIdConverter
        self.warningLogger = warningLogger
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        guard let soupEntryId = warningLogger.handle({ try soupEntryIdConverter.soupEntryId(managedObjectId: managedObject.objectID) },
                                                     "Unable to export soupEntryId from \(managedObject)")
            else { return }
        soupEntry.soupEntryId = soupEntryId
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        if let soupEntryId = soupEntry.soupEntryId {
            guard let expectedManagedObjectId = warningLogger.handle({ try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) },
                                                                     "Unable to map soupEntryId \(soupEntryId) to \(managedObject)")
                else { return }
            warningLogger.assert(expectedManagedObjectId == managedObject.objectID, "Wrong soupEntryId \(soupEntryId) mapped to \(managedObject)")
        }
    }
}

extension SoupEntryIdMapper: UniqueFieldMapper {
    func predicateByValues(_ values: [Any]) -> NSPredicate {
        // TODO: Rewrite the predicate with a type-safe expression.
        NSPredicate(format: "self in %@", values)
    }

    func value(from soupEntry: SoupEntry) -> Any? {
        guard let soupEntryId = soupEntry.soupEntryId else { return nil }
        return try? soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId)
    }

    func value(from managedObject: NSManagedObject) -> Any? {
        managedObject.objectID
    }
}
