//
//  CoreDataSoupPoolFactory.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 04.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData
import MobileSync

class CoreDataSoupPoolFactory {
    let model: NSManagedObjectModel
    let persistentStore: NSPersistentStore
    let pseudoSmartStore: PseudoSmartStore
    let metadataSyncManager: MetadataSyncManager
    let soupAccessor: CoreDataSoupAccessor
    let warningLogger: WarningLogger
    init(model: NSManagedObjectModel,
         persistentStore: NSPersistentStore,
         pseudoSmartStore: PseudoSmartStore,
         metadataSyncManager: MetadataSyncManager,
         soupAccessor: CoreDataSoupAccessor,
         warningLogger: WarningLogger) {
        self.model = model
        self.persistentStore = persistentStore
        self.pseudoSmartStore = pseudoSmartStore
        self.metadataSyncManager = metadataSyncManager
        self.soupAccessor = soupAccessor
        self.warningLogger = warningLogger
    }

    open func soupEntryIdConverter(entity: NSEntityDescription) -> SoupEntryIdConverter? {
        guard let entityName = entity.name
            .check(warningLogger, "Entity has no name to build soupEntryIdConverter: \(entity)")
            else { return nil }
        return SoupEntryIdConverterImpl(persistentStore: persistentStore, entityName: entityName)
    }

    struct Output {
        let soups: [CoreDataSoup]
        let upsertQueue: CoreDataSoupEntryUpsertQueue
        let relationshipContext: CoreDataSoupRelationshipContext
    }

    open func resolveUpsertQueue() -> CoreDataSoupEntryUpsertQueue {
        CoreDataSoupEntryUpsertQueueImpl(warningLogger: warningLogger)
    }
    lazy var upsertQueue = resolveUpsertQueue()

    open func resolveRelationshipContext() -> CoreDataSoupRelationshipContextImpl {
        CoreDataSoupRelationshipContextImpl(upsertQueue: upsertQueue)
    }
    lazy var relationshipContext = resolveRelationshipContext()

    func resolveSfMetadata(entitySfName: String, completion: @escaping (Metadata?) -> Void) {
        metadataSyncManager.fetchMetadata(forObject: entitySfName, mode: .cacheFirst) { metadata in
            DispatchQueue.main.async {
                completion(metadata)
            }
        }
    }

    enum CustomError: Error {
        case cannotLoadMetadata(entitySfName: String)
    }

    func make(completion: @escaping (Result<Output, Error>) -> Void) {
        var soups: [CoreDataSoup] = []
        let dispatchGroup = DispatchGroup()
        var error: Error?
        for entity in model.entities {
            guard let entitySfName = entity.sfName,
                let soupEntryIdConverter = soupEntryIdConverter(entity: entity)
                    .check(warningLogger, "Cannot build soupEntryIdConverter: \(entity)")
                else { continue }
            dispatchGroup.enter()
            resolveSfMetadata(entitySfName: entitySfName) { sfMetadata in
                defer {
                    dispatchGroup.leave()
                }
                let warningLogger = self.warningLogger
                guard let sfMetadata = sfMetadata else {
                    error = CustomError.cannotLoadMetadata(entitySfName: entitySfName)
                    return
                }
                let metadataFactory = CoreDataSoupMetadataFactory(entity: entity,
                                                                  sfMetadata: sfMetadata,
                                                                  soupEntryIdConverter: soupEntryIdConverter,
                                                                  warningLogger: self.warningLogger)
                guard let soupMetadata = metadataFactory.metadata
                    .check(warningLogger, "Cannot build metadata for \(entity)")
                    else { return }
                let relationshipContext = self.relationshipContext
                let soup = CoreDataSoup(soupMetadata: soupMetadata,
                                        soupEntryIdConverter: soupEntryIdConverter,
                                        soupAccessor: self.soupAccessor,
                                        relationshipContextResolver: { [weak relationshipContext] _ in relationshipContext },
                                        warningLogger: self.warningLogger)
                guard (Result { try self.pseudoSmartStore.addExternalSoup(soup, name: soupMetadata.soupName) })
                    .check(warningLogger, "Cannot add CoreDataSoup to PseudoSmartStore: \(soup)")
                    != nil else { return }
                self.relationshipContext.register(metadata: soupMetadata, upserter: soup)
                soups.append(soup)
            }
        }
        dispatchGroup.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(.init(soups: soups,
                                          upsertQueue: self.upsertQueue,
                                          relationshipContext: self.relationshipContext)))
            }
        }
    }
}
