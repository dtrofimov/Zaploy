//
//  NSDictionary+SmartStoreEntry.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 14.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import SmartStore

extension SoupEntry {
    var soupEntryId: SoupEntryId? {
        get { self[SmartStore.soupEntryId] as? NSNumber }
        set { self[SmartStore.soupEntryId] = newValue }
    }
}
