//
//  ManagedReprose.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 05.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class ManagedReprose: NSManagedObject, Reprose, ManagedObjectType {
    static let entityName = "Reprose"

    @NSManaged var isFavorite: Bool
    @NSManaged var name: String

    @NSManaged var moCreatedBy: ManagedUser?
    var createdBy: User? { moCreatedBy }

    @NSManaged var moDeeg: ManagedDeeg?
    var deeg: Deeg? { moDeeg }

    @NSManaged var moLeads: Set<ManagedLead>
    var leads: [Lead] { moLeads.sortedByHash }
}
