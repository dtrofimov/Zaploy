//
//  Lead.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 30.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

protocol Lead: HavingName, HavingId {
    var someBool: Bool { get }
    var someCurrency: Decimal? { get }
}
