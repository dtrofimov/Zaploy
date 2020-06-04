//
//  NSDictionary+SmartStoreEntry.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 14.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import MobileSync
import SmartStore

public extension SoupEntry {
    var soupEntryId: SoupEntryId? {
        get { self[SmartStore.soupEntryId] as? NSNumber }
        set { self[SmartStore.soupEntryId] = newValue }
    }

    var sfId: SfId? {
        get { self[kId] as? SfId }
        set { self[kId] = newValue }
    }

    var sfTypeAttribute: String? {
        get {
            (self[kAttributesKey] as? [AnyHashable: Any])?["type"] as? String
        }
        set {
            self[kAttributesKey] = (self[kAttributesKey] as? [AnyHashable: Any] ?? [:]).with {
                $0["type"] = newValue
            }
        }
    }

    var asJson: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var asPrettyJson: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
