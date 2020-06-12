//
//  RawSoqlSyncDownService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

class RawSoqlSyncDownService: SyncService, ObservableObject {
    let syncName: String
    let soqlQuery: String
    let soupName: String
    let syncManager: SyncManager

    init(syncName: String, soqlQuery: String, soupName: String, syncManager: SyncManager) {
        self.syncName = syncName
        self.soqlQuery = soqlQuery
        self.soupName = soupName
        self.syncManager = syncManager
    }

    func resolveSync() -> SyncState {
        if let sync = syncManager.syncStatus(forName: syncName) {
            return sync
        }
        let target = SoqlSyncDownTarget.newSyncTarget(soqlQuery)
        return syncManager.createSyncDown(target,
                                          options: .newSyncOptions(forSyncDown: .overwrite),
                                          soupName: soupName,
                                          syncName: syncName)
    }

    lazy var syncId = NSNumber(value: resolveSync().syncId)

    var sync: SyncState {
        syncManager.syncStatus(forId: syncId) ?? resolveSync()
    }

    enum CustomError: Error {
        case stopped
        case syncStateError(String)
        case unknownState
    }

    var status: SyncStatus {
        switch sync.status {
        case .new:
            return .new
        case .stopped:
            return .failure(CustomError.stopped)
        case .running:
            return .running
        case .done:
            return .success
        case .failed:
            return .failure(CustomError.syncStateError(sync.error))
        @unknown default:
            return .failure(CustomError.unknownState)
        }
    }

    var lastStartDate: Date? { sync.lastStartDate }

    func start() {
        syncManager.cleanGhosts(named: syncName) { _ in
            self.objectWillChange.send()
        }
        self.objectWillChange.send()
    }
}

extension SyncState {
    var lastStartDate: Date? {
        let milliseconds = startTime
        guard milliseconds != 0 else { return nil }
        return Date(timeIntervalSince1970: Double(milliseconds) * 0.001)
    }
}
