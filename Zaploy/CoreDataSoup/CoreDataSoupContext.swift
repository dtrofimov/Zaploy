//
//  CoreDataSyncDownContext.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 07.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class CoreDataSoupContext: ExternalSoup {
    let soup: CoreDataSoup
    let soupEntryIdConverter: SoupEntryIdConverter
    let context: NSManagedObjectContext
    let warningLogger: WarningLogger

    init(soup: CoreDataSoup, soupEntryIdConverter: SoupEntryIdConverter, context: NSManagedObjectContext, warningLogger: WarningLogger) {
        self.soup = soup
        self.soupEntryIdConverter = soupEntryIdConverter
        self.context = context
        self.warningLogger = warningLogger
    }

    // MARK: ExternalSoup

    func nonDirtySfIds(syncSoupEntryId: SoupEntryId?) -> [SfId] {
        let request = NSFetchRequest<NSDictionary>()
        request.entity = soup.entity
        // TODO: Add syncSoupEntryId filtering support
        // TODO: Exclude dirty entries
        let moIdField = soup.sfIdMapper.moField
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

    var dirtySoupEntryIds: [SoupEntryId] {
        // TODO: Include dirty entries
        []
    }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry] {
        let request = NSFetchRequest<NSManagedObject>()
        request.entity = soup.entity
        let managedObjectIds: [NSManagedObjectID] = soupEntryIds.compactMap { soupEntryId in
            guard let managedObjectId = warningLogger.handle({ try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) },
                                                             "Unable to build managedObjectId from soupEntryId \(soupEntryId)")
                else { return nil }
            return managedObjectId
        }
        request.predicate = soup.soupEntryIdMapper.predicateByValues(managedObjectIds)
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
                soup.map(from: object, to: &$0)
            }
        }
    }

    func upsert(entries: [SoupEntry]) {
        let predicates: [NSPredicate] = soup.uniqueMappers.compactMap { mapper in
            let values = entries.compactMap { mapper.value(from: $0) }
            guard !values.isEmpty else { return nil }
            return mapper.predicateByValues(values)
        }
        let existingObjects: [NSManagedObject] = {
            guard !predicates.isEmpty else { return [] }
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = soup.entity
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            request.returnsObjectsAsFaults = false
            guard let objects = warningLogger.handle({ try context.fetch(request) },
                                                     "Cannot fetch by ids: \(request)")
                else { return [] }
            return objects
        }()
        for entry in entries {
            let matchingObjects: [NSManagedObject] = existingObjects.filter { object in
                soup.uniqueMappers.contains { mapper in
                    let valueFromObject = mapper.value(from: object)
                    let valueFromEntry = mapper.value(from: entry)
                    if let valueFromObject = valueFromObject, !(valueFromObject is NSObject) {
                        warningLogger.logWarning("Value cannot be mapped to NSObject: \(mapper) returns \(valueFromObject) from \(object)")
                    }
                    if let valueFromEntry = valueFromEntry, !(valueFromEntry is NSObject) {
                        warningLogger.logWarning("Value cannot be mapped to NSObject: \(mapper) returns \(valueFromEntry) from \(entry)")
                    }
                    return mapper.value(from: object) as? NSObject == mapper.value(from: entry) as? NSObject
                }
            }
            guard matchingObjects.count <= 1 else {
                warningLogger.logWarning("Multiple matching objects found for \(entry): \(matchingObjects)")
                continue
            }
            let targetObject: NSManagedObject = {
                if let existing = matchingObjects.first {
                    for mapper in soup.uniqueMappers {
                        if let existingValue = mapper.value(from: existing) as? NSObject,
                            let newValue = mapper.value(from: entry) as? NSObject,
                            existingValue != newValue {
                            warningLogger.logWarning("Unique value doesn't match for \(mapper): existingObject = \(existing), upsertedEntry = \(entry)")
                        }
                    }
                    return existing
                } else {
                    if soup.soupEntryIdMapper.value(from: entry) != nil {
                        warningLogger.logWarning("Object not found by soupEntryId while upserting \(entry)")
                    }
                    return NSEntityDescription.insertNewObject(forEntityName: soup.entityName, into: context)
                }
            }()
            soup.map(from: entry, to: targetObject)
        }
        warningLogger.handle({ try context.save() },
                             "Unable to save a context after upserting")
    }

    func remove(soupEntryIds: [SoupEntryId]) {
        let request = NSFetchRequest<NSManagedObject>()
        request.entity = soup.entity
        let managedObjectIds = soupEntryIds.compactMap { soupEntryId in
            warningLogger.handle({ try soupEntryIdConverter.managedObjectId(soupEntryId: soupEntryId) },
                                 "Cannot get managedObjectId from soupEntryId \(soupEntryId)")
        }
        request.predicate = soup.soupEntryIdMapper.predicateByValues(managedObjectIds)
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

    func remove(sfIds: [SfId]) {
        let request = NSFetchRequest<NSManagedObject>()
        request.entity = soup.entity
        request.predicate = soup.sfIdMapper.predicateByValues(sfIds)
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
