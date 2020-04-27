//
//  AsyncLazy.swift
//  Rivora
//
//  Created by Dmitrii Trofimov on 19.03.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class AsyncLazy<Value> {
    private enum State {
        case none
        case loading(completion: (Value) -> Void)
        case ready(_ value: Value)
    }

    private var state: State = .none

    var value: Value? {
        if case let .ready(value) = state {
            return value
        } else {
            return nil
        }
    }

    typealias Factory = (_ completion: @escaping (Value) -> Void) -> Void

    private let factory: Factory

    init(factory: @escaping Factory) {
        self.factory = factory
    }

    private let stateAccessQueue = DispatchQueue(label: "AsyncLasy.serialAccess")
    func loadIfNeeded(completion: @escaping (Value) -> Void) {
        let codeToPerformAfterUnlock: () -> Void  = {
            stateAccessQueue.sync {
                switch state {
                case .none:
                    state = .loading(completion: completion)
                    return {
                        self.factory {
                            self.complete(with: $0)
                        }
                    }
                case .loading(let oldCompletion):
                    state = .loading(completion: { value in
                        oldCompletion(value)
                        completion(value)
                    })
                    return { }
                case .ready(let value):
                    return {
                        completion(value)
                    }
                }
            }
        }()
        codeToPerformAfterUnlock()
    }

    private func complete(with value: Value) {
        let completion: (Value) -> Void = stateAccessQueue.sync {
            guard case let .loading(completion: completion) = state else {
                fatalError("Internal error: AsyncSingleton state was mutated from outside of its loading flow")
            }
            state = .ready(value)
            return completion
        }
        completion(value)
    }
}
