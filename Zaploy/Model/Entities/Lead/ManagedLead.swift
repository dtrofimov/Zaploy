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

    @NSManaged var id: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String
    @NSManaged var company: String
    @NSManaged var someBool: Bool
    @KVC("someCurrency") var someCurrency: Decimal?
    @KVC("syncDownId") var syncDownId: Int64?
}
