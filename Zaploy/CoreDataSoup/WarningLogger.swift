//
//  WarningLogger.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 13.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

protocol WarningLogger {
    var isEnabled: Bool { get }

    func logWarning(_ message: @autoclosure () -> String, error: Error?)
}

extension WarningLogger {
    func logWarning(_ message: @autoclosure() -> String) {
        logWarning(message(), error: nil)
    }

    func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        if !condition() {
            logWarning(message())
        }
    }
}

extension Bool {
    func check(_ warningLogger: WarningLogger, _ message: @autoclosure () -> String) -> Bool {
        if !self {
            warningLogger.logWarning(message())
        }
        return self
    }
}

extension Optional {
    func check(_ warningLogger: WarningLogger, _ message: @autoclosure () -> String) -> Optional {
        if self == nil {
            warningLogger.logWarning(message())
        }
        return self
    }
}

extension Optional where Wrapped == Any {
    func checkType<T>(_ warningLogger: WarningLogger, _ messagePrefix: @autoclosure () -> String) -> T? {
        if let value = self, !(value is T), !(value is NSNull) {
            warningLogger.logWarning("\(messagePrefix()). Unexpected value type: \(value) is \(type(of: value)) instead of \(T.self)")
        }
        return self as? T
    }
}

extension Result {
    func check(_ warningLogger: WarningLogger, _ message: @autoclosure () -> String) -> Optional<Success> {
        switch self {
        case let .success(success):
            return success
        case let .failure(error):
            warningLogger.logWarning(message(), error: error)
            return nil
        }
    }
}

class ConsoleWarningLogger: WarningLogger {
    var isEnabled = true

    func logWarning(_ message: @autoclosure () -> String, error: Error?) {
        guard isEnabled else { return }
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
        NSLog("WARNING! \(message)")
    }
}
