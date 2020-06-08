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
    let metadataSyncManager: MetadataSyncManager
    let soupAccessor: CoreDataSoupAccessor
    let relationshipContextResolver: (NSManagedObjectContext) -> CoreDataSoupRelationshipContext?
    let warningLogger: WarningLogger
    init(model: NSManagedObjectModel,
         persistentStore: NSPersistentStore,
         metadataSyncManager: MetadataSyncManager,
         soupAccessor: CoreDataSoupAccessor,
         relationshipContextResolver: @escaping (NSManagedObjectContext) -> CoreDataSoupRelationshipContext?,
         warningLogger: WarningLogger) {
        self.model = model
        self.persistentStore = persistentStore
        self.metadataSyncManager = metadataSyncManager
        self.soupAccessor = soupAccessor
        self.relationshipContextResolver = relationshipContextResolver
        self.warningLogger = warningLogger
    }

    open func resolveSoupEntryIdConverter(entity: NSEntityDescription) -> SoupEntryIdConverter? {
        guard let entityName = entity.name
            .check(warningLogger, "Entity has no name to build soupEntryIdConverter: \(entity)")
            else { return nil }
        return SoupEntryIdConverterImpl(persistentStore: persistentStore, entityName: entityName)
    }

    open func resolveSfMetadata(entitySfName: String, completion: @escaping (Metadata?) -> Void) {
        metadataSyncManager.fetchMetadata(forObject: entitySfName, mode: .cacheFirst) { metadata in
            DispatchQueue.main.async {
                completion(metadata)
            }
        }
    }

    open func resolveSoupMetadata(entity: NSEntityDescription, sfMetadata: Metadata, soupEntryIdConverter: SoupEntryIdConverter) -> CoreDataSoupMetadata? {
        CoreDataSoupMetadataFactory(entity: entity,
                                    sfMetadata: sfMetadata,
                                    soupEntryIdConverter: soupEntryIdConverter,
                                    warningLogger: warningLogger)
            .metadata
            .check(warningLogger, "Cannot build metadata for \(entity)")
    }

    open func resolveSoup(soupMetadata: CoreDataSoupMetadata, soupEntryIdConverter: SoupEntryIdConverter) -> CoreDataSoup? {
        return CoreDataSoupImpl(soupMetadata: soupMetadata,
                                soupAccessor: self.soupAccessor,
                                relationshipContextResolver: self.relationshipContextResolver,
                                warningLogger: self.warningLogger)
    }

    enum CustomError: Error {
        case cannotLoadMetadata(entitySfName: String)
    }

    func make(soupRegistrator: @escaping (CoreDataSoup) -> Void, completion: @escaping (Result<(), Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var error: Error?
        for entity in model.entities {
            guard let entitySfName = entity.sfName,
                let soupEntryIdConverter = resolveSoupEntryIdConverter(entity: entity)
                    .check(warningLogger, "Cannot build soupEntryIdConverter: \(entity)")
                else { continue }
            dispatchGroup.enter()
            resolveSfMetadata(entitySfName: entitySfName) { sfMetadata in
                defer {
                    dispatchGroup.leave()
                }
                guard let sfMetadata = sfMetadata else {
                    error = CustomError.cannotLoadMetadata(entitySfName: entitySfName)
                    return
                }
                guard let soupMetadata = self.resolveSoupMetadata(entity: entity, sfMetadata: sfMetadata, soupEntryIdConverter: soupEntryIdConverter),
                    let soup = self.resolveSoup(soupMetadata: soupMetadata, soupEntryIdConverter: soupEntryIdConverter)
                    else { return }
                soupRegistrator(soup)
            }
        }
        dispatchGroup.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
