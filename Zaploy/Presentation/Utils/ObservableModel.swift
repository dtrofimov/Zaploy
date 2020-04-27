//
//  ObservableModel.swift
//  Rivora
//
//  Created by Dmitrii Trofimov on 26.03.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/**
    A protocol with requirements equal to `ObservableObject`, but without `associatedtype` requirements,
    which allows to use it as a concrete type, as well as any inherited protocol (e. g. some view model protocol).

    Example:

    ```
    protocol DemoViewModel: ObservableModel {
        var description: String { get }
    }

    class DemoViewModelImpl: DemoViewModel, ObservableObject {
        @Published var description: String = "Some description"
    }
    ```
 */
public protocol ObservableModel: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

/**
    A property wrapper functionally equivalent to `ObservedObject`, but not explicitly requiring any protocol conformance.
    Instead, it checks conformance to `ObservableModel` in runtime at initialization moment.
    This allows to use a protocol (some view model protocol inherited from `ObservableModel`) as a concrete type to store an actual model
    and to uncouple it from a concrete view model implementation.

    Example:

    ```
    struct DemoView: View {
        @ObservedModel var model: DemoViewModel

        var body: some View {
            Text(model.description)
        }
    }
    ```
 */
@propertyWrapper
public struct ObservedModel<Wrapped>: DynamicProperty {
    public let wrappedValue: Wrapped

    private class Observer: ObservableObject {
        @Published var value: () = ()
    }

    @ObservedObject private var observer: Observer

    private let disposable: AnyCancellable

    public init(wrappedValue: Wrapped) {
        let observer = Observer()
        self.observer = observer
        self.wrappedValue = wrappedValue
        guard let observable = wrappedValue as? ObservableModel else {
            fatalError("ObservedModel should be used with ObservableModel conforming types only")
        }
        self.disposable = observable.objectWillChange.sink { value in
            observer.value = ()
        }
    }
}

/**
    An auxiliary protocol with an empty default implementation of `ObservableModel`,
    useful to implement a simple view model for preview purposes.
 */
public protocol StubObservableModel: ObservableModel {
}

extension StubObservableModel {
    var objectWillChange: ObservableObjectPublisher { .init() }
}
