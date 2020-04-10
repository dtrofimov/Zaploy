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

    @objc(storeName) // 156
    var name: String {
        // Used in `+sharedInstanceForStore:` only to identify store within a user, org, and community. Using `defaultStore` is OK.
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[3].method.contains("+[SFMobileSyncSyncManager sharedInstanceForStore:]") {
        } else {
            fatalError()
        }
        #endif
        return smartStore.name
    }

    @objc(storePath) // 161
    var path: String? {
        // Used in `+sharedInstanceForStore:` only for some safety check. Must be non-nil.
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[2].method.contains("+[SFMobileSyncSyncManager sharedInstanceForStore:]") {
        } else {
            fatalError()
        }
        #endif
        return smartStore.path
    }

    @objc(user) // 166
    var userAccount: UserAccount? {
        // Used in `+sharedInstanceForStore:` only to identify the current user.
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[2].method.contains("+[SFMobileSyncSyncManager sharedInstanceForStore:]") ||
            frames[3].method.contains("+[SFMobileSyncSyncManager sharedInstanceForStore:]") {
        } else {
            fatalError()
        }
        #endif
        return smartStore.userAccount
    }

    @objc(indicesForSoup:) // 285
    func indices(forSoupNamed soupName: String) -> [SoupIndex] {
        /*
         1. Used in `-buildSyncIdPredicateIfIndexed:` within `cleanGhosts` to check the presence of an optional index for `kSyncTargetSyncId` (`"__sync_id__"`).
         Since we control `-queryWithQuerySpec:pageIndex:error:` directly, return an empty array here.

         2. Used in `+setupSyncsSoupIfNeeded:` to check whether `kSFSyncStateSyncsSoupName` soup exists and has exactly three indices.
         To pretend we already have the soup configured, return these indices:

         ```
         [
             SoupIndex(path: kSFSyncStateSyncsSoupSyncType, indexType: kSoupIndexTypeJSON1, columnName: nil),
             SoupIndex(path: "name", indexType: kSoupIndexTypeJSON1, columnName: nil),
             SoupIndex(path: kSFSyncStateStatus, indexType: kSoupIndexTypeJSON1, columnName: nil),
         ]
         ```
         */
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[2].method.contains("-[SFSyncDownTarget buildSyncIdPredicateIfIndexed:soupName:syncId:]"),
            soupName == "someSoupName" {
        } else if frames[2].method.contains("+[SFSyncState setupSyncsSoupIfNeeded:]"),
            soupName == kSFSyncStateSyncsSoupName {
        } else {
            fatalError()
        }
        #endif
        return smartStore.indices(forSoupNamed: soupName)
    }

    @objc(soupExists:) // 291
    func soupExists(forName soupName: String) -> Bool {
        // Used in `+setupSyncsSoupIfNeeded:` to check whether `kSFSyncStateSyncsSoupName` soup exists and has exactly three indices.
        // To pretend we already have the soup configured, return `true`.
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[2].method.contains("+[SFSyncState setupSyncsSoupIfNeeded:]"),
            soupName == kSFSyncStateSyncsSoupName {
        } else {
            fatalError()
        }
        #endif
        return smartStore.soupExists(forName: soupName)
    }

    @objc(registerSoup:withIndexSpecs:error:) // 300
    func registerSoup(withName soupName: String, withIndices indices: [SoupIndex]) throws {
        // Used in `+setupSyncsSoupIfNeeded:` to register `kSFSyncStateSyncsSoupName` soup if not already.
        // Presumable not needed to override, if we override `soupExists` correctly.
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[2].method.contains("+[SFSyncState setupSyncsSoupIfNeeded:]"),
            soupName == kSFSyncStateSyncsSoupName {
        } else {
            fatalError()
        }
        #endif
        try smartStore.registerSoup(withName: soupName, withIndices: indices)
    }

    @objc(queryWithQuerySpec:pageIndex:error:) // 341
    func query(using querySpec: QuerySpec, startingFromPageIndex startPageIndex: UInt) throws -> [Any] {
        /*
         1. Used in `+cleanupSyncsSoupIfNeeded:`, `+getSyncsWithStatus:status:` with the following SmartSQL query:

         ```
         select {syncs_soup:_soup} from {syncs_soup} where {syncs_soup:status} = 'RUNNING'
         ```

         That's a part of a procedure that finds all running syncs and moves them to `"STOPPED"` status (`SFSyncStateStatusStopped`).
         We should perform this procedure manually on SmartStore initialization. In this method, return an empty array.

         2. Used in `-getNonDirtyRecordIds:soupName:idField:additionalPredicate:`, `-getIdsWithQuery:syncManager:` within `cleanGhosts`
         to fetch all non-dirty records of the given soup (those which we can remove wihin Clean Ghosts procedure).

         ```
         SELECT {someSoupName:Id} FROM {someSoupName} WHERE {someSoupName:__local__} = '0'  ORDER BY {someSoupName:Id} ASC
         ```

         Return the actual result here (the list of non-dirty record ids within a given table).
         */
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[2].method.contains("+[SFSyncState getSyncsWithStatus:status:]"),
            frames[3].method.contains("+[SFSyncState cleanupSyncsSoupIfNeeded:]"),
            querySpec.smartSql == "select {syncs_soup:_soup} from {syncs_soup} where {syncs_soup:status} = 'RUNNING'" {
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
        /*
         Used in `SFSyncState +byName:store:` in several places to dereference SFSyncState by a soupEntryId (with `kSFSyncStateSyncsSoupName` soup). Return the actual result here.
         */
        #if VERIFY_REAL_SMART_STORE_CALLS
        let frames = Thread.callStackFrames
        if frames[3].method.contains("+[SFSyncState byName:store:]"),
            soupEntryIds.count == 1,
            soupName == kSFSyncStateSyncsSoupName {
        } else {
            fatalError()
        }
        #endif
        return smartStore.retrieve(usingSoupEntryIds: soupEntryIds, fromSoupNamed: soupName)
    }

    @objc(upsertEntries:toSoup:) // 389
    func upsert(entries: [[AnyHashable : Any]], forSoupNamed soupName: String) -> [[AnyHashable: Any]] {
        /*
         Perform the upsert and return the entries as they are inserted to the database.
         Probably, the system also relies on SOUP_ENTRY_ID and SOUP_LAST_MODIFIED_DATE fields which are re-written when the entry is saved.

         1. Used in `+newSyncDownWithOptions:target:soupName:name:store:` to upsert a new SFSyncState.

         2. Used in `SFSyncTarget -saveInSmartStore:soupName:records:idFieldName:syncId:lastError:cleanFirst:` to upsert the downloaded objects. ???

         3. Used in `SFSyncState -save:` to save SFSyncState.
         */
        smartStore.upsert(entries: entries, forSoupNamed: soupName)
    }

    @objc(upsertEntries:toSoup:withExternalIdPath:error:) // 402
    func upsert(entries: [Any], forSoupNamed soupName: String, withExternalIdPath externalIdPath: String) throws -> [Any] {
        // Used in `SFSyncTarget -saveInSmartStore:soupName:records:idFieldName:syncId:lastError:cleanFirst:` to upsert the downloaded objects.
        try smartStore.upsert(entries: entries, forSoupNamed: soupName, withExternalIdPath: externalIdPath)
    }

    @objc(lookupSoupEntryIdForSoupName:forFieldPath:fieldValue:error:) // 413
    func lookupSoupEntryId(soupNamed soupName: String, fieldPath: String, fieldValue: String) throws -> NSNumber {
        // 1. Used in `SFSyncState +byName:store:` to find SFSyncState soupEntryId by its name.
        // 2. Used in `SFSyncState +deleteByName:store:` to find SFSyncState soupEntryId by its name.
        #if VERIFY_REAL_SMART_STORE_CALLS
        guard soupName == kSFSyncStateSyncsSoupName,
            fieldPath == "name"
            else { fatalError() }
        #endif
        return try smartStore.lookupSoupEntryId(soupNamed: soupName, fieldPath: fieldPath, fieldValue: fieldValue)
    }

    @objc(removeEntries:fromSoup:) // 434
    func removeEntries(_ entryIds: [NSNumber], fromSoup soupName: String) {
        // Used in `SFSyncState +deleteById:store:` to remove a SFSyncState by its soupEntryId.
        #if VERIFY_REAL_SMART_STORE_CALLS
        guard soupName == kSFSyncStateSyncsSoupName,
        entryIds.count == 1
            else { fatalError() }
        #endif
        try? smartStore.remove(entryIds: entryIds, forSoupNamed: soupName)
    }
}
