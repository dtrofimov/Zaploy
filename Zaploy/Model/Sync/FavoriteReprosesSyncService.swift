//
//  FavoriteReprosesSyncService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

class FavoriteReprosesSyncService: SerialSyncService {
    let reprosesService: SoqlSyncDownService

    init(soups: Soups, syncManager: SyncManager) {
        let reprosesService = SoqlSyncDownService(syncName: "FavoriteReproses_reproses",
                                                    otherFieldNames: soups.deeg.fieldNamesForSoql.map { "Deeg__r.\($0)" } +
                                                        [soups.lead.soqlQuery(from: "Leads__r").inBrackets],
                                                    filter: "IsFavorite__c = true",
                                                    soup: soups.reprose,
                                                    syncManager: syncManager)
        self.reprosesService = reprosesService
        super.init(childServices: [reprosesService])
    }
}
