//
//  Optional+Description.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 18.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension Optional where Wrapped: CustomStringConvertible {
    var optionalDescription: String {
        if let self = self {
            return self.description
        } else {
            return "nil"
        }
    }
}
