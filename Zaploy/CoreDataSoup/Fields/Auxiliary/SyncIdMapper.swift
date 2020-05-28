//
//  SyncIdMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 20.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData

class SyncIdMapper: BaseFieldMapper {
    override func kvcValue(forSoupEntryValue soupEntryValue: Any) -> Any? {
        Optional(soupEntryValue)
            .checkType(warningLogger, "SyncIdMapper decoding")
            as NSNumber?
    }
}
