//
//  CoreDataSoupEntryUpsertQueue.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 01.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol CoreDataSoupEntryUpserter: AnyObject {
    func upsert(entries: [SoupEntry], in context: NSManagedObjectContext, in relationshipContext: CoreDataSoupRelationshipContext, onUpsert: (_ entry: SoupEntry, _ index: Int, _ object: NSManagedObject?) -> Void)
}

protocol CoreDataSoupEntryUpsertQueue {
    func enqueueUpsertRelationship(entry: SoupEntry, completion: @escaping (NSManagedObject?) -> Void)

    func processQueue(in context: NSManagedObjectContext, in relationshipContext: CoreDataSoupRelationshipContext)
}

class CoreDataSoupEntryUpsertQueueImpl: CoreDataSoupEntryUpsertQueue {
    let warningLogger: WarningLogger
    internal init(warningLogger: WarningLogger) {
        self.warningLogger = warningLogger
    }

    private struct QueueItem {
        let entry: SoupEntry
        let completion: (NSManagedObject?) -> Void
    }
    private var queueItems: [QueueItem] = []

    func enqueueUpsertRelationship(entry: SoupEntry, completion: @escaping (NSManagedObject?) -> Void) {
        queueItems.append(.init(entry: entry,
                                completion: completion))
    }

    func processQueue(in context: NSManagedObjectContext, in relationshipContext: CoreDataSoupRelationshipContext) {
        while let firstItem = queueItems.first {
            guard let entitySfName = firstItem.entry.sfTypeAttribute
                .check(warningLogger, "CoreDataSoupEntryUpsertQueue item has no type attribute: \(firstItem.entry)"),
                let upserter = relationshipContext.upserter(entitySfName: entitySfName)
                    .check(warningLogger, "CoreDataSoupEntryUpsertQueue cannot resolve an upserter for entitySfName: \(entitySfName), \(firstItem.entry)")
                else {
                    firstItem.completion(nil)
                    queueItems.removeFirst()
                    continue
            }
            let itemsToProcess: [QueueItem] = queueItems.removeAllAndReturn {
                $0.entry.sfTypeAttribute.flatMap { relationshipContext.upserter(entitySfName: $0) } === upserter
            }
            upserter.upsert(entries: itemsToProcess.map { $0.entry }, in: context, in: relationshipContext) { entry, index, object in
                itemsToProcess[index].completion(object)
            }
        }
    }
}

class EmptyCoreDataSoupEntryUpsertQueue: CoreDataSoupEntryUpsertQueue {
    static let empty = EmptyCoreDataSoupEntryUpsertQueue()

    func enqueueUpsertRelationship(entry: SoupEntry, completion: @escaping (NSManagedObject?) -> Void) {
        completion(nil)
    }

    func processQueue(in context: NSManagedObjectContext, in relationshipContext: CoreDataSoupRelationshipContext) {
    }
}
