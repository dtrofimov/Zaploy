//
//  Set+OrderedByHash.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 05.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension Set {
    var sortedByHash: [Element] {
        sorted {
            $0.hashValue < $1.hashValue
        }
    }
}
