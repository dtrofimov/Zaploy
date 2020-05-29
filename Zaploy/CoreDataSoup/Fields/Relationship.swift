//
//  Relationship.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 27.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class Relationship: BaseField {
    let moRelationship: NSRelationshipDescription
    let relationshipResolver: CoreDataSoupRelationshipResolver
    let shouldRemoveUnlinked: Bool

    init(moRelationship: NSRelationshipDescription,
         sfField: SFField,
         warningLogger: WarningLogger,
         relationshipResolver: CoreDataSoupRelationshipResolver,
         shouldRemoveUnlinked: Bool) {
        self.moRelationship = moRelationship
        self.relationshipResolver = relationshipResolver
        self.shouldRemoveUnlinked = shouldRemoveUnlinked
        super.init(moField: moRelationship, sfField: sfField, warningLogger: warningLogger)
    }

    override func kvcValue(forSoupEntryValue soupEntryValue: Any) -> Any? {
        warningLogger.logWarning("kvcValue(forSoupEntryValue:) is called for Relationship. Use map(from:to:) instead.")
        return nil
    }

    override func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        guard let soupEntryValue = self.soupEntryValue(from: soupEntry) else { return }
        let oldReferencedObject: NSManagedObject? = kvcValue(from: managedObject)
            .checkType(warningLogger, "Relationship old getting")
        func complete(with referencedObject: NSManagedObject?) {
            if oldReferencedObject == referencedObject { return }
            if shouldRemoveUnlinked, let oldReferencedObject = oldReferencedObject {
                oldReferencedObject.managedObjectContext
                    .check(warningLogger, "Unlinked relationship has no context to remove from: \(oldReferencedObject)")?
                    .delete(oldReferencedObject)
            }
            setKvcValue(referencedObject, to: managedObject)
        }
        guard let entry: SoupEntry = Optional(soupEntryValue)
            .checkType(warningLogger, "Relationship decoding"),
            let context = managedObject.managedObjectContext
                .check(warningLogger, "Managed object has no context to map a relationship: \(managedObject), \(moRelationship)")
            else { return complete(with: nil) }
        relationshipResolver.enqueueUpsertRelationship(entry: entry, in: context) { referencedObject in
            guard let referencedObject = referencedObject
                .check(warningLogger, "Cannot upsert an embedded relationship: \(entry), \(moRelationship)")
                else { return complete(with: nil) }
            if let expectedEntity = moRelationship.destinationEntity {
                guard (referencedObject.entity == expectedEntity)
                    .check(warningLogger, "Upserted relationship has a wrong entity: expected \(expectedEntity), the object is \(referencedObject)")
                    else { return complete(with: nil) }
            }
            complete(with: referencedObject)
        }
    }

    override func soupEntryValue(forKvcValue kvcValue: Any?) -> Any {
        guard let referencedObject: NSManagedObject = kvcValue
            .checkType(warningLogger, "Relationship encoding"),
            let referenceEntry = relationshipResolver.referenceEntry(from: referencedObject)
                .check(warningLogger, "Cannot encode a reference entry for a referenced object: \(referencedObject)")
            else { return NSNull() }
        return referenceEntry
    }
}
