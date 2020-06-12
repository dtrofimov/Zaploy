//
//  SoqlSyncDownService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

class SoqlSyncDownService: SerialSyncService {
    let rawSyncDownService: RawSoqlSyncDownService
    let cleanGhostsService: CleanGhostsService

    init(syncName: String, soqlQuery: String, soupName: String, syncManager: SyncManager) {
        let rawSyncDownService = RawSoqlSyncDownService(syncName: syncName, soqlQuery: soqlQuery, soupName: soupName, syncManager: syncManager)
        let cleanGhostsService = CleanGhostsService(sync: rawSyncDownService.sync, syncManager: syncManager)
        self.rawSyncDownService = rawSyncDownService
        self.cleanGhostsService = cleanGhostsService
        super.init(childServices: [cleanGhostsService, rawSyncDownService])
    }

    convenience init(syncName: String,
                     fieldNames: [String]? = nil,
                     otherFieldNames: [String] = [],
                     filter: String? = nil,
                     soup: CoreDataSoup,
                     syncManager: SyncManager) {
        let soqlQuery = soup.soqlQuery(fieldNames: fieldNames, otherFieldNames: otherFieldNames, filter: filter)
        self.init(syncName: syncName, soqlQuery: soqlQuery, soupName: soup.metadata.soupName, syncManager: syncManager)
    }
}
