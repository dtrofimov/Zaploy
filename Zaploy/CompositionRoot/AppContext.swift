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
    static let leadsSoupName = "Lead"
    lazy var smartStore = SmartStore.shared(withName: SmartStore.defaultStoreName, forUserAccount: userAccount)
        .forceUnwrap("Cannot resolve shared SmartStore")
    lazy var pseudoSmartStore = PseudoSmartStore(smartStore: smartStore)
    lazy var replacedSmartStore = unsafeBitCast(pseudoSmartStore, to: SmartStore.self)
    lazy var syncManager = SyncManager.sharedInstance(store: replacedSmartStore)
        .forceUnwrap("Cannot resolve shared SyncManager")
    lazy var metadataSyncManager = MetadataSyncManager.sharedInstance(userAccount, smartStore: replacedSmartStore.name)

    // MARK: Core Data

    lazy var coreDataUrl: URL =
        URL(fileURLWithPath: smartStore.path.forceUnwrap("SmartStore has no path"))
            .deletingLastPathComponent()
            .appendingPathComponent("coreDataStore.sqlite")
    var coreDataStack: CoreDataStack! // assigned asynchronously

    // MARK: CoreDataSoupPool

    lazy var soupAccessor = PersistentContainerCoreDataSoupAccessor(persistentContainer: coreDataStack.persistentContainer)
    lazy var warningLogger = ConsoleWarningLogger()
    lazy var soupPoolFactory = CoreDataSoupPoolFactory(model: coreDataStack.model,
                                                       persistentStore: coreDataStack.store,
                                                       metadataSyncManager: metadataSyncManager,
                                                       soupAccessor: soupAccessor,
                                                       relationshipContextResolver: { [weak self] _ in self?.soupPool },
                                                       warningLogger: warningLogger)
    lazy var upsertQueue = CoreDataSoupEntryUpsertQueueImpl(warningLogger: warningLogger)
    lazy var soupPool = CoreDataSoupPool(upsertQueue: upsertQueue)

    // MARK: Leads entity

    let leadsEntityName = "Lead"
    lazy var leadsEntity = coreDataStack.model.entitiesByName[leadsEntityName]
        .forceUnwrap("Lead entity not found")

    static func make(appContext: AppContext, userAccount: UserAccount, completion: @escaping (AppUserContext) -> Void) {
        let result = AppUserContext(appContext: appContext, userAccount: userAccount)
        _ = result.syncManager
        CoreDataStack.make(url: result.coreDataUrl) {
            result.coreDataStack = $0
            result.soupPoolFactory.make(soupRegistrator: result.register(soup:)) { soupPoolResult in
                soupPoolResult.forceUnwrap("Unable to run soupPoolFactory")
                completion(result)
            }
        }
    }

    lazy var playground = SyncDownPlayground(syncDownName: Self.syncDownName,
                                             syncUpName: Self.syncUpName,
                                             soupName: Self.leadsSoupName,
                                             entity: leadsEntity,
                                             context: coreDataStack.persistentContainer.viewContext,
                                             loginManager: appContext.loginManager,
                                             userAccount: userAccount,
                                             syncManager: syncManager,
                                             metadataSyncManager: metadataSyncManager)


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
        HomeView(reprosesScreenResolver: resolveReprosesScreen,
                 leadsScreenResolver: resolveLeadsScreen,
                 deegsScreenResolver: resolveDeegsScreen,
                 playgroundScreenResolver: resolvePlaygroundScreen)
    }

    func resolveReprosesScreen() -> AppScreen {
        let model = ReprosesViewModelImpl(moc: coreDataStack.viewContext)
        return ReprosesView(model: model)
    }

    func resolveLeadsScreen() -> AppScreen {
        let model = LeadsViewModelImpl(moc: coreDataStack.viewContext)
        return LeadsView(model: model)
    }

    func resolveDeegsScreen() -> AppScreen {
        DeegsView()
    }

    func resolvePlaygroundScreen() -> AppScreen {
        PlaygroundView(playground: playground, leadDetailsScreenResolver: resolveLeadDetailsScreen(lead:))
    }

    func resolveLeadDetailsScreen(lead: Lead) -> AppScreen {
        LeadDetailsView(lead: lead)
    }

    func register(soup: CoreDataSoup) {
        Result { try pseudoSmartStore.addExternalSoup(soup, name: soup.metadata.soupName) }
            .forceUnwrap("Cannot add soup: \(soup.metadata)")
        soupPool.register(soup: soup)
    }
}
