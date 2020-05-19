//
//  ManagedObjectType.swift
//  Unshift
//
//  Created by Dmitrii Trofimov on 25.10.2019.
//  Copyright © 2019 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import CoreData

protocol ManagedObjectType where Self: NSManagedObject {
    static var entityName: String { get }
}

extension ManagedObjectType {
    static var safeFetchRequest: NSFetchRequest<Self> {
        return NSFetchRequest<Self>(entityName: self.entityName)
    }
}
