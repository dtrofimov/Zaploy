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
import PseudoSmartStore

class SyncDownPlayground: ObservableObject {
    let syncDownName: String
    let syncUpName: String
    let soupName: String
    let userAccount: UserAccount
    let syncManager: SyncManager
    let externalSoup: DemoExternalSoup
    let metadataSyncManager: MetadataSyncManager
    let layoutSyncManager: LayoutSyncManager

    init(syncDownName: String, syncUpName: String, soupName: String, userAccount: UserAccount, syncManager: SyncManager, externalSoup: DemoExternalSoup, metadataSyncManager: MetadataSyncManager, layoutSyncManager: LayoutSyncManager) {
        self.syncDownName = syncDownName
        self.syncUpName = syncUpName
        self.soupName = soupName
        self.userAccount = userAccount
        self.syncManager = syncManager
        self.externalSoup = externalSoup
        self.metadataSyncManager = metadataSyncManager
        self.layoutSyncManager = layoutSyncManager
    }

    var syncDownState: SyncState? { syncManager.syncStatus(forName: syncDownName) }
    var syncDownStatus: String? { syncDownState.map { SyncState.syncStatus(toString: $0.status) } }

    var syncUpState: SyncState? { syncManager.syncStatus(forName: syncUpName) }
    var syncUpStatus: String? { syncUpState.map { SyncState.syncStatus(toString: $0.status) } }

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
            "attributes": ["type": "Lead"],
            "FirstName": "John",
            "LastName": "Local",
            "Company": "Big Company, inc",
            "__local__": true,
            "__locally_created__": true,
            "__locally_updated__": true,
            ]])
        refreshOnMainThread()
    }

    func upsertNonLocalRecord() {
        try? externalSoup.upsert(entries: [
            [
                "attributes": ["type": "Lead"],
                "Id": "ausyg6d7i6qt7e6g",
                "FirstName": "Jane",
                "LastName": "Non-Local",
            ],
            [
                "attributes": ["type": "Lead"],
                "Id": "aiusytd78q8w67t",
                "FirstName": "David",
                "LastName": "Non-Local",
            ],
        ])
        refreshOnMainThread()
    }

    func syncDown() {
        syncManager.deleteSync(forName: syncDownName)
        try! syncManager.syncDown(target: SoqlSyncDownTarget.newSyncTarget("select Id, FirstName, LastName, Company from Lead"),
                                  options: SyncOptions.newSyncOptions(forSyncDown: .overwrite),
                                  soupName: soupName,
                                  syncName: syncDownName) { [weak self] syncState in
                                    self?.refreshOnMainThread()
        }
        refreshOnMainThread()
    }

    func resyncDown() {
        try! syncManager.reSync(named: syncDownName, onUpdate: { [weak self] syncState in
            self?.refreshOnMainThread()
        })
        refreshOnMainThread()
    }

    func cleanGhosts() {
        syncManager.cleanGhosts(named: syncDownName, { [weak self] result in
            self?.refreshOnMainThread()
        })
        refreshOnMainThread()
    }

    func deleteSyncDown() {
        syncManager.deleteSync(forName: syncDownName)
        refreshOnMainThread()
    }

    func syncUp() {
        syncManager.deleteSync(forName: syncUpName)
        try! syncManager.syncUp(target: SyncUpTarget(createFieldlist: nil, updateFieldlist: nil),
                                options: SyncOptions.newSyncOptions(forSyncUp: ["Id", "FirstName", "LastName", "Company"], mergeMode: .overwrite),
                                soupName: soupName,
                                syncName: syncUpName,
                                onUpdate: { [weak self] syncState in
                                    self?.refreshOnMainThread()
        })
        refreshOnMainThread()
    }

    func resyncUp() {
        try! syncManager.reSync(named: syncUpName) { [weak self] syncState in
            self?.refreshOnMainThread()
        }
        refreshOnMainThread()
    }

    func deleteSyncUp() {
        syncManager.deleteSync(forName: syncUpName)
        refreshOnMainThread()
    }

    func markFirstAsDeleted() {
        guard !externalSoup.entries.isEmpty else { return }
        externalSoup.entries[0].update {
            $0["__local__"] = NSNumber(value: true)
            $0["__locally_deleted__"] = NSNumber(value: true)
        }
        refreshOnMainThread()
    }

    func modifyFirst() {
        guard !externalSoup.entries.isEmpty else { return }
        externalSoup.entries[0].update {
            $0["FirstName"] = $0["FirstName"] as! String + "1"
            $0["__local__"] = NSNumber(value: true)
            $0["__locally_updated__"] = NSNumber(value: true)
        }
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
