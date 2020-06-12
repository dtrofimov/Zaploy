//
//  CoreDataSoupPool.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class CoreDataSoupPool {
    let upsertQueue: CoreDataSoupEntryUpsertQueue
    internal init(upsertQueue: CoreDataSoupEntryUpsertQueue) {
        self.upsertQueue = upsertQueue
    }

    private(set) var soups: [CoreDataSoup] = .init()
    private(set) var soupsForEntities: [NSEntityDescription: CoreDataSoup] = .init()
    private(set) var soupsForEntityNames: [String: CoreDataSoup] = .init()
    private(set) var soupsForEntitySfNames: [String: CoreDataSoup] = .init()
    private(set) var soupsForSoupNames: [String: CoreDataSoup] = .init()

    func register(soup: CoreDataSoup) {
        soups.append(soup)
        soupsForEntities[soup.metadata.entity] = soup
        if let entityName = soup.metadata.entity.name {
            soupsForEntityNames[entityName] = soup
        }
        if let sfName = soup.metadata.sfName {
            soupsForEntitySfNames[sfName] = soup
        }
        soupsForSoupNames[soup.metadata.soupName] = soup
    }
}

extension CoreDataSoupPool: CoreDataSoupRelationshipContext {
    func upserter(entitySfName: String) -> CoreDataSoupEntryUpserter? {
        soupsForEntitySfNames[entitySfName]
    }

    func metadata(entity: NSEntityDescription) -> CoreDataSoupMetadata? {
        soupsForEntities[entity]?.metadata
    }
}
