//
//  ExternalSoup.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 14.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SmartStore

typealias SoupEntryId = NSNumber

typealias SfId = String

typealias SoupEntry = [AnyHashable: Any]

@objc
protocol ExternalSoup: AnyObject {
    var name: String { get }

    @objc optional var indices: [SoupIndex] { get }

    func nonDirtySfIds(syncSoupEntryId: SoupEntryId?) -> [SfId]

    var dirtySoupEntryIds: [SoupEntryId] { get }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry]

    func upsert(entries: [SoupEntry]) throws

    func remove(soupEntryIds: [SoupEntryId])

    func remove(sfIds: [SfId])
}
