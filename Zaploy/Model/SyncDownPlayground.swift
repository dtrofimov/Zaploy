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
    lazy var smartStore = SmartStore.shared(withName: SmartStore.defaultStoreName, forUserAccount: userAccount!)!
    lazy var externalSoup = DemoExternalSoup(name: soupName)
    lazy var smartStoreProxy = SmartStoreProxy(smartStore: smartStore).then {
        try? $0.addExternalSoup(externalSoup)
    }
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
    var syncStatus: String? { syncState.map { SyncState.syncStatus(toString: $0.status) } }

    private func refreshOnMainThread() {
        if Thread.isMainThread {
            objectWillChange.send()
        } else {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func upsertLocalRecord() {
        try? externalSoup.upsert(entries: [[
            "Name": "John Local",
            "__local__": true,
            "__locally_created__": true,
            "__locally_updated__": true,
            ]])
        refreshOnMainThread()
    }

    func upsertNonLocalRecord() {
        try? externalSoup.upsert(entries: [[
            "Name": "Jane Non-Local",
            "Id": "ausyg6d7i6qt7e6g",
            ]])
        refreshOnMainThread()
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

    var leadDicts: [SoupEntry] {
        externalSoup.entries
    }
}
