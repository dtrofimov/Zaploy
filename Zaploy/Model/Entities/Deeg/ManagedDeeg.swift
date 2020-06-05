//
//  ManagedDeeg.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 05.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class ManagedDeeg: NSManagedObject, Deeg, ManagedObjectType {
    static let entityName = "Deeg"

    @NSManaged var name: String

    @NSManaged var moCreatedBy: ManagedUser?
    var createdBy: User? { moCreatedBy }

    @NSManaged var moReproses: Set<ManagedReprose>
    var reproses: [Reprose] { moReproses.sortedByHash }
}
