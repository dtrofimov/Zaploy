//
//  Reprose.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 05.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

protocol Reprose:
    ObservableModel,
    HavingId,
    HavingGuid,
    HavingCreatedBy
{
    var name: String { get }
    var isFavorite: Bool { get }
    var deeg: Deeg? { get }
    var leads: [Lead] { get }
}
