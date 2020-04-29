//
//  Optional+ForceUnwrap.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 30.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension Optional {
    func forceUnwrap(_ message: String) -> Wrapped {
        guard let result = self else {
            fatalError(message)
        }
        return result
    }
}
