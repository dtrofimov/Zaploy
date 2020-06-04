//
//  FieldProtocols.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

typealias MOField = NSPropertyDescription

protocol EntryMapper: AnyObject {
    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry, in relationshipContext: CoreDataSoupRelationshipContext)

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject, in relationshipContext: CoreDataSoupRelationshipContext)
}

protocol HavingMOField {
    var moField: MOField { get }
}

protocol HavingSFField {
    var sfField: SFField { get }
}

protocol FetchableField {
    func predicateByValues(_ values: [Any]) -> NSPredicate

    func value(from soupEntry: SoupEntry) -> Any?

    func setValue(_ value: Any?, to soupEntry: inout SoupEntry)

    func value(from managedObject: NSManagedObject) -> Any?
}
