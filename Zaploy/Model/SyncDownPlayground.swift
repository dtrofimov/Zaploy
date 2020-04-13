//
//  SyncDownPlayground.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import MobileSync
import Then

class SyncDownPlayground: ObservableObject {
    static let shared = SyncDownPlayground()

    var userAccount: UserAccount? { UserAccountManager.shared.currentUserAccount }
    lazy var smartStore = SmartStore.shared(withName: SmartStore.defaultStoreName, forUserAccount: userAccount!)!.then {
        if !$0.soupExists(forName: soupName) {
            try! $0.registerSoup(withName: soupName, withIndices: [
                SoupIndex(path: "Id", indexType: "string", columnName: nil)!,
                SoupIndex(path: "__local__", indexType: "integer", columnName: nil)!,
            ])
        }
    }
    lazy var smartStoreProxy = SmartStoreProxy(target: smartStore)
    lazy var proxiedSmartStore = unsafeBitCast(smartStoreProxy, to: SmartStore.self)
    lazy var syncManager = SyncManager.sharedInstance(store: proxiedSmartStore)!
    lazy var metadataSyncManager = MetadataSyncManager.sharedInstance(userAccount!, smartStore: proxiedSmartStore.name)
    lazy var layoutSyncManager = LayoutSyncManager.sharedInstance(userAccount!, smartStore: proxiedSmartStore.name)

    let syncName = "someSyncName"
    let soupName = "someSoupName"

    var syncState: SyncState? {
        guard userAccount != nil else { return nil }
        return syncManager.syncStatus(forName: syncName)
    }

    private func refreshOnMainThread() {
        if Thread.isMainThread {
            objectWillChange.send()
        } else {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func syncDown() {
        syncManager.deleteSync(forName: syncName)
        try! syncManager.syncDown(target: SoqlSyncDownTarget.newSyncTarget("select Id, Name from Lead"),
                                  options: SyncOptions.newSyncOptions(forSyncDown: .overwrite),
                                  soupName: soupName,
                                  syncName: syncName) { [weak self] syncState in
                                    self?.refreshOnMainThread()
        }
        refreshOnMainThread()
    }

    func resync() {
        try! syncManager.reSync(named: syncName, onUpdate: { [weak self] syncState in
            self?.refreshOnMainThread()
        })
        refreshOnMainThread()
    }

    func cleanGhosts() {
        syncManager.cleanGhosts(named: syncName, { [weak self] result in
            self?.refreshOnMainThread()
        })
        refreshOnMainThread()
    }

    func deleteSync() {
        syncManager.deleteSync(forName: syncName)
        refreshOnMainThread()
    }

    func syncDownMetadata() {
        metadataSyncManager.fetchMetadata(forObject: "Lead", mode: .serverFirst) { [weak self] metadata in
            self?.refreshOnMainThread()
        }
        refreshOnMainThread()
    }

    func loadMetadataFromCache() {
        metadataSyncManager.fetchMetadata(forObject: "Lead", mode: .cacheOnly) { [weak self] metadata in
            self?.refreshOnMainThread()
        }
        refreshOnMainThread()
    }

    func syncDownLayout() {
        layoutSyncManager.fetchLayout(forObject: "Lead", layoutType: nil, mode: .serverFirst) { [weak self] string, layout in
            self?.refreshOnMainThread()
        }
        refreshOnMainThread()
    }

    var leadDicts: [NSDictionary] {
        guard userAccount != nil else { return [] }
        guard smartStore.soupExists(forName: soupName) else { return [] }
        let smartSql = "select {\(soupName):_soup} from {\(soupName)}"
        let spec = QuerySpec.buildSmartQuerySpec(smartSql: smartSql, pageSize: UInt(Int.max))!
        return try! smartStore.query(using: spec, startingFromPageIndex: 0).map { ($0 as! NSArray).firstObject as! NSDictionary }
    }
}
