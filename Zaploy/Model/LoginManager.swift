//
//  LoginManager.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SalesforceSDKCore

class LoginManager: ObservableObject {
    let userAccountManager: UserAccountManager
    let authHelper: AuthHelper.Type
    let userContextResolver: (UserAccount) -> UserContext

    init(userAccountManager: UserAccountManager, authHelper: AuthHelper.Type, userContextResolver: @escaping (UserAccount) -> UserContext) {
        self.userAccountManager = userAccountManager
        self.authHelper = authHelper
        self.userContextResolver = userContextResolver
        refreshUserContext()
        authHelper.registerBlock(forCurrentUserChangeNotifications: { [weak self] in
            self?.refreshUserContext()
        })
    }

    @Published private(set) var userContext: UserContext?

    func refreshUserContext() {
        let userAccount = userAccountManager.currentUserAccount
        if userContext?.userAccount == userAccount { return }
        userContext = userAccount.map { userContextResolver($0) }
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
