//
//  Then+Update.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 20.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Then

extension Then where Self: Any {
    public mutating func update(_ block: (inout Self) throws -> Void) rethrows {
        try block(&self)
    }
}
