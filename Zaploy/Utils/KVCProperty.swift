//
//  KvcProperty.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 25.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

@propertyWrapper
public struct KVC<Value> {
    private let key: String
    private let `default`: Value

    public init(_ key: String, default: Value) {
        self.key = key
        self.default = `default`
    }

    public init<T>(_ key: String) where Value == Optional<T> {
        self.init(key, default: nil)
    }

    // This uses an undocumented property wrapper API providing an access to an enclosing self,
    // which is used in @Published properties.
    public static subscript<EnclosingSelf>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, KVC>
    ) -> Value where EnclosingSelf: NSObject {
        get {
            let myself = observed[keyPath: storageKeyPath]
            return observed.value(forKey: myself.key) as? Value ?? myself.default
        }
        set {
            let myself = observed[keyPath: storageKeyPath]
            observed.setValue(newValue, forKey: myself.key)
        }
    }

    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("called wrappedValue getter") }
        set { fatalError("called wrappedValue setter") }
    }
}
