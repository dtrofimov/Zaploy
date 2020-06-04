//
//  ManagedUser.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 30.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class ManagedUser: NSManagedObject, User, ManagedObjectType {
    static var entityName = "User"

    @NSManaged public var id: String?
    @NSManaged public var username: String
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String
}
