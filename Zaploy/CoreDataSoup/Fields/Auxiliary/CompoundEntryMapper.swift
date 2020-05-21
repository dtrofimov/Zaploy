//
//  CompoundEntryMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 19.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class CompoundEntryMapper: EntryMapper {
    let childMappers: [EntryMapper]
    init(childMappers: [EntryMapper]) {
        self.childMappers = childMappers
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        for mapper in childMappers {
            mapper.map(from: managedObject, to: &soupEntry)
        }
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        for mapper in childMappers {
            mapper.map(from: soupEntry, to: managedObject)
        }
    }
}
