//
//  UserContext.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 27.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

protocol HavingUserAccount {
    var userAccount: UserAccount { get }
}

/// App-specific dependencies, resolved when a user is logged in. Used in composition root only.
/// Wrap this in a conditional compilation for unit testing.
protocol UserContext: HavingUserAccount, AnyObject {
    func resolveScreenAfterLogin() -> AppScreen
}
