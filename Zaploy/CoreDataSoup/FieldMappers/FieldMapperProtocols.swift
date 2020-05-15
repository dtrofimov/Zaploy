//
//  FieldMapperProtocols.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol FieldMapper: AnyObject {
    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry)

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject)
}

protocol HavingMOField {
    var moField: MOField { get }
}

protocol UniqueFieldMapper: FieldMapper {
    func predicateByValues(_ values: [Any]) -> NSPredicate

    func value(from soupEntry: SoupEntry) -> Any?

    func value(from managedObject: NSManagedObject) -> Any?
}

typealias SFIdMapper = UniqueFieldMapper & HavingMOField
