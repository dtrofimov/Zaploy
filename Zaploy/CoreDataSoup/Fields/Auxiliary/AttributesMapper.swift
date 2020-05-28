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

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        guard (managedObject.entity == entity)
            .check(warningLogger, "NSManagedObject has no entity to encode attributes: \(managedObject)")
            else { return }
        soupEntry[Keys.attributes] = (soupEntry[Keys.attributes] as? [AnyHashable: Any] ?? [:]).with {
            $0[Keys.type] = entitySfName
        }
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        if warningLogger.isEnabled,
            let attributes: [AnyHashable: Any] = soupEntry[Keys.attributes]
                .checkType(warningLogger, "AttributesMapper attributes decoding"),
            let entitySfName: String = attributes[Keys.type]
                .checkType(warningLogger, "AttributesMapper type decoding") {
            warningLogger.assert(entitySfName == self.entitySfName,
                                 "Wrong entity when mapping attributes from \(soupEntry) to \(managedObject)")
        }
    }
}
