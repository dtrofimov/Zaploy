//
//  SoupEntryIdMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 07.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol SoupEntryIdConverter {
    func soupEntryId(managedObjectId: NSManagedObjectID) throws -> SoupEntryId
    func managedObjectId(soupEntryId: SoupEntryId) throws -> NSManagedObjectID
}

class SoupEntryIdMapperImpl: SoupEntryIdConverter {
    enum CustomError: Error {
        case managedObjectIdIsTemporary(_ managedObjectId: NSManagedObjectID)
        case unexpectedUriRepresentationFormat(_ managedObjectId: NSManagedObjectID)
        case unexpectedPersistentStore(_ managedObjectId: NSManagedObjectID, expectedStoreId: String)
        case unexpectedEntity(_ managedObjectId: NSManagedObjectID, expectedEntityName: String)
        case cannotCreateUrl(_ string: String)
        case cannotResolveUriRepresentation(_ uriRepresentation: URL)
    }

    let storeId: String
    let persistentStore: NSPersistentStore
    let persistentStoreCoordinator: NSPersistentStoreCoordinator
    let entityName: String

    init?(persistentStore: NSPersistentStore, entityName: String) {
        guard let storeId = persistentStore.identifier else { return nil }
        self.storeId = storeId
        self.persistentStore = persistentStore
        guard let coordinator = persistentStore.persistentStoreCoordinator else { return nil }
        self.persistentStoreCoordinator = coordinator
        self.entityName = entityName
    }

    func soupEntryId(managedObjectId: NSManagedObjectID) throws -> SoupEntryId {
        guard !managedObjectId.isTemporaryID else {
            throw CustomError.managedObjectIdIsTemporary(managedObjectId)
        }
        guard managedObjectId.persistentStore == persistentStore else {
            throw CustomError.unexpectedPersistentStore(managedObjectId, expectedStoreId: storeId)
        }
        let uriRepresentation = managedObjectId.uriRepresentation()
        var string = uriRepresentation.absoluteString
        guard string.removePrefix("x-coredata://\(storeId)/") else {
            throw CustomError.unexpectedUriRepresentationFormat(managedObjectId)
        }
        let components = string.components(separatedBy: "/")
        guard components.count == 2 else {
            throw CustomError.unexpectedUriRepresentationFormat(managedObjectId)
        }
        let entityName = components[0]
        guard entityName == self.entityName else {
            throw CustomError.unexpectedEntity(managedObjectId, expectedEntityName: self.entityName)
        }
        string = components[1]
        guard string.removePrefix("p"), let intId = UInt64(string) else {
            throw CustomError.unexpectedUriRepresentationFormat(managedObjectId)
        }
        return .init(value: intId)
    }

    func managedObjectId(soupEntryId: SoupEntryId) throws -> NSManagedObjectID {
        let uriString = "x-coredata://\(storeId)/\(entityName)/p\(soupEntryId.uint64Value)"
        guard let uriRepresentation = URL(string: uriString) else {
            throw CustomError.cannotCreateUrl(uriString)
        }
        guard let result = persistentStoreCoordinator.managedObjectID(forURIRepresentation: uriRepresentation) else {
            throw CustomError.cannotResolveUriRepresentation(uriRepresentation)
        }
        return result
    }
}
