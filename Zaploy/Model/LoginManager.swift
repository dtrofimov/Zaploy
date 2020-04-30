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
    let notificationCenter: NotificationCenter

    init(userAccountManager: UserAccountManager, authHelper: AuthHelper.Type, userContextManager: UserContextManager, notificationCenter: NotificationCenter) {
        self.userAccountManager = userAccountManager
        self.authHelper = authHelper
        self.userContextManager = userContextManager
        self.notificationCenter = notificationCenter
        refreshUserContext()
        notificationCenter.addObserver(self, selector: #selector(refreshUserContext), name: .init(UserAccountManager.didLogoutUser), object: nil)
        notificationCenter.addObserver(self, selector: #selector(refreshUserContext), name: .init(UserAccountManager.didSwitchUser), object: nil)
    }

    @Published private(set) var userAccount: UserAccount?

    @objc func refreshUserContext() {
        let userAccount = userAccountManager.currentUserAccount
        if self.userAccount == userAccount { return }
        self.userAccount = userAccount
        userContextManager.userAccountDidChange(to: userAccount)
    }

    @Published private var progressTokens: Set<NSObject> = []

    var isInProgress: Bool { !progressTokens.isEmpty || userAccount?.loginState == .loggingOut }

    func login() {
        let progressToken = NSObject()
        progressTokens.insert(progressToken)
        authHelper.loginIfRequired { [weak self] in
            self?.progressTokens.remove(progressToken)
            self?.refreshUserContext()
        }
    }

    func logout() {
        userAccountManager.logout()
        refreshUserContext()
    }
}
