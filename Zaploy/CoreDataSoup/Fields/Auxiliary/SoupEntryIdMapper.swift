//
//  SoupEntryIdMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class SoupEntryIdMapper: EntryMapper {
    let soupEntryIdConverter: SoupEntryIdConverter
    let warningLogger: WarningLogger

    internal init(soupEntryIdConverter: SoupEntryIdConverter, warningLogger: WarningLogger) {
        self.soupEntryIdConverter = soupEntryIdConverter
        self.warningLogger = warningLogger
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry, in relationshipContext: CoreDataSoupRelationshipContext) {
        guard let soupEntryId = (Result { try soupEntryIdConverter.soupEntryId(managedObjectId: managedObject.objectID) })
            .check(warningLogger, "Unable to export soupEntryId from \(managedObject)")
            else { return }
        soupEntry.soupEntryId = soupEntryId
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject, in relationshipContext: CoreDataSoupRelationshipContext) {
        if warningLogger.isEnabled,
            let soupEntryId = soupEntry.soupEntryId {
            guard let expectedManagedObjectId = (Result { try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) })
                .check(warningLogger, "Unable to map soupEntryId \(soupEntryId) to \(managedObject)")
                else { return }
            warningLogger.assert(expectedManagedObjectId == managedObject.objectID,
                                 "Wrong soupEntryId \(soupEntryId) mapped to \(managedObject)")
        }
    }
}

extension SoupEntryIdMapper: FetchableField {
    func predicateByValues(_ values: [Any]) -> NSPredicate {
        // TODO: Rewrite the predicate with a type-safe expression.
        NSPredicate(format: "self in %@", values)
    }

    func value(from soupEntry: SoupEntry) -> Any? {
        guard let soupEntryId = soupEntry.soupEntryId else { return nil }
        return (Result { try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) })
            .check(warningLogger, "Unable to convert soupEntryId value from a soupEntry: \(soupEntryId)")
    }

    func setValue(_ value: Any?, to soupEntry: inout SoupEntry) {
        guard let managedObjectId: NSManagedObjectID = value
            .checkType(warningLogger, "SoupEntryIdMapper encoding"),
            let soupEntryId = (Result { try soupEntryIdConverter.soupEntryId(managedObjectId: managedObjectId) })
                .check(warningLogger, "Unable to map managedObjectId to soupEntryId: \(managedObjectId)")
            else { return }
        soupEntry.soupEntryId = soupEntryId
    }

    func value(from managedObject: NSManagedObject) -> Any? {
        managedObject.objectID
    }
}
