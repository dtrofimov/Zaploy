//
//  String+SafeRemove.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 16.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension String {
    mutating func removePrefix(_ prefix: String) -> Bool {
        guard hasPrefix(prefix) else { return false }
        removeFirst(prefix.count)
        return true
    }

    mutating func removeSuffix(_ suffix: String) -> Bool {
        guard hasSuffix(suffix) else { return false }
        removeLast(suffix.count)
        return true
    }
}
