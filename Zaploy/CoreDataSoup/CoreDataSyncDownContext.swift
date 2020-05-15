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
    let soupEntryIdMapper: SoupEntryIdMapper
    let context: NSManagedObjectContext

    init(soup: CoreDataSoup, soupEntryIdMapper: SoupEntryIdMapper, context: NSManagedObjectContext) {
        self.soup = soup
        self.soupEntryIdMapper = soupEntryIdMapper
        self.context = context
    }

    // MARK: ExternalSoup

    func nonDirtySfIds(syncSoupEntryId: SoupEntryId?) -> [SfId] {
        let request = NSFetchRequest<NSDictionary>()
        request.entity = soup.entity
        // TODO: Add syncSoupEntryId filtering support
        guard let dicts = try? context.fetch(request) else { return [] }
        return dicts.compactMap {
            $0[soup.idField.name] as? SfId
        }
    }

    var dirtySoupEntryIds: [SoupEntryId] {
        []
    }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry] {
        let request = NSFetchRequest<NSManagedObject>()
        request.entity = soup.entity
        let managedObjectIds = soupEntryIds.compactMap { try? soupEntryIdMapper.managedObjectId(soupEntryId: $0) }
        request.predicate = NSPredicate(format: "self in %@", managedObjectIds)
        request.returnsObjectsAsFaults = false
        guard let unsortedObjects = try? context.fetch(request) else { return [] }
        let objectsForManagedObjectIds = unsortedObjects.reduce(into: [NSManagedObjectID: NSManagedObject]()) {
            $0[$1.objectID] = $1
        }
        return managedObjectIds.compactMap {
            guard let object = objectsForManagedObjectIds[$0] else { return nil }
            return SoupEntry().with {
                for field in soup.allFields {
                    field.map(from: object, to: &$0)
                }
            }
        }
    }

    ///////// STOPPED HERE

    func upsert(entries: [SoupEntry]) throws {
        fatalError()
    }

    func remove(soupEntryIds: [SoupEntryId]) {
        fatalError()
    }

    func remove(sfIds: [SfId]) {
        fatalError()
    }
}
