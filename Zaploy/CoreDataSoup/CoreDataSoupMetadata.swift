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
    let sfName: String?
    let sfIdField: FetchableField & HavingMOField
    let soupEntryIdField: FetchableField
    let syncIdField: FetchableField?
    let attributesMapper: EntryMapper?
    let otherUniqueFields: [FetchableField]
    let sfFieldsForMOFields: [MOField: SFField]
    let soupMapper: EntryMapper

    var uniqueFields: [FetchableField] {
        [sfIdField, soupEntryIdField] + otherUniqueFields
    }
}
