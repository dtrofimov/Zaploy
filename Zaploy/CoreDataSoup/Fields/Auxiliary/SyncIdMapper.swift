//
//  SyncIdMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 20.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class SyncIdMapper: BaseFieldMapper {
    override func kvcValue(forSoupEntryValue soupEntryValue: Any?) -> Any? {
        warningLogger.checkType(soupEntryValue, "SyncIdMapper decoding") as NSNumber?
    }
}
