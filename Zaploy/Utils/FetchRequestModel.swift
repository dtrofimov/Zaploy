//
//  FetchRequestModel.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class FetchRequestModel<Object> where Object: ManagedObjectType {
    let moc: NSManagedObjectContext
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }

    lazy var fetchRequest = Object.safeFetchRequest

    func order<Value>(by keyPath: KeyPath<Object, Value>, ascending: Bool = true) {
        fetchRequest.sortDescriptors = (fetchRequest.sortDescriptors ?? []).with {
            $0.append(.init(keyPath: keyPath, ascending: ascending))
        }
    }

    private(set) var sectionNameKeyPathString: String?
    func setSectionNameKeyPath<Value>(_ keyPath: KeyPath<Object, Value>?) {
        sectionNameKeyPathString = keyPath.map { NSExpression(forKeyPath: $0).keyPath }
    }

    var cacheName: String? = nil

    func sink(to model: ObservableModel) -> NSFetchedResultsController<Object> {
        NSFetchedResultsController<Object>(fetchRequest: fetchRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: sectionNameKeyPathString,
                                           cacheName: cacheName)
            .then {
                let listener = FetchResultsListener { [weak model] in
                    model?.objectWillChange.send()
                }
                $0.delegate = listener
                $0.attachForLifetime(listener)
                try? $0.performFetch()
        }
    }
}

private class FetchResultsListener: NSObject, NSFetchedResultsControllerDelegate {
    let handler: () -> Void
    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        handler()
    }
}

extension ManagedObjectType {
    static func fetchRequestModel(moc: NSManagedObjectContext) -> FetchRequestModel<Self> {
        .init(moc: moc)
    }
}
