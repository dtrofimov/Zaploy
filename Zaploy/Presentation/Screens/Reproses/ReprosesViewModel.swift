//
//  ReprosesViewModel.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

protocol ReprosesViewModel: ObservableModel {
    var reproses: [Reprose] { get }
}

class ReprosesViewModelImpl: NSObject, ReprosesViewModel, ObservableObject {
    let moc: NSManagedObjectContext
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }

    lazy var reprosesFrc = ManagedReprose.fetchRequestModel(moc: moc).then {
        $0.order(by: \.name)
    }.sink(to: self)

    var reproses: [Reprose] { reprosesFrc.fetchedObjects ?? [] }
}
