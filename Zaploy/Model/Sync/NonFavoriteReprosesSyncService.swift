//
//  NonFavoriteReprosesSyncService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

class NonFavoriteReprosesSyncService: SerialSyncService {
    let reprosesService: SoqlSyncDownService
    let deegsService: SoqlSyncDownService
    let leadsService: SoqlSyncDownService

    init(soups: Soups, syncManager: SyncManager) {
        let reprosesService = SoqlSyncDownService(syncName: "NonFavoriteReproses_reproses",
                                                    filter: "IsFavorite__c == false",
                                                    soup: soups.reprose,
                                                    syncManager: syncManager)
        let deegsService = SoqlSyncDownService(syncName: "NonFavoriteReproses_deegs",
                                                 filter:
            "Id in (select Deeg__c from Reprose__c where IsFavorite__c = false) and " +
            "Id not in (select Deeg__c from Reprose__c where IsFavorite__c = true)",
                                                 soup: soups.deeg,
                                                 syncManager: syncManager)
        let leadsService = SoqlSyncDownService(syncName: "NonFavoriteReproses_leads",
                                                 filter: "Reprose__c.IsFavorite__c == false",
                                                 soup: soups.lead,
                                                 syncManager: syncManager)
        self.reprosesService = reprosesService
        self.deegsService = deegsService
        self.leadsService = leadsService
        super.init(childServices: [reprosesService, deegsService, leadsService])
    }
}
