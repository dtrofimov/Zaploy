//
//  SmartStoreProxy.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import SmartStore
import MobileSync

@objcMembers
class SmartStoreProxy: SimpleProxy {
    var smartStore: SmartStore { target as! SmartStore }

    init(smartStore: SmartStore) {
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

    func isTargetSoupName(_ soupName: String) -> Bool {
        externalSoupsForNames[soupName] == nil
    }

    @objc(storeName) // 156
    var name: String {
        // Don't override.
        return smartStore.name
    }

    @objc(storePath) // 161
    var path: String? {
        // Don't override.
        return smartStore.path
    }

    @objc(user) // 166
    var userAccount: UserAccount? {
        // Don't override
        return smartStore.userAccount
    }

    @objc(indicesForSoup:) // 285
    func indices(forSoupNamed soupName: String) -> [SoupIndex] {
        /*
         1. Used in `-buildSyncIdPredicateIfIndexed:` within `cleanGhosts` to check the presence of an optional index for `kSyncTargetSyncId` (`"__sync_id__"`).
         Since we control `-queryWithQuerySpec:pageIndex:error:` directly, return an empty array here.

         2. For system soups, don't override.
         */
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if isTargetSoupName(soupName) {
        } else if frames[2].method.contains("-[SFSyncDownTarget buildSyncIdPredicateIfIndexed:soupName:syncId:]"),
            soupName == "someSoupName" {
        } else {
            fatalError()
        }
        #endif
        if externalSoupsForNames[soupName] != nil {
            return []
        } else {
            return smartStore.indices(forSoupNamed: soupName)
        }
    }

    @objc(soupExists:) // 291
    func soupExists(forName soupName: String) -> Bool {
        // Used for both target and extended soups. Support both.
        externalSoupsForNames[soupName] != nil ||
            smartStore.soupExists(forName: soupName)
    }

    @objc(registerSoup:withIndexSpecs:error:) // 300
    func registerSoup(withName soupName: String, withIndices indices: [SoupIndex]) throws {
        // Used for target soups only when the corresponding managers are instantiated.
        // For extended soups, isn't called from SF SDK, until we use SFSDKStoreConfig.
        #if VERIFY_REAL_SMART_STORE_CALLS
        if isTargetSoupName(soupName) {
        } else {
            fatalError()
        }
        #endif
        if externalSoupsForNames[soupName] != nil {
            throw CustomError.soupAlreadyExists(soupName: soupName)
        } else {
            try smartStore.registerSoup(withName: soupName, withIndices: indices)
        }
    }

    @objc(queryWithQuerySpec:pageIndex:error:) // 341
    func query(using querySpec: QuerySpec, startingFromPageIndex startPageIndex: UInt) throws -> [Any] {
        /*
         1. Used in target soups in arbitrary ways.

         2. Used in `-getNonDirtyRecordIds:soupName:idField:additionalPredicate:`, `-getIdsWithQuery:syncManager:` within `cleanGhosts`
         to fetch all non-dirty records of the given soup (those which we can remove wihin Clean Ghosts procedure).

         ```
         SELECT {someSoupName:Id} FROM {someSoupName} WHERE {someSoupName:__local__} = '0'  ORDER BY {someSoupName:Id} ASC
         ```

         Return the actual result here (the list of non-dirty record ids within a given table).
         */
        let soupName = try querySpec.safeSoupName()
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if isTargetSoupName(soupName) {
        } else if frames[2].method.contains("-[SFSyncTarget getIdsWithQuery:syncManager:]"),
            frames[3].method.contains("-[SFSyncDownTarget getNonDirtyRecordIds:soupName:idField:additionalPredicate:]"),
            querySpec.smartSql == "SELECT {\(soupName):Id} FROM {\(soupName)} WHERE {\(soupName):__local__} = '0'  ORDER BY {\(soupName):Id} ASC" {
        } else {
            fatalError()
        }
        #endif
        if let externalSoup = externalSoupsForNames[soupName] {
            guard querySpec.smartSql == "SELECT {\(soupName):Id} FROM {\(soupName)} WHERE {\(soupName):__local__} = '0'  ORDER BY {\(soupName):Id} ASC" else {
                throw CustomError.unknownQuery(query: querySpec)
            }
            return externalSoup.nonDirtySfIds.map { [$0] }
        } else {
            return try smartStore.query(using: querySpec, startingFromPageIndex: startPageIndex)
        }
    }

    @objc(retrieveEntries:fromSoup:) // 377
    func retrieve(usingSoupEntryIds soupEntryIds: [NSNumber], fromSoupNamed soupName: String) -> [[AnyHashable: Any]] {
        // Used for target soups.
        // For extended soups, is presumably called within syncup.
        #if VERIFY_REAL_SMART_STORE_CALLS
        if isTargetSoupName(soupName) {
        } else {
            fatalError()
        }
        #endif
        if let externalSoup = externalSoupsForNames[soupName] {
            return externalSoup.entries(soupEntryIds: soupEntryIds)
        } else {
            return smartStore.retrieve(usingSoupEntryIds: soupEntryIds, fromSoupNamed: soupName)
        }
    }

    @objc(upsertEntries:toSoup:) // 389
    func upsert(entries: [[AnyHashable : Any]], forSoupNamed soupName: String) -> [[AnyHashable: Any]] {
        // Used for both target and extended soups. Upserts by soupEntryId (if present in the given entry).
        if let externalSoup = externalSoupsForNames[soupName] {
            try? externalSoup.upsert(entries: entries)
            return entries
        } else {
            return smartStore.upsert(entries: entries, forSoupNamed: soupName)
        }
    }

    @objc(upsertEntries:toSoup:withExternalIdPath:error:) // 402
    func upsert(entries: [Any], forSoupNamed soupName: String, withExternalIdPath externalIdPath: String) throws -> [Any] {
        // Used for extended soups to upsert the downloaded objects by Id.
        // Presumably may be called for target soups.
        if let externalSoup = externalSoupsForNames[soupName] {
            try externalSoup.upsert(entries: entries as! [SoupEntry])
            return entries
        } else {
            return try smartStore.upsert(entries: entries, forSoupNamed: soupName, withExternalIdPath: externalIdPath)
        }
    }

    @objc(lookupSoupEntryIdForSoupName:forFieldPath:fieldValue:error:) // 413
    func lookupSoupEntryId(soupNamed soupName: String, fieldPath: String, fieldValue: String) throws -> NSNumber {
        // Used for target soups.
        // Presumably may be called for extended soups.
        #if VERIFY_REAL_SMART_STORE_CALLS
        if isTargetSoupName(soupName) {
        } else { fatalError() }
        #endif
        if externalSoupsForNames[soupName] != nil {
            throw CustomError.unsupportedMethod(selector: #selector(SmartStore.lookupSoupEntryId(soupNamed:fieldPath:fieldValue:)))
        } else {
            return try smartStore.lookupSoupEntryId(soupNamed: soupName, fieldPath: fieldPath, fieldValue: fieldValue)
        }
    }

    @objc(removeEntries:fromSoup:) // 434
    func removeEntries(_ entryIds: [NSNumber], fromSoup soupName: String) {
        // Used for target soups.
        // Presumably may be called for extended soups.
        #if VERIFY_REAL_SMART_STORE_CALLS
        if isTargetSoupName(soupName) {
        } else { fatalError() }
        #endif
        if let externalSoup = externalSoupsForNames[soupName] {
            externalSoup.remove(soupEntryIds: entryIds)
        } else {
            try? smartStore.remove(entryIds: entryIds, forSoupNamed: soupName)
        }
    }

    @objc(removeEntriesByQuery:fromSoup:) // 454
    func removeEntries(byQuery querySpec: QuerySpec, fromSoup soupName: String) {
        if let externalSoup = externalSoupsForNames[soupName] {
            var string = querySpec.smartSql
            guard string.removePrefix("SELECT {\(soupName):_soupEntryId} FROM {\(soupName)} WHERE {\(soupName):Id} IN "),
                string.removePrefix("("),
                string.removeSuffix(")")
                else { return }
            let ids: [SfId] = string
                .split(separator: ",")
                .compactMap {
                    var string = $0.trimmingCharacters(in: .whitespaces)
                    guard string.removePrefix("'"),
                        string.removeSuffix("'")
                        else { return nil }
                    return string
            }
            if !ids.isEmpty {
                externalSoup.remove(sfIds: ids)
            }
        } else {
            try? smartStore.removeEntries(usingQuerySpec: querySpec, forSoupNamed: soupName)
        }
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
