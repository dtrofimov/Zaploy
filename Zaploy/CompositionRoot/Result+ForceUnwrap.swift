//
//  Result+ForceUnwrap.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 18.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension Result {
    func forceUnwrap(_ message: String) -> Success {
        switch self {
        case let .success(success):
            return success
        case let .failure(error):
            fatalError("\(message): \(error)")
        }
    }
}
