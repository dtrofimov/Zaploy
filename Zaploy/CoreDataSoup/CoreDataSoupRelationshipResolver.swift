//
//  CoreDataSoupRelationshipResolver.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 27.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol CoreDataSoupRelationshipResolver {
    func enqueueUpsertRelationship(entry: SoupEntry, in context: NSManagedObjectContext, completion: (NSManagedObject?) -> Void)

    func referenceEntry(from object: NSManagedObject) -> SoupEntry?
}
