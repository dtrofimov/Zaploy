//
//  ChildRelationship.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 28.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class ChildRelationship: EntryMapper, HavingMOField {
    let moRelationship: NSRelationshipDescription
    var moField: MOField { moRelationship }
    let sfChildRelationship: SFChildRelationship
    let shouldUnlinkAbsent: Bool
    let shouldRemoveUnlinked: Bool
    let warningLogger: WarningLogger

    init(moRelationship: NSRelationshipDescription,
         sfChildRelationship: SFChildRelationship,
         shouldUnlinkAbsent: Bool,
         shouldRemoveUnlinked: Bool,
         warningLogger: WarningLogger) {
        self.moRelationship = moRelationship
        self.sfChildRelationship = sfChildRelationship
        self.shouldUnlinkAbsent = shouldUnlinkAbsent
        self.shouldRemoveUnlinked = shouldRemoveUnlinked
        self.warningLogger = warningLogger
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject, in relationshipContext: CoreDataSoupRelationshipContext) {
        guard let soupEntryValue = soupEntry[moRelationship.name] else { return }
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
                relationshipContext.upsertQueue.enqueueUpsertRelationship(entry: entry) { referencedObject in
                    let warningLogger = self.warningLogger
                    guard let referencedObject = referencedObject
                        .check(warningLogger, "Unable to upsert child relationship \(self.moRelationship): \(entry)"),
                        (referencedObject.managedObjectContext == context)
                            .check(warningLogger, "Upserted child relationship has a wrong MOC: \(referencedObject.managedObjectContext.optionalDescription), expected \(context)")
                        else { return completion() }
                    if let expectedEntity = self.moRelationship.destinationEntity {
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

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry, in relationshipContext: CoreDataSoupRelationshipContext) {
        // do nothing: sending child relationships directly is not allowed, we should update every child instead
    }
}
