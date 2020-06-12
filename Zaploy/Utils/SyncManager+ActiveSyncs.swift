//
//  SyncManager+ActiveSyncs.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

extension SyncManager {
    var activeSyncs: NSDictionary? {
        value(forKey: "activeSyncs") as? NSDictionary
    }
}
