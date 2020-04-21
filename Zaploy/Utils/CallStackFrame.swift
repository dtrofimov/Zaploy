//
//  CallStackFrame.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 10.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import Then

#if VERIFY_FORWARDED_CALLERS

struct CallStackFrame {
    let module: String
    let address: Int
    let method: String
    let line: Int
}

extension String: Then {}

extension CallStackFrame {
    init(_ description: String) {
        var components = description.split(separator: " ")
            .filter { !$0.isEmpty }
            .map { String($0) }
        line = Int(components.removeLast())!
        guard components.removeLast() == "+" else { fatalError() }
        guard Int(components.removeFirst()) != nil else { fatalError() }
        module = components.removeFirst()
        address = Int(components.removeFirst().with {
            let hexPrefix = "0x"
            guard $0.hasPrefix(hexPrefix) else { fatalError() }
            $0.removeFirst(hexPrefix.count)
        }, radix: 16)!
        method = components.joined(separator: " ")
    }
}

extension Thread {
    static var callStackFrames: [CallStackFrame] {
        Thread.callStackSymbols.map { CallStackFrame($0) }.with {
            $0.removeFirst()
        }
    }
}

#endif
