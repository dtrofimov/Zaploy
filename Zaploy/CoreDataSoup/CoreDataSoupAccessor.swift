//
//  CoreDataSoupAccessor.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol CoreDataSoupAccessor {
    func accessStore(_ block: (NSManagedObjectContext) -> Void)
}

extension CoreDataSoupAccessor {
    func accessStore<T>(_ block: (NSManagedObjectContext) -> T) -> T {
        var result: T!
        accessStore {
            result = block($0)
        }
        return result
    }

    func accessStore<T>(_ block: (NSManagedObjectContext) throws -> T) throws -> T {
        let result: Result<T, Error> = accessStore {
            do {
                return .success(try block($0))
            } catch {
                return .failure(error)
            }
        }
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}

class PersistentContainerCoreDataSoupAccessor: CoreDataSoupAccessor {
    let persistentContainer: NSPersistentContainer

    internal init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    func accessStore(_ block: (NSManagedObjectContext) -> Void) {
        let context = persistentContainer.newBackgroundContext()
        context.performAndWait {
            block(context)
        }
    }
}
