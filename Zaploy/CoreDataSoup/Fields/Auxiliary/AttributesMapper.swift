//
//  AttributesMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class AttributesMapper: EntryMapper {
    let entity: NSEntityDescription
    let entitySfName: String
    let warningLogger: WarningLogger

    init(entity: NSEntityDescription, entitySfName: String, warningLogger: WarningLogger) {
        self.entity = entity
        self.entitySfName = entitySfName
        self.warningLogger = warningLogger
    }

    struct Keys {
        static let attributes = "attributes"
        static let type = "type"
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry, in relationshipContext: CoreDataSoupRelationshipContext) {
        guard (managedObject.entity == entity)
            .check(warningLogger, "NSManagedObject has wrong entity to encode attributes: \(managedObject)")
            else { return }
        soupEntry.sfTypeAttribute = entitySfName
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject, in relationshipContext: CoreDataSoupRelationshipContext) {
        guard (managedObject.entity == entity)
            .check(warningLogger, "NSManagedObject has wrong entity to decode attributes: \(managedObject)")
            else { return }
        if warningLogger.isEnabled,
            let entitySfName = soupEntry.sfTypeAttribute {
            warningLogger.assert(entitySfName == self.entitySfName,
                                 "Wrong entitySfName when mapping attributes from \(soupEntry) to \(managedObject)")
        }
    }
}
