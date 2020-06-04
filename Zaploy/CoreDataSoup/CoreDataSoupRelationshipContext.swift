//
//  CoreDataSoupRelationshipContext.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 02.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol CoreDataSoupRelationshipContext {
    var upsertQueue: CoreDataSoupEntryUpsertQueue { get }

    func upserter(entitySfName: String) -> CoreDataSoupEntryUpserter?

    func metadata(entity: NSEntityDescription) -> CoreDataSoupMetadata?
}

class CoreDataSoupRelationshipContextImpl: CoreDataSoupRelationshipContext {
    let upsertQueue: CoreDataSoupEntryUpsertQueue
    init(upsertQueue: CoreDataSoupEntryUpsertQueue) {
        self.upsertQueue = upsertQueue
    }

    private var upsertersForEntitySfNames: [String: CoreDataSoupEntryUpserter] = [:]
    private var metadatasForEntities: [NSEntityDescription: CoreDataSoupMetadata] = [:]

    func register(metadata: CoreDataSoupMetadata, upserter: CoreDataSoupEntryUpserter) {
        metadatasForEntities[metadata.entity] = metadata
        if let sfName = metadata.sfName {
            upsertersForEntitySfNames[sfName] = upserter
        }
    }

    func upserter(entitySfName: String) -> CoreDataSoupEntryUpserter? {
        upsertersForEntitySfNames[entitySfName]
    }

    func metadata(entity: NSEntityDescription) -> CoreDataSoupMetadata? {
        metadatasForEntities[entity]
    }
}

class EmptyCoreDataSoupRelationshipContext: CoreDataSoupRelationshipContext {
    static let empty = EmptyCoreDataSoupRelationshipContext()

    var upsertQueue: CoreDataSoupEntryUpsertQueue { EmptyCoreDataSoupEntryUpsertQueue.empty }

    func upserter(entitySfName: String) -> CoreDataSoupEntryUpserter? {
        nil
    }

    func metadata(entity: NSEntityDescription) -> CoreDataSoupMetadata? {
        nil
    }
}
