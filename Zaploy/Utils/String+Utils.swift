//
//  String+Utils.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension String {
    var inQuotes: String {
        return "'\(self)'"
    }

    var inBrackets: String {
        return "(\(self))"
    }
}
