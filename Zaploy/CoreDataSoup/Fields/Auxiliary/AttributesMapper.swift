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
        guard managedObject.entity == entity else { return }
        soupEntry[Keys.attributes] = (soupEntry[Keys.attributes] as? [AnyHashable: Any] ?? [:]).with {
            $0[Keys.type] = entitySfName
        }
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        if let attributes = soupEntry[Keys.attributes] as? [AnyHashable: Any],
            let entitySfName = attributes[Keys.type] as? String {
            warningLogger.assert(entitySfName == self.entitySfName, "Wrong entity when mapping attributes from \(soupEntry) to \(managedObject)")
        }
    }
}
