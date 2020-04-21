//
//  ExternalSoup.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 14.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SmartStore

public typealias SoupEntryId = NSNumber

public typealias SfId = String

public typealias SoupEntry = [AnyHashable: Any]

@objc
public protocol ExternalSoup: AnyObject {
    @objc optional var indices: [SoupIndex] { get }

    func nonDirtySfIds(syncSoupEntryId: SoupEntryId?) -> [SfId]

    var dirtySoupEntryIds: [SoupEntryId] { get }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry]

    func upsert(entries: [SoupEntry]) throws

    func remove(soupEntryIds: [SoupEntryId])

    func remove(sfIds: [SfId])
}
