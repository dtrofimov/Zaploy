//
//  SmartStoreProxy.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import SmartStore

@objcMembers
open class SmartStoreProxy: SimpleProxy {
    public let smartStore: SmartStore

    init(smartStore: SmartStore) {
        self.smartStore = smartStore
        super.init(target: smartStore)
    }

    private(set) var externalSoupsForNames: [String: ExternalSoup] = [:]

    enum CustomError: Error {
        case soupAlreadyExists(soupName: String)
        case unknownQuery(query: QuerySpec)
        case unsupportedMethod(selector: Selector)
    }

    func addExternalSoup(_ soup: ExternalSoup) throws {
        let name = soup.name
        guard externalSoupsForNames[name] == nil else {
            throw CustomError.soupAlreadyExists(soupName: name)
        }
        externalSoupsForNames[name] = soup
    }

    open func logError(_ message: String) {
        let message = "ERROR: \(message)"
        NSLog(message)
        #if DEBUG
        fatalError(message)
        #endif
    }

    open func logWarning(_ message: String) {
        let message = "WARNING: \(message)"
        NSLog(message)
    }

    @objc(storeName) // 156
    var name: String {
        smartStore.name
    }

    @objc(storePath) // 161
    var path: String? {
        smartStore.path
    }

    @objc(user) // 166
    var userAccount: UserAccount? {
        smartStore.userAccount
    }

    @objc(indicesForSoup:) // 285
    func indices(forSoupNamed soupName: String) -> [SoupIndex] {
        if externalSoupsForNames[soupName] != nil {
            // Used in `-buildSyncIdPredicateIfIndexed:` within `cleanGhosts` to check the presence of an optional index for `kSyncTargetSyncId` (`"__sync_id__"`).
            // Since we control `-queryWithQuerySpec:pageIndex:error:` directly, return an empty array here.
            #if VERIFY_REAL_SMART_STORE_CALLS
            let frames = Thread.callStackFrames
            if frames[2].method.contains("-[SFSyncDownTarget buildSyncIdPredicateIfIndexed:soupName:syncId:]") {
            } else {
                logError("indicesForSoup: is called with an unknown call stack.")
            }
            #endif
            return []
        } else {
            return smartStore.indices(forSoupNamed: soupName)
        }
    }

    @objc(soupExists:) // 291
    func soupExists(forName soupName: String) -> Bool {
        externalSoupsForNames[soupName] != nil ||
            smartStore.soupExists(forName: soupName)
    }

    @objc(registerSoup:withIndexSpecs:error:) // 300
    func registerSoup(withName soupName: String, withIndices indices: [SoupIndex]) throws {
        if externalSoupsForNames[soupName] != nil {
            // For external soups, isn't called from SF SDK, until we use SFSDKStoreConfig,
            // which isn't a supported way of using `ExternalSoup`.
            throw CustomError.soupAlreadyExists(soupName: soupName)
        } else {
            try smartStore.registerSoup(withName: soupName, withIndices: indices)
        }
    }

    @objc(queryWithQuerySpec:pageIndex:error:) // 341
    func query(using querySpec: QuerySpec, startingFromPageIndex startPageIndex: UInt) throws -> [Any] {
        let soupName = try querySpec.safeSoupName()
        if let externalSoup = externalSoupsForNames[soupName] {
            // Used in `-getNonDirtyRecordIds:soupName:idField:additionalPredicate:`, `-getIdsWithQuery:syncManager:` within `cleanGhosts`
            // to fetch all non-dirty records of the given soup (those which we can remove wihin Clean Ghosts procedure).
            guard querySpec.smartSql == "SELECT {\(soupName):Id} FROM {\(soupName)} WHERE {\(soupName):__local__} = '0'  ORDER BY {\(soupName):Id} ASC" else {
                logError("queryWithQuerySpec:pageIndex:error: is called with an unknown query: \(querySpec.smartSql)")
                throw CustomError.unknownQuery(query: querySpec)
            }
            #if VERIFY_REAL_SMART_STORE_CALLS
            let frames = Thread.callStackFrames
            if frames[2].method.contains("-[SFSyncTarget getIdsWithQuery:syncManager:]") {
            } else {
                logWarning("queryWithQuerySpec:pageIndex:error: is called with an unknown call stack.")
            }
            #endif
            // The pagination is not actually used in `-getIdsWithQuery:syncManager:`, all the pages are concatenated immediately.
            // That's why we don't use pagination in `ExternalSoup` interface, we request all the ids at once.
            if startPageIndex == 0 {
                return externalSoup.nonDirtySfIds.map { [$0] }
            } else {
                return []
            }
        } else {
            return try smartStore.query(using: querySpec, startingFromPageIndex: startPageIndex)
        }
    }

    @objc(retrieveEntries:fromSoup:) // 377
    func retrieve(usingSoupEntryIds soupEntryIds: [NSNumber], fromSoupNamed soupName: String) -> [[AnyHashable: Any]] {
        if let externalSoup = externalSoupsForNames[soupName] {
            // Not called for external soups within syncdown, only for syncup.
            logWarning("retrieveEntries:fromSoup: is called. SyncUp test cases are not fully supported.")
            return externalSoup.entries(soupEntryIds: soupEntryIds)
        } else {
            return smartStore.retrieve(usingSoupEntryIds: soupEntryIds, fromSoupNamed: soupName)
        }
    }

    @objc(upsertEntries:toSoup:) // 389
    func upsert(entries: [[AnyHashable : Any]], forSoupNamed soupName: String) -> [[AnyHashable: Any]] {
        if let externalSoup = externalSoupsForNames[soupName] {
            // For external soups, called with empty `entries` only.
            if !entries.isEmpty {
                logWarning("upsertEntries:toSoup: is called with a non-empty entry list.")
            }
            #if VERIFY_REAL_SMART_STORE_CALLS
            #endif
            try? externalSoup.upsert(entries: entries)
            return entries
        } else {
            return smartStore.upsert(entries: entries, forSoupNamed: soupName)
        }
    }

    @objc(upsertEntries:toSoup:withExternalIdPath:error:) // 402
    func upsert(entries: [Any], forSoupNamed soupName: String, withExternalIdPath externalIdPath: String) throws -> [Any] {
        if let externalSoup = externalSoupsForNames[soupName] {
            // Used for external soups to upsert the downloaded objects by Id.
            try externalSoup.upsert(entries: entries as! [SoupEntry])
            return entries
        } else {
            return try smartStore.upsert(entries: entries, forSoupNamed: soupName, withExternalIdPath: externalIdPath)
        }
    }

    @objc(lookupSoupEntryIdForSoupName:forFieldPath:fieldValue:error:) // 413
    func lookupSoupEntryId(soupNamed soupName: String, fieldPath: String, fieldValue: String) throws -> NSNumber {
        if externalSoupsForNames[soupName] != nil {
            // Not used for external soups.
            logError("lookupSoupEntryIdForSoupName:forFieldPath:fieldValue:error: is called, which is unsupported.")
            throw CustomError.unsupportedMethod(selector: #selector(SmartStore.lookupSoupEntryId(soupNamed:fieldPath:fieldValue:)))
        } else {
            return try smartStore.lookupSoupEntryId(soupNamed: soupName, fieldPath: fieldPath, fieldValue: fieldValue)
        }
    }

    @objc(removeEntries:fromSoup:) // 434
    func removeEntries(_ entryIds: [NSNumber], fromSoup soupName: String) {
        if let externalSoup = externalSoupsForNames[soupName] {
            // Not called for external soups within syncdown, only for syncup.
            logWarning("removeEntries:fromSoup: is called. SyncUp test cases are not fully supported.")
            externalSoup.remove(soupEntryIds: entryIds)
        } else {
            try? smartStore.remove(entryIds: entryIds, forSoupNamed: soupName)
        }
    }

    @objc(removeEntriesByQuery:fromSoup:) // 454
    func removeEntries(byQuery querySpec: QuerySpec, fromSoup soupName: String) {
        if let externalSoup = externalSoupsForNames[soupName] {
            // For external soups, called within `cleanGhosts` to remove the unneeded records by a list of `SfId`s.
            var string = querySpec.smartSql
            guard string.removePrefix("SELECT {\(soupName):_soupEntryId} FROM {\(soupName)} WHERE {\(soupName):Id} IN "),
                string.removePrefix("("),
                string.removeSuffix(")")
                else {
                    logError("removeEntriesByQuery:fromSoup: is called with an unknown query.")
                    return
            }
            let ids: [SfId] = string
                .split(separator: ",")
                .compactMap {
                    var string = $0.trimmingCharacters(in: .whitespaces)
                    guard string.removePrefix("'"),
                        string.removeSuffix("'")
                        else {
                            logError("removeEntriesByQuery:fromSoup: is called with an unknown query.")
                            return nil
                    }
                    return string
            }
            externalSoup.remove(sfIds: ids)
        } else {
            try? smartStore.removeEntries(usingQuerySpec: querySpec, forSoupNamed: soupName)
        }
    }

    open override func willForwardSelector(_ selector: Selector) {
        super.willForwardSelector(selector)
        logError("Unknown method \(NSStringFromSelector(selector)) is called")
    }
}

private extension QuerySpec {
    var parsedSoupName: String? {
        var string = smartSql
        guard string.removePrefix("SELECT {") || string.removePrefix("select {") else { return nil }
        guard let soupNameSubstring = string.split(separator: ":").first else { return nil }
        return String(soupNameSubstring)
    }

    func safeSoupName() throws -> String {
        if !soupName.isEmpty { return soupName }
        if let result = parsedSoupName, !result.isEmpty { return result }
        throw SmartStoreProxy.CustomError.unknownQuery(query: self)
    }
}
