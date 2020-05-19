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
import CoreData

class SyncDownPlayground: ObservableObject {
    let syncDownName: String
    let syncUpName: String
    let soupName: String
    let entity: NSEntityDescription
    let context: NSManagedObjectContext
    let loginManager: LoginManager
    let userAccount: UserAccount
    let syncManager: SyncManager
    let metadataSyncManager: MetadataSyncManager
    let layoutSyncManager: LayoutSyncManager

    init(syncDownName: String, syncUpName: String, soupName: String, entity: NSEntityDescription, context: NSManagedObjectContext, loginManager: LoginManager, userAccount: UserAccount, syncManager: SyncManager, metadataSyncManager: MetadataSyncManager, layoutSyncManager: LayoutSyncManager) {
        self.syncDownName = syncDownName
        self.syncUpName = syncUpName
        self.soupName = soupName
        self.entity = entity
        self.context = context
        self.loginManager = loginManager
        self.userAccount = userAccount
        self.syncManager = syncManager
        self.metadataSyncManager = metadataSyncManager
        self.layoutSyncManager = layoutSyncManager
    }

    func logout() {
        loginManager.logout()
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
        // TODO: Raise __local__, __locally_created__, __locally_updated__ flags
//        ManagedLead(context: context).do {
//            $0.firstName = "John"
//            $0.lastName = "Local"
//            $0.company = "Big Company, inc"
//        }
//        try! context.save()
//        refreshOnMainThread()
    }

    func upsertNonLocalRecord() {
        ManagedLead.findOrCreate(byId: "ausyg6d7i6qt7e6g", in: context).do {
            $0.firstName = "Jane"
            $0.lastName = "Non-Local"
            $0.company = "Little Company, inc"
        }
        ManagedLead.findOrCreate(byId: "aiusytd78q8w67t", in: context).do {
            $0.firstName = "David"
            $0.lastName = "Non-Local"
            $0.company = "Small Company, inc"
        }
        try! context.save()
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
//        guard !externalSoup.entries.isEmpty else { return }
//        externalSoup.entries[0].update {
//            $0["__local__"] = NSNumber(value: true)
//            $0["__locally_deleted__"] = NSNumber(value: true)
//        }
//        refreshOnMainThread()
    }

    func modifyFirst() {
//        guard !externalSoup.entries.isEmpty else { return }
//        externalSoup.entries[0].update {
//            $0["FirstName"] = $0["FirstName"] as! String + "1"
//            $0["__local__"] = NSNumber(value: true)
//            $0["__locally_updated__"] = NSNumber(value: true)
//        }
//        refreshOnMainThread()
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

    var leads: [Lead] {
        let request = ManagedLead.safeFetchRequest
        request.sortDescriptors = [.init(key: "firstName", ascending: true)]
        return try! context.fetch(request)
    }
}
