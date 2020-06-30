//
//  CleanGhostsService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

class CleanGhostsService: SyncService, ObservableObject {
    let syncId: SoupEntryId
    let syncName: String
    let syncManager: SyncManager
    init(sync: SyncState, syncManager: SyncManager) {
        self.syncId = NSNumber(value: sync.syncId)
        self.syncName = sync.name
        self.syncManager = syncManager
    }

    var status: SyncStatus {
        // using private APIs: there's no public way to detect the status of clean ghosts task
        if let activeTask = syncManager.activeSyncs?[syncId] as? NSObject,
            NSStringFromClass(type(of: activeTask)).contains("CleanSyncGhosts") {
            return .running
        } else {
            return .success
        }
    }

    var sync: SyncState? { syncManager.syncStatus(forId: syncId) }

    var lastStartDate: Date? {
        sync?.lastStartDate
    }

    func start() {
        // skip cleaning ghosts, if the sync is newly created
        if let sync = sync, sync.status == .new { return } //
        syncManager.cleanGhosts(named: syncName) { _ in
            self.objectWillChange.send()
        }
        self.objectWillChange.send()
    }
}
