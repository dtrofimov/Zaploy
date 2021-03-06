//
//  User.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 30.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

protocol User:
    ObservableModel,
    HavingId,
    HavingNameComponents
{
    var username: String { get }
}
