//
//  LoginManager.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SalesforceSDKCore

typealias UserAccount = SalesforceSDKCore.UserAccount

class LoginManager: ObservableObject {
    let userAccountManager: UserAccountManager
    let authHelper: AuthHelper.Type
    let userContextManager: UserContextManager

    init(userAccountManager: UserAccountManager, authHelper: AuthHelper.Type, userContextManager: UserContextManager) {
        self.userAccountManager = userAccountManager
        self.authHelper = authHelper
        self.userContextManager = userContextManager
        refreshUserContext()
        authHelper.registerBlock(forCurrentUserChangeNotifications: { [weak self] in
            self?.refreshUserContext()
        })
    }

    @Published private(set) var userAccount: UserAccount?

    func refreshUserContext() {
        let userAccount = userAccountManager.currentUserAccount
        if self.userAccount == userAccount { return }
        self.userAccount = userAccount
        userContextManager.userAccountDidChange(to: userAccount)
    }

    @Published private var progressTokens: Set<NSObject> = []

    var isInProgress: Bool { !progressTokens.isEmpty }

    func login() {
        let progressToken = NSObject()
        progressTokens.insert(progressToken)
        authHelper.loginIfRequired { [weak self] in
            self?.progressTokens.remove(progressToken)
            self?.refreshUserContext()
        }
    }
}
