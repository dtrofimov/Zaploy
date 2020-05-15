//
//  WarningLogger.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 13.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

protocol WarningLogger {
    func logWarning(_ message: @autoclosure () -> String, error: Error?)

    func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String)
}

extension WarningLogger {
    func logWarning(_ message: @autoclosure() -> String) {
        logWarning(message(), error: nil)
    }

    func assert(_ expression: @autoclosure () -> Bool, _ message: @autoclosure () -> String) {
        if !expression() {
            logWarning(message())
        }
    }

    // we cannot use autoclosure for expression because of https://bugs.swift.org/browse/SR-487
    func handle<T>(_ expression: () throws -> T, _ message: @autoclosure () -> String) -> T? {
        do {
            return try expression()
        } catch {
            logWarning(message(), error: error)
            return nil
        }
    }
}

class ConsoleWarningLogger: WarningLogger {
    func logWarning(_ message: @autoclosure () -> String, error: Error?) {
        var message = message()
        if !message.isEmpty, !message.hasSuffix(".") {
            message.append(".")
        }
        if let error = error {
            if !message.isEmpty {
                message.append(" ")
            }
            message.append("Error: \(error).")
        }
        NSLog(message)
    }
}
