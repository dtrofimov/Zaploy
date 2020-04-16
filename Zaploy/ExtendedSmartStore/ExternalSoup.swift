//
//  ExternalSoup.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 14.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

typealias SoupEntryId = NSNumber

typealias SfId = String

typealias SoupEntry = [AnyHashable: Any]

@objc
protocol ExternalSoup: AnyObject {
    var name: String { get }

    var nonDirtySfIds: [SfId] { get }

    func entries(soupEntryIds: [SoupEntryId]) -> [SoupEntry]

    func upsert(entries: [SoupEntry]) throws

    func remove(soupEntryIds: [SoupEntryId])

    func remove(sfIds: [SfId])
}
