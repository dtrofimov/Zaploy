//
//  LeadsViewModel.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol LeadsViewModel: ObservableModel {
    var leads: [Lead] { get }
}

class LeadsViewModelImpl: NSObject, LeadsViewModel, ObservableObject {
    let moc: NSManagedObjectContext
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }

    lazy var leadsFrc = ManagedLead.fetchRequestModel(moc: moc).then {
        $0.order(by: \.firstName)
        $0.order(by: \.lastName)
    }.sink(to: self)

    var leads: [Lead] { leadsFrc.fetchedObjects ?? [] }
}
