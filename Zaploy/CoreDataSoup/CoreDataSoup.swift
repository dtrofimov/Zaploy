//
//  CoreDataSoupContext.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 07.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData
import Then

class CoreDataSoup: ExternalSoup {
    let soupMetadata: CoreDataSoupMetadata
    let soupMapper: EntryMapper
    let soupEntryIdConverter: SoupEntryIdConverter
    let soupAccessor: CoreDataSoupAccessor
    let warningLogger: WarningLogger

    init(soupMetadata: CoreDataSoupMetadata, soupMapper: EntryMapper, soupEntryIdConverter: SoupEntryIdConverter, soupAccessor: CoreDataSoupAccessor, warningLogger: WarningLogger) {
        self.soupMetadata = soupMetadata
        self.soupMapper = soupMapper
        self.soupEntryIdConverter = soupEntryIdConverter
        self.soupAccessor = soupAccessor
        self.warningLogger = warningLogger
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
            guard let dicts = warningLogger.handle({ try context.fetch(request) },
                                                   "Unable to fetch nonDirtySfIds: \(request)")
                else { return [] }
            return dicts.compactMap {
                let sfId = $0[moIdField.name] as? SfId
                warningLogger.assert(sfId != nil, "No sfId found when fetching nonDirtySfIds: \($0)")
                return sfId
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
                guard let managedObjectId = warningLogger.handle({ try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) },
                                                                 "Unable to build managedObjectId from soupEntryId \(soupEntryId)")
                    else { return nil }
                return managedObjectId
            }
            request.predicate = soupMetadata.soupEntryIdField.predicateByValues(managedObjectIds)
            request.returnsObjectsAsFaults = false
            guard let fetchedObjects = warningLogger.handle({ try context.fetch(request) },
                                                            "Unable to fetch entries for soupEntryIds: \(request)")
                else { return [] }
            let objectsForManagedObjectIds: [NSManagedObjectID: NSManagedObject] = fetchedObjects.reduce(into: [:]) {
                $0[$1.objectID] = $1
            }
            return managedObjectIds.compactMap {
                guard let object = objectsForManagedObjectIds[$0] else {
                    warningLogger.logWarning("Entry not found for managedObjectId \($0)")
                    return nil
                }
                return SoupEntry().with {
                    soupMapper.map(from: object, to: &$0)
                }
            }
        }
    }

    func upsert(entries: [SoupEntry]) {
        return soupAccessor.accessStore { context in
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
                guard let objects = warningLogger.handle({ try context.fetch(request) },
                                                         "Cannot fetch by ids: \(request)")
                    else { return [] }
                return objects
            }()
            for entry in entries {
                let matchingObjects: [NSManagedObject] = existingObjects.filter { object in
                    soupMetadata.uniqueFields.contains { field in
                        let valueFromObject = field.value(from: object)
                        let valueFromEntry = field.value(from: entry)
                        if let valueFromObject = valueFromObject, !(valueFromObject is NSObject) {
                            warningLogger.logWarning("Value cannot be mapped to NSObject: \(field) returns \(valueFromObject) from \(object)")
                        }
                        if let valueFromEntry = valueFromEntry, !(valueFromEntry is NSObject) {
                            warningLogger.logWarning("Value cannot be mapped to NSObject: \(field) returns \(valueFromEntry) from \(entry)")
                        }
                        return field.value(from: object) as? NSObject == field.value(from: entry) as? NSObject
                    }
                }
                guard matchingObjects.count <= 1 else {
                    warningLogger.logWarning("Multiple matching objects found for \(entry): \(matchingObjects)")
                    continue
                }
                let targetObject: NSManagedObject = {
                    if let existing = matchingObjects.first {
                        for field in soupMetadata.uniqueFields {
                            if let existingValue = field.value(from: existing) as? NSObject,
                                let newValue = field.value(from: entry) as? NSObject,
                                existingValue != newValue {
                                warningLogger.logWarning("Unique value doesn't match for \(field): existingObject = \(existing), upsertedEntry = \(entry)")
                            }
                        }
                        return existing
                    } else {
                        if soupMetadata.soupEntryIdField.value(from: entry) != nil {
                            warningLogger.logWarning("Object not found by soupEntryId while upserting \(entry)")
                        }
                        return NSManagedObject(entity: soupMetadata.entity, insertInto: context)
                    }
                }()
                soupMapper.map(from: entry, to: targetObject)
            }
            warningLogger.handle({ try context.save() },
                                 "Unable to save a context after upserting")
        }
    }

    func remove(soupEntryIds: [SoupEntryId]) {
        return soupAccessor.accessStore { context in
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soupMetadata.entity
            let managedObjectIds = soupEntryIds.compactMap { soupEntryId in
                warningLogger.handle({ try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) },
                                     "Cannot get managedObjectId from soupEntryId \(soupEntryId)")
            }
            request.predicate = soupMetadata.soupEntryIdField.predicateByValues(managedObjectIds)
            request.includesPropertyValues = false
            guard let objects = warningLogger.handle({ try context.fetch(request) },
                                                     "Cannot fetch objects to remove by soupEntryIds: \(request)")
                else { return }
            for object in objects {
                context.delete(object)
            }
            warningLogger.handle({ try context.save() },
                                 "Unable to save a context after removing by soupEntryIds")
        }
    }

    func remove(sfIds: [SfId]) {
        return soupAccessor.accessStore { context in
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soupMetadata.entity
            request.predicate = soupMetadata.sfIdField.predicateByValues(sfIds)
            request.includesPropertyValues = false
            guard let objects = warningLogger.handle({ try context.fetch(request) },
                                                     "Cannot fetch objects to remove by sfIds: \(request)")
                else { return }
            for object in objects {
                context.delete(object)
            }
            warningLogger.handle({ try context.save() },
                                 "Unable to save a context after removing by sfIds")
        }
    }
}
