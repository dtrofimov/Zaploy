//
//  Array+RemoveAndReturn.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 01.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension RangeReplaceableCollection {
    public mutating func removeAllAndReturn(where shouldBeRemoved: (Element) throws -> Bool) rethrows -> [Element] {
        var removed: [Element] = []
        try removeAll {
            if try shouldBeRemoved($0) {
                removed.append($0)
                return true
            } else {
                return false
            }
        }
        return removed
    }
}
