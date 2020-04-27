//
//  AppCompositionRoot.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 23.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import MobileSync

class AppContext {
    /// To be used in AppDelegate and SceneDelegate entry points only.
    static let shared = AppContext()

    lazy var userAccountManager = UserAccountManager.shared
    lazy var loginManager = LoginManager(userAccountManager: userAccountManager, authHelper: AuthHelper.self, userContextResolver: resolveUserContext(userAccount:))
}

class AppUserContext {
    let appContext: AppContext
    let userAccount: UserAccount
    init(appContext: AppContext, userAccount: UserAccount) {
        self.appContext = appContext
        self.userAccount = userAccount
    }

    let syncDownName = "syncDownName"
    let syncUpName = "syncUpName"
    let soupName = "someSoupName"
    lazy var smartStore = SmartStore.shared(withName: SmartStore.defaultStoreName, forUserAccount: userAccount)!
    lazy var externalSoup = DemoExternalSoup()
    lazy var pseudoSmartStore = PseudoSmartStore(smartStore: smartStore).then {
        try? $0.addExternalSoup(externalSoup, name: soupName)
    }
    lazy var replacedSmartStore = unsafeBitCast(pseudoSmartStore, to: SmartStore.self)
    lazy var syncManager = SyncManager.sharedInstance(store: replacedSmartStore)!
    lazy var metadataSyncManager = MetadataSyncManager.sharedInstance(userAccount, smartStore: replacedSmartStore.name)
    lazy var layoutSyncManager = LayoutSyncManager.sharedInstance(userAccount, smartStore: replacedSmartStore.name)
    lazy var playground = SyncDownPlayground(syncDownName: syncDownName,
                                             syncUpName: syncUpName,
                                             soupName: soupName,
                                             userAccount: userAccount,
                                             syncManager: syncManager,
                                             externalSoup: externalSoup,
                                             metadataSyncManager: metadataSyncManager,
                                             layoutSyncManager: layoutSyncManager)
}

extension AppContext {
    func resolveRootScreen() -> AppScreen {
        LoginView(loginManager: loginManager, nextScreenResolver: { $0.resolveScreenAfterLogin() })
    }

    func resolveUserContext(userAccount: UserAccount) -> UserContext {
        AppUserContext(appContext: self, userAccount: userAccount)
    }
}

extension AppUserContext: UserContext {
    func resolveScreenAfterLogin() -> AppScreen {
        PlaygroundView(playground: playground, entryDetailsScreenResolver: resolveEntryDetailsScreen(entry:))
    }

    func resolveEntryDetailsScreen(entry: SoupEntry) -> AppScreen {
        EntryDetailsView(entry: entry)
    }
}
