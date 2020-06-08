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
