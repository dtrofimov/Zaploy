//
//  UserContext.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 27.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

/// App-specific dependencies, resolved when a user is logged in.
/// Wrap this in a conditional compilation for unit testing.
protocol UserContext: AnyObject {
    var userAccount: UserAccount { get }

    func resolveScreenAfterLogin() -> AppScreen
}
