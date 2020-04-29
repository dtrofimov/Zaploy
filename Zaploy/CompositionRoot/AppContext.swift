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
    lazy var userContextManager = UserContextManagerImpl(userContextAsyncResolver: resolveUserContext(userAccount:completion:))
    lazy var loginManager = LoginManager(userAccountManager: userAccountManager, authHelper: AuthHelper.self, userContextManager: userContextManager)
}

class AppUserContext {
    let appContext: AppContext
    let userAccount: UserAccount

    private init(appContext: AppContext, userAccount: UserAccount) {
        self.appContext = appContext
        self.userAccount = userAccount
    }

    // MARK: SF SDK

    static let syncDownName = "syncDownName"
    static let syncUpName = "syncUpName"
    static let soupName = "someSoupName"
    lazy var smartStore = SmartStore.shared(withName: SmartStore.defaultStoreName, forUserAccount: userAccount)
        .forceUnwrap("Cannot resolve shared SmartStore")
    lazy var externalSoup = DemoExternalSoup()
    lazy var pseudoSmartStore = PseudoSmartStore(smartStore: smartStore).then {
        try? $0.addExternalSoup(externalSoup, name: Self.soupName)
    }
    lazy var replacedSmartStore = unsafeBitCast(pseudoSmartStore, to: SmartStore.self)
    lazy var syncManager = SyncManager.sharedInstance(store: replacedSmartStore)
        .forceUnwrap("Cannot resolve shared SyncManager")
    lazy var metadataSyncManager = MetadataSyncManager.sharedInstance(userAccount, smartStore: replacedSmartStore.name)
    lazy var layoutSyncManager = LayoutSyncManager.sharedInstance(userAccount, smartStore: replacedSmartStore.name)

    // MARK: Core Data

    lazy var coreDataUrl: URL =
        URL(fileURLWithPath: smartStore.path.forceUnwrap("SmartStore has no path"))
            .deletingLastPathComponent()
            .appendingPathComponent("coreDataStore.sqlite")
    var coreDataStack: CoreDataStack!

    static func make(appContext: AppContext, userAccount: UserAccount, completion: @escaping (AppUserContext) -> Void) {
        let result = AppUserContext(appContext: appContext, userAccount: userAccount)
        CoreDataStack.make(url: result.coreDataUrl) {
            result.coreDataStack = $0
            completion(result)
        }
    }

    lazy var playground = SyncDownPlayground(syncDownName: Self.syncDownName,
                                             syncUpName: Self.syncUpName,
                                             soupName: Self.soupName,
                                             userAccount: userAccount,
                                             syncManager: syncManager,
                                             externalSoup: externalSoup,
                                             metadataSyncManager: metadataSyncManager,
                                             layoutSyncManager: layoutSyncManager)


}

extension AppContext {
    func resolveRootScreen() -> AppScreen {
        LoginView(loginManager: loginManager, userContextManager: userContextManager, nextScreenResolver: { $0.resolveScreenAfterLogin() })
    }

    func resolveUserContext(userAccount: UserAccount, completion: @escaping (UserContext) -> Void) {
        AppUserContext.make(appContext: self, userAccount: userAccount, completion: completion)
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
