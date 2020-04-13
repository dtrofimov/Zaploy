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

    func isTargetSoupName(_ soupName: String) -> Bool {
        switch soupName {
        case "sfdcMetadata", "sfdcLayouts", "syncs_soup":
            return true
        default:
            return false
        }
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
        return smartStore.indices(forSoupNamed: soupName)
    }

    @objc(soupExists:) // 291
    func soupExists(forName soupName: String) -> Bool {
        // Used for both target and extended soups. Support both.
        return smartStore.soupExists(forName: soupName)
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
        try smartStore.registerSoup(withName: soupName, withIndices: indices)
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
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if isTargetSoupName(querySpec.soupName) {
        } else if frames[2].method.contains("-[SFSyncTarget getIdsWithQuery:syncManager:]"),
            frames[3].method.contains("-[SFSyncDownTarget getNonDirtyRecordIds:soupName:idField:additionalPredicate:]"),
            querySpec.smartSql == "SELECT {someSoupName:Id} FROM {someSoupName} WHERE {someSoupName:__local__} = '0'  ORDER BY {someSoupName:Id} ASC" {
        } else {
            fatalError()
        }
        #endif
        return try smartStore.query(using: querySpec, startingFromPageIndex: startPageIndex)
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
        return smartStore.retrieve(usingSoupEntryIds: soupEntryIds, fromSoupNamed: soupName)
    }

    @objc(upsertEntries:toSoup:) // 389
    func upsert(entries: [[AnyHashable : Any]], forSoupNamed soupName: String) -> [[AnyHashable: Any]] {
        // Used for both target and extended soups. Upserts by soupEntryId (if present in the given entry).
        smartStore.upsert(entries: entries, forSoupNamed: soupName)
    }

    @objc(upsertEntries:toSoup:withExternalIdPath:error:) // 402
    func upsert(entries: [Any], forSoupNamed soupName: String, withExternalIdPath externalIdPath: String) throws -> [Any] {
        // Used for extended soups to upsert the downloaded objects by Id.
        // Presumably may be called for target soups.
        try smartStore.upsert(entries: entries, forSoupNamed: soupName, withExternalIdPath: externalIdPath)
    }

    @objc(lookupSoupEntryIdForSoupName:forFieldPath:fieldValue:error:) // 413
    func lookupSoupEntryId(soupNamed soupName: String, fieldPath: String, fieldValue: String) throws -> NSNumber {
        // Used for target soups.
        // Presumably may be called for extended soups.
        #if VERIFY_REAL_SMART_STORE_CALLS
        if isTargetSoupName(soupName) {
        } else { fatalError() }
        #endif
        return try smartStore.lookupSoupEntryId(soupNamed: soupName, fieldPath: fieldPath, fieldValue: fieldValue)
    }

    @objc(removeEntries:fromSoup:) // 434
    func removeEntries(_ entryIds: [NSNumber], fromSoup soupName: String) {
        // Used for target soups.
        // Presumably may be called for extended soups.
        #if VERIFY_REAL_SMART_STORE_CALLS
        if isTargetSoupName(soupName) {
        } else { fatalError() }
        #endif
        try? smartStore.remove(entryIds: entryIds, forSoupNamed: soupName)
    }
}
