//
//  DemoExternalSoup.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import MobileSync

class DemoExternalSoup: ExternalSoup {
    let name: String

    init(name: String) {
        self.name = name
    }

    var entries: [SoupEntry] = []

    var nextSoupEntryId = 0
    var makeNextSoupEntryId: NSNumber {
        let result = nextSoupEntryId
        nextSoupEntryId += 1
        return NSNumber(value: result)
    }

    func repairSoupEntryIdIfNeeded(entry: inout SoupEntry) {
        if entry.soupEntryId != nil { return }
        entry.soupEntryId = NSNumber(value: nextSoupEntryId)
        nextSoupEntryId += 1
    }

    func nonDirtySfIds(syncSoupEntryId: SoupEntryId?) -> [SfId] {
        entries.compactMap {
            if let isLocal = $0["__local__"] as? Bool, isLocal {
                return nil
            } else {
                return $0.id
            }
        }
    }

    var dirtySoupEntryIds: [SoupEntryId] {
        entries.compactMap {
            if let isLocal = $0["__local__"] as? Bool, isLocal {
                return $0.soupEntryId
            } else {
                return nil
            }
        }
    }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry] {
        soupEntryIds.compactMap { soupEntryId in
            entries.first { $0.soupEntryId == soupEntryId }
        }
    }

    func upsert(entries entriesToUpsert: [SoupEntry]) throws {
        for entry in entriesToUpsert {
            let existingIndex: Int? = {
                if let soupEntryId = entry.soupEntryId,
                    let index = entries.firstIndex(where: { $0.soupEntryId == soupEntryId }) {
                    return index
                }
                if let id = entry.id,
                    let index = entries.firstIndex(where: { $0.id == id }) {
                    return index
                }
                return nil
            }()
            let existing = existingIndex.map { entries[$0] }
            var newEntry = entry
            if newEntry.id == nil,
                let id = existing?.id {
                newEntry.id = id
            }
            if newEntry.soupEntryId == nil,
                let soupEntryId = existing?.soupEntryId {
                newEntry.soupEntryId = soupEntryId
            }
            if let existingIndex = existingIndex {
                entries[existingIndex] = newEntry
            } else {
                newEntry.soupEntryId = makeNextSoupEntryId
                entries.append(newEntry)
            }
        }
    }

    func remove(soupEntryIds: [SoupEntryId]) {
        entries.removeAll { soupEntryIds.contains($0.soupEntryId!) }
    }

    func remove(sfIds: [SfId]) {
        entries.removeAll {
            guard let id = $0.id else { return false }
            return sfIds.contains(id)
        }
    }
}

extension SoupEntry {
    var id: SfId? {
        get { self[kId] as? SfId }
        set { self[kId] = newValue }
    }
}
