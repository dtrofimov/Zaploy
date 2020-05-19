//
//  MetadataSyncManager+LoadFromCache.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 06.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import MobileSync

extension MetadataSyncManager {
    func cachedMetadata(objectName: String) -> Metadata? {
        var result: Metadata?
        fetchMetadata(forObject: objectName, mode: .cacheOnly) { metadata in
            result = metadata
        }
        return result
    }
}
