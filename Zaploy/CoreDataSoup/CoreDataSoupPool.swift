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

    var soups: [CoreDataSoup] = .init()
    var soupsForEntities: [NSEntityDescription: CoreDataSoup] = .init()
    var soupsForEntitySfNames: [String: CoreDataSoup] = .init()
    var soupsForSoupNames: [String: CoreDataSoup] = .init()

    func register(soup: CoreDataSoup) {
        soups.append(soup)
        soupsForEntities[soup.soupMetadata.entity] = soup
        if let sfName = soup.soupMetadata.sfName {
            soupsForEntitySfNames[sfName] = soup
        }
        soupsForSoupNames[soup.soupMetadata.soupName] = soup
    }
}

extension CoreDataSoupPool: CoreDataSoupRelationshipContext {
    func upserter(entitySfName: String) -> CoreDataSoupEntryUpserter? {
        soupsForEntitySfNames[entitySfName]
    }

    func metadata(entity: NSEntityDescription) -> CoreDataSoupMetadata? {
        soupsForEntities[entity]?.soupMetadata
    }
}
