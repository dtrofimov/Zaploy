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
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                let userAccount = UserAccountManager.shared.currentUserAccount!
//                let syncManager = SyncManager.sharedInstance(forUserAccount: userAccount)
//                syncManager.deleteSync(forName: "someSyncName")
//                try! syncManager.syncDown(target: SoqlSyncDownTarget.newSyncTarget("select Id, Name from Lead"),
//                                          options: SyncOptions.newSyncOptions(forSyncDown: .overwrite),
//                                          soupName: "asdf",
//                                          syncName: "someSyncName") { syncState in
//                                            NSLog("SyncState is \(syncState)")
//                }
//            }
        }
    }
}
