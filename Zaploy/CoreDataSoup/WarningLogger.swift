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

    // depending on the optimization, the condition is not guaranteed to be called in assert
    func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String)
}

extension WarningLogger {
    func logWarning(_ message: @autoclosure() -> String) {
        logWarning(message(), error: nil)
    }

    func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String) {
        if !condition() {
            logWarning(message())
        }
    }

    func checkType<T>(_ value: Any?, _ messagePrefix: String) -> T? {
        if let value = value, !(value is T), !(value is NSNull) {
            logWarning("\(messagePrefix). Unexpected value type: \(value) is \(type(of: value)) instead of \(T.self)")
        }
        return value as? T
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
        NSLog("WARNING! \(message)")
    }
}
