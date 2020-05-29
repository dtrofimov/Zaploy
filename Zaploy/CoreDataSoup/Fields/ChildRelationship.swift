//
//  ChildRelationship.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 28.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class ChildRelationship: BaseField {
    let moRelationship: NSRelationshipDescription
    let relationshipResolver: CoreDataSoupRelationshipResolver
    let shouldUnlinkAbsent: Bool
    let shouldRemoveUnlinked: Bool

    init(moRelationship: NSRelationshipDescription,
         sfField: SFField,
         warningLogger: WarningLogger,
         relationshipResolver: CoreDataSoupRelationshipResolver,
         shouldUnlinkAbsent: Bool,
         shouldRemoveUnlinked: Bool) {
        self.moRelationship = moRelationship
        self.relationshipResolver = relationshipResolver
        self.shouldUnlinkAbsent = shouldUnlinkAbsent
        self.shouldRemoveUnlinked = shouldRemoveUnlinked
        super.init(moField: moRelationship, sfField: sfField, warningLogger: warningLogger)
    }

    override func kvcValue(forSoupEntryValue soupEntryValue: Any) -> Any? {
        warningLogger.logWarning("kvcValue(forSoupEntryValue:) is called for ChildRelationship. Use map(from:to:) instead.")
        return nil
    }

    override func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        guard let soupEntryValue = self.soupEntryValue(from: soupEntry) else { return }
        let mutableSetAccessor = managedObject.mutableSetValue(forKey: moField.name)
        var unmatchedOldSet = Optional(mutableSetAccessor)
            .checkType(warningLogger, "ChildRelationship old getting")
            as Set<NSManagedObject>?
            ?? []

        let multiTaskTracker = MultiTaskTracker()
        defer {
            if shouldUnlinkAbsent {
                multiTaskTracker.onComplete {
                    for unlinkedObject in unmatchedOldSet {
                        mutableSetAccessor.remove(unlinkedObject)
                        if self.shouldRemoveUnlinked {
                            unlinkedObject.managedObjectContext
                                .check(self.warningLogger, "Unlinked child relationship has no context to remove from: \(unlinkedObject)")?
                                .delete(unlinkedObject)
                        }
                    }
                }
            }
        }

        guard let collectionDict: [AnyHashable: Any] = Optional(soupEntryValue)
            .checkType(warningLogger, "ChildRelationship collectionDict decoding"),
            let entries: [SoupEntry] = collectionDict["records"]
                .checkType(warningLogger, "ChildRelationship records decoding"),
            let context = managedObject.managedObjectContext
                .check(warningLogger, "Managed object has no context to map a child relationship: \(managedObject), \(moRelationship)")
            else { return }

        for entry in entries {
            multiTaskTracker.track { completion in
                relationshipResolver.enqueueUpsertRelationship(entry: entry, in: context) { referencedObject in
                    guard let referencedObject = referencedObject
                        .check(warningLogger, "Unable to upsert child relationship \(moRelationship): \(entry)")
                        else { return completion() }
                    if let expectedEntity = moRelationship.destinationEntity {
                        guard (referencedObject.entity == expectedEntity)
                            .check(warningLogger, "Upserted child relationship has a wrong entity: expected \(expectedEntity), the object is \(referencedObject)")
                            else { return completion() }
                    }
                    mutableSetAccessor.add(referencedObject)
                    unmatchedOldSet.remove(referencedObject)
                    completion()
                }
            }
        }
    }

    override func soupEntryValue(forKvcValue kvcValue: Any?) -> Any {
        warningLogger.logWarning("soupEntryValue(forKvcValue:) is called for ChildRelationship. Use map(from:to:) instead.")
        return NSNull()
    }

    override func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        // do nothing: sending child relationships directly is not allowed, we should update every child instead
    }
}
