//
//  CoreDataStack.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 29.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataStack {
    let model: NSManagedObjectModel
    let store: NSPersistentStore
    let viewContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer

    static let modelName = "Model"

    static let model: NSManagedObjectModel = {
        let url = Bundle.main.url(forResource: modelName, withExtension: "momd")
            .forceUnwrap("Model file not found")
        let model = NSManagedObjectModel(contentsOf: url)
            .forceUnwrap("Cannot read data model file")
        return model
    }()

    static func make(url: URL, completion: @escaping (CoreDataStack) -> Void) {
        let model = Self.model
        let storeDescription = NSPersistentStoreDescription(url: url).then {
            $0.type = NSSQLiteStoreType
            $0.shouldMigrateStoreAutomatically = true
            $0.shouldInferMappingModelAutomatically = true
        }
        let container = NSPersistentContainer(name: "model", managedObjectModel: model).then {
            $0.persistentStoreDescriptions = [storeDescription]
        }
        container.loadPersistentStores { store, error in
            if let error = error {
                fatalError("Cannot load persistent store: \(error)")
            }
            let store = container.persistentStoreCoordinator.persistentStore(for: url).forceUnwrap("Persistent store not found in NSPersistentStoreCoordinator")
            completion(.init(model: model,
                             store: store,
                             viewContext: container.viewContext,
                             persistentContainer: container))
        }
    }
}
