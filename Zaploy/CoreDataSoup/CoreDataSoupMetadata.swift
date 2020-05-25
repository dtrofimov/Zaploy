//
//  CoreDataSoupMetadata.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 19.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

struct CoreDataSoupMetadata {
    let entity: NSEntityDescription
    let sfIdField: FetchableField & HavingMOField
    let soupEntryIdField: FetchableField
    let syncIdField: FetchableField?
    let otherUniqueFields: [FetchableField]
    let sfFieldsForMOFields: [MOField: SFField]

    var uniqueFields: [FetchableField] {
        [sfIdField, soupEntryIdField] + otherUniqueFields
    }
}
