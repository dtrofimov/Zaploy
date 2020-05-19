//
//  HavingId.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 18.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol HavingId {
    var id: String? { get }
}

extension HavingId where Self: ManagedObjectType {
    var id: String? {
        get { self.id }
        set { self.setValue(newValue, forKey: "id") }
    }

    static func object(byId id: String, in context: NSManagedObjectContext) -> Self? {
        let request = Self.safeFetchRequest
        request.predicate = NSPredicate(format: "self.id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    static func findOrCreate(byId id: String, in context: NSManagedObjectContext) -> Self {
        if let result = object(byId: id, in: context) { return result }
        return Self(context: context).then {
            $0.id = id
        }
    }
}
