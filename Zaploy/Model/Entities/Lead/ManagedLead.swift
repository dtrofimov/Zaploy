//
//  ManagedLead.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 30.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class ManagedLead: NSManagedObject, Lead, ManagedObjectType {
    static let entityName = "Lead"

    @NSManaged public var id: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String
    @NSManaged public var company: String
}
