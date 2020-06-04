//
//  CoreDataSoupContext.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 07.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class CoreDataSoup: ExternalSoup, CoreDataSoupEntryUpserter {
    let soupMetadata: CoreDataSoupMetadata
    let soupEntryIdConverter: SoupEntryIdConverter
    let soupAccessor: CoreDataSoupAccessor
    let relationshipContextResolver: (NSManagedObjectContext) -> CoreDataSoupRelationshipContext?
    let warningLogger: WarningLogger

    init(soupMetadata: CoreDataSoupMetadata,
         soupEntryIdConverter: SoupEntryIdConverter,
         soupAccessor: CoreDataSoupAccessor,
         relationshipContextResolver: @escaping (NSManagedObjectContext) -> CoreDataSoupRelationshipContext?,
         warningLogger: WarningLogger) {
        self.soupMetadata = soupMetadata
        self.soupEntryIdConverter = soupEntryIdConverter
        self.soupAccessor = soupAccessor
        self.relationshipContextResolver = relationshipContextResolver
        self.warningLogger = warningLogger
    }

    private func performMapping<T>(in context: NSManagedObjectContext, block: (CoreDataSoupRelationshipContext) throws -> T) rethrows -> T {
        let relationshipContext = relationshipContextResolver(context) ?? EmptyCoreDataSoupRelationshipContext.empty
        let result = try block(relationshipContext)
        relationshipContext.upsertQueue.processQueue(in: context, in: relationshipContext)
        return result
    }

    // MARK: ExternalSoup

    func nonDirtySfIds(syncSoupEntryId: SoupEntryId?) -> [SfId] {
        return soupAccessor.accessStore { context in
            let request = NSFetchRequest<NSDictionary>()
            request.entity = soupMetadata.entity
            request.resultType = .dictionaryResultType
            let predicates: [NSPredicate] = [].with {
                if let syncIdField = soupMetadata.syncIdField,
                    let syncId = syncSoupEntryId {
                    $0.append(syncIdField.predicateByValues([syncId]))
                }
                // TODO: Exclude dirty entries
            }
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            let moIdField = soupMetadata.sfIdField.moField
            request.propertiesToFetch = [moIdField]
            guard let dicts = (Result { try context.fetch(request) })
                .check(warningLogger, "Unable to fetch nonDirtySfIds: \(request)")
                else { return [] }
            return dicts.compactMap {
                $0[moIdField.name]
                    .check(warningLogger, "No sfId found when fetching nonDirtySfIds: \($0)")
                    .checkType(warningLogger, "CoreDataSoup.nonDirtySfIds sfId extracting")
                    as SfId?
            }
        }
    }

    var dirtySoupEntryIds: [SoupEntryId] {
        // TODO: Include dirty entries
        []
    }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry] {
        return soupAccessor.accessStore { context in
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soupMetadata.entity
            let managedObjectIds: [NSManagedObjectID] = soupEntryIds.compactMap { soupEntryId in
                guard let managedObjectId = (Result { try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) })
                    .check(warningLogger, "Unable to build managedObjectId from soupEntryId \(soupEntryId)")
                    else { return nil }
                return managedObjectId
            }
            request.predicate = soupMetadata.soupEntryIdField.predicateByValues(managedObjectIds)
            request.returnsObjectsAsFaults = false
            guard let fetchedObjects = (Result { try context.fetch(request) })
                .check(warningLogger, "Unable to fetch entries for soupEntryIds: \(request)")
                else { return [] }
            let objectsForManagedObjectIds: [NSManagedObjectID: NSManagedObject] = fetchedObjects.reduce(into: [:]) {
                $0[$1.objectID] = $1
            }
            return performMapping(in: context) { relationshipContext in
                managedObjectIds.compactMap {
                    guard let object = objectsForManagedObjectIds[$0]
                        .check(warningLogger, "Entry not found for managedObjectId \($0)")
                        else { return nil }
                    return SoupEntry().with {
                        soupMetadata.soupMapper.map(from: object, to: &$0, in: relationshipContext)
                    }
                }
            }
        }
    }

    func upsert(entries: [SoupEntry], in context: NSManagedObjectContext, in relationshipContext: CoreDataSoupRelationshipContext, onUpsert: (SoupEntry, Int, NSManagedObject?) -> Void) {
        let predicates: [NSPredicate] = soupMetadata.uniqueFields.compactMap { field in
            let values = entries.compactMap { field.value(from: $0) }
            guard !values.isEmpty else { return nil }
            return field.predicateByValues(values)
        }
        let existingObjects: [NSManagedObject] = {
            guard !predicates.isEmpty else { return [] }
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soupMetadata.entity
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            request.returnsObjectsAsFaults = false
            guard let objects = (Result { try context.fetch(request) })
                .check(warningLogger, "Cannot fetch by ids: \(request)")
                else { return [] }
            return objects
        }()
        for (index, entry) in entries.enumerated() {
            let matchingObjects: [NSManagedObject] = existingObjects.filter { object in
                soupMetadata.uniqueFields.contains { field in
                    field.value(from: object)
                        .checkType(warningLogger, "CoreDataSoup.upsert matchingObjects left")
                        as NSObject?
                        ==
                        field.value(from: entry)
                            .checkType(warningLogger, "CoreDataSoup.upsert matchingObjects left")
                        as NSObject?
                }
            }
            guard (matchingObjects.count <= 1)
                .check(warningLogger, "Multiple matching objects found for \(entry): \(matchingObjects)")
                else {
                    onUpsert(entry, index, nil)
                    continue
            }
            let targetObject: NSManagedObject = {
                if let existing = matchingObjects.first {
                    if warningLogger.isEnabled {
                        for field in soupMetadata.uniqueFields {
                            if let existingValue = field.value(from: existing) as? NSObject,
                                let newValue = field.value(from: entry) as? NSObject {
                                warningLogger.assert(existingValue == newValue,
                                                     "Unique value doesn't match for \(field): existingObject = \(existing), upsertedEntry = \(entry)")
                            }
                        }
                    }
                    return existing
                } else {
                    warningLogger.assert(soupMetadata.soupEntryIdField.value(from: entry) == nil,
                                         "Object not found by soupEntryId while upserting \(entry)")
                    return NSManagedObject(entity: soupMetadata.entity, insertInto: context)
                }
            }()
            soupMetadata.soupMapper.map(from: entry, to: targetObject, in: relationshipContext)
            onUpsert(entry, index, targetObject)
        }
    }

    func upsert(entries: [SoupEntry]) {
        return soupAccessor.accessStore { context in
            performMapping(in: context) { relationshipContext in
                upsert(entries: entries, in: context, in: relationshipContext) { _, _ , _ in }
            }
            (Result { try context.save() })
                .check(warningLogger, "Unable to save a context after upserting")
        }
    }

    func remove(soupEntryIds: [SoupEntryId]) {
        return soupAccessor.accessStore { context in
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soupMetadata.entity
            let managedObjectIds = soupEntryIds.compactMap { soupEntryId in
                (Result { try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) })
                    .check(warningLogger, "Cannot get managedObjectId from soupEntryId \(soupEntryId)")
            }
            request.predicate = soupMetadata.soupEntryIdField.predicateByValues(managedObjectIds)
            request.includesPropertyValues = false
            guard let objects = (Result { try context.fetch(request) })
                .check(warningLogger, "Cannot fetch objects to remove by soupEntryIds: \(request)")
                else { return }
            for object in objects {
                context.delete(object)
            }
            (Result { try context.save() })
                .check(warningLogger, "Unable to save a context after removing by soupEntryIds")
        }
    }

    func remove(sfIds: [SfId]) {
        return soupAccessor.accessStore { context in
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soupMetadata.entity
            request.predicate = soupMetadata.sfIdField.predicateByValues(sfIds)
            request.includesPropertyValues = false
            guard let objects = (Result { try context.fetch(request) })
                .check(warningLogger, "Cannot fetch objects to remove by sfIds: \(request)")
                else { return }
            for object in objects {
                context.delete(object)
            }
            (Result { try context.save() })
                .check(warningLogger, "Unable to save a context after removing by sfIds")
        }
    }
}
