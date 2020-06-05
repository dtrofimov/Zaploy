//
//  HavingGuid.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 05.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol HavingGuid {
    var guid: String { get }
}

extension HavingGuid where Self: ManagedObjectType {
    var guid: String {
        (value(forKey: "guid") as? String)
            .forceUnwrap("Object has no guid: \(self)")
    }

    static func object(byGuid guid: String, in context: NSManagedObjectContext) -> Self? {
        let request = Self.safeFetchRequest
        request.predicate = NSPredicate(format: "self.guid == %@", guid)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    static func makeWithGuid(in context: NSManagedObjectContext) -> Self {
        let guid = UUID().uuidString
        return Self(context: context).then {
            $0.setValue(guid, forKey: "guid")
        }
    }
}
