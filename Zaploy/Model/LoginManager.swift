//
//  LoginManager.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SalesforceSDKCore

class LoginManager: ObservableObject {
    static let shared = LoginManager()

    @Published private var progressTokens: Set<NSObject> = []

    var isInProgress: Bool { !progressTokens.isEmpty }

    var user: UserAccount? { UserAccountManager.shared.currentUserAccount }

    init() {
        AuthHelper.registerBlock(forCurrentUserChangeNotifications: { [weak self] in
            NSLog("Should reload")
            self?.objectWillChange.send()
        })
    }

    func login() {
        let progressToken = NSObject()
        progressTokens.insert(progressToken)
        AuthHelper.loginIfRequired { [weak self] in
            NSLog("Should reload manually")
            self?.progressTokens.remove(progressToken)
        }
    }
}
