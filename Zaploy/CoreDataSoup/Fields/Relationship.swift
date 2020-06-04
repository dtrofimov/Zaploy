//
//  Relationship.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 27.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class Relationship: EntryMapper, HavingMOField, HavingSFField {
    let moRelationship: NSRelationshipDescription
    var moField: MOField { moRelationship }
    let sfField: SFField
    let sfRelationshipName: String
    let shouldRemoveUnlinked: Bool
    let warningLogger: WarningLogger

    init(moRelationship: NSRelationshipDescription,
         sfField: SFField,
         sfRelationshipName: String,
         shouldRemoveUnlinked: Bool,
         warningLogger: WarningLogger) {
        self.moRelationship = moRelationship
        self.sfField = sfField
        self.sfRelationshipName = sfRelationshipName
        self.shouldRemoveUnlinked = shouldRemoveUnlinked
        self.warningLogger = warningLogger
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject, in relationshipContext: CoreDataSoupRelationshipContext) {
        let relationshipValue: Any? = soupEntry[sfRelationshipName] // "Asdf__r": { ... }
        let idValue: Any? = soupEntry[sfField.name] // "Asdf__c": "..."
        guard relationshipValue != nil || idValue != nil else { return }

        // re-code them to a single reference entry
        let soupEntryValue: Any = {
            let relationshipEntry: SoupEntry? = relationshipValue
                .checkType(warningLogger, "Relationship relationship decoding")
            let id: SfId? = idValue
                .checkType(warningLogger, "Relationship id decoding")

            guard relationshipEntry != nil || id != nil else { return NSNull() }
            var referencedEntry = relationshipEntry ?? [:]
            if let embeddedId = referencedEntry.sfId {
                if let id = id {
                    warningLogger.assert(embeddedId == id, "Two different ids provided during Relationship decoding: \(moRelationship), \(soupEntry)")
                }
            } else {
                referencedEntry.sfId = id
            }
            let sfEntityNameUnsafe: String? = {
                if let type = referencedEntry.sfTypeAttribute {
                    return type
                }
                if let referencedSfEntityName = sfField.referenceTo {
                    return referencedSfEntityName
                }
                if let referencedEntity = moRelationship.destinationEntity,
                    let referencedMetadata = relationshipContext.metadata(entity: referencedEntity),
                    let referencedEntitySfName = referencedMetadata.sfName {
                    return referencedEntitySfName
                }
                return nil
            }()
            guard let sfEntityName = sfEntityNameUnsafe
                .check(warningLogger, "Cannot find sfEntityName when decoding a relationship: \(moRelationship), \(soupEntry)")
                else { return NSNull() }
            referencedEntry.sfTypeAttribute = sfEntityName
            return referencedEntry
        }()

        let oldReferencedObject: NSManagedObject? = managedObject.value(forKey: moRelationship.name)
            .checkType(warningLogger, "Relationship old getting")
        func complete(with referencedObject: NSManagedObject?) {
            if oldReferencedObject == referencedObject { return }
            if shouldRemoveUnlinked, let oldReferencedObject = oldReferencedObject {
                oldReferencedObject.managedObjectContext
                    .check(warningLogger, "Unlinked relationship has no context to remove from: \(oldReferencedObject)")?
                    .delete(oldReferencedObject)
            }
            managedObject.setValue(referencedObject, forKey: moRelationship.name)
        }
        guard let referencedEntry = soupEntryValue as? SoupEntry,
            let context = managedObject.managedObjectContext
                .check(warningLogger, "Managed object has no context to map a relationship: \(managedObject), \(moRelationship)")
            else { return complete(with: nil) }
        relationshipContext.upsertQueue.enqueueUpsertRelationship(entry: referencedEntry) { referencedObject in
            let warningLogger = self.warningLogger
            guard let referencedObject = referencedObject
                .check(warningLogger, "Cannot upsert an embedded relationship: \(referencedEntry), \(self.moRelationship)"),
                (referencedObject.managedObjectContext == context)
                    .check(warningLogger, "Upserted relationship has a wrong MOC: \(referencedObject.managedObjectContext.optionalDescription), expected \(context)")
                else { return complete(with: nil) }
            if let expectedEntity = self.moRelationship.destinationEntity {
                guard (referencedObject.entity == expectedEntity)
                    .check(warningLogger, "Upserted relationship has a wrong entity: expected \(expectedEntity), the object is \(referencedObject)")
                    else { return complete(with: nil) }
            }
            complete(with: referencedObject)
        }
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry, in relationshipContext: CoreDataSoupRelationshipContext) {
        (soupEntry[sfField.name], soupEntry[sfRelationshipName]) = {
            func fallback() -> (Any?, Any?) { (NSNull(), nil) }
            guard let referencedObject: NSManagedObject = managedObject.value(forKey: moRelationship.name)
                .checkType(warningLogger, "Relationship encoding"),
                let metadata = relationshipContext.metadata(entity: referencedObject.entity)
                    .check(warningLogger, "Cannot resolve metadata to encode a relationship: \(referencedObject)")
                else { return fallback() }
            if let id = metadata.sfIdField.value(from: referencedObject) {
                return (id, nil)
            }
            var referenceEntry: SoupEntry = [:]
            metadata.attributesMapper
                .check(warningLogger, "No attributes mapper to encode reference entry: \(metadata.entity)")?
                .map(from: referencedObject, to: &referenceEntry, in: relationshipContext)
            for uniqueField in metadata.otherUniqueFields {
                if let value = uniqueField.value(from: referencedObject) {
                    uniqueField.setValue(value, to: &referenceEntry)
                    return (nil, referenceEntry)
                }
            }
            return fallback()
        }()
    }
}
