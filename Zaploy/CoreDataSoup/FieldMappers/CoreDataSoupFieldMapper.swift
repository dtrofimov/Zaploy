//
//  FieldMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol FieldMapper {
    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry)
    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject)
}
