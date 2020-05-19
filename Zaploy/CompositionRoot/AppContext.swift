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
    lazy var loginManager = LoginManager(userAccountManager: userAccountManager, authHelper: AuthHelper.self, userContextManager: userContextManager, notificationCenter: .default)
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
    lazy var pseudoSmartStore = PseudoSmartStore(smartStore: smartStore)
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
    let entityName = "Lead"
    lazy var entity = coreDataStack.model.entitiesByName[entityName].forceUnwrap("Lead entity not found")
    var sfMetadata: Metadata!
    lazy var soupEntryIdConverter = SoupEntryIdConverterImpl(persistentStore: coreDataStack.store,
                                                             entityName: entityName)
        .forceUnwrap("Unable to create SoupEntryIdConverter")
    lazy var warningLogger = ConsoleWarningLogger()
    lazy var soupMapper: CoreDataSoupMapperImpl = Result {
        try .init(entity: entity,
                  sfMetadata: sfMetadata,
                  soupEntryIdConverter: soupEntryIdConverter,
                  warningLogger: warningLogger)
    }.forceUnwrap("Cannot create CoreDataSoupMapperImpl")
    lazy var soupAccessor = PersistentContainerCoreDataSoupAccessor(persistentContainer: coreDataStack.persistentContainer)
    lazy var externalSoup = CoreDataSoup(soupMapper: soupMapper,
                                         soupEntryIdConverter: soupEntryIdConverter,
                                         soupAccessor: soupAccessor,
                                         warningLogger: warningLogger)

    static func make(appContext: AppContext, userAccount: UserAccount, completion: @escaping (AppUserContext) -> Void) {
        let result = AppUserContext(appContext: appContext, userAccount: userAccount)
        _ = result.syncManager
        CoreDataStack.make(url: result.coreDataUrl) {
            result.coreDataStack = $0
            result.metadataSyncManager.fetchMetadata(forObject: "Lead", mode: .cacheFirst) {
                result.sfMetadata = $0.forceUnwrap("Cannot load SF metadata")
                DispatchQueue.main.async {
                    Result {
                        try result.pseudoSmartStore.addExternalSoup(result.externalSoup, name: soupName)
                    }.forceUnwrap("Unable to add an external soup")
                    completion(result)
                }
            }
        }
    }

    lazy var playground = SyncDownPlayground(syncDownName: Self.syncDownName,
                                             syncUpName: Self.syncUpName,
                                             soupName: Self.soupName,
                                             entity: entity,
                                             context: coreDataStack.persistentContainer.viewContext,
                                             loginManager: appContext.loginManager,
                                             userAccount: userAccount,
                                             syncManager: syncManager,
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
        PlaygroundView(playground: playground, leadDetailsScreenResolver: resolveLeadDetailsScreen(lead:))
    }

    func resolveLeadDetailsScreen(lead: Lead) -> AppScreen {
        LeadDetailsView(lead: lead)
    }
}
