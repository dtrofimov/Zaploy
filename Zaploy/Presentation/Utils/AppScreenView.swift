//
//  AppScreenView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 27.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct AppScreenView<Dependency>: View {
    private class LazyScreenResolver {
        private var resolver: (() -> AppScreen)!
        init(resolver: @escaping () -> AppScreen) {
            self.resolver = resolver
        }
        lazy var screen: AppScreen = {
            defer { resolver = nil }
            return resolver()
        }()
    }

    private let resolver: LazyScreenResolver
    let dependency: Dependency
    let comparator: (Dependency, Dependency) -> Bool

    init(resolver: @autoclosure @escaping () -> AppScreen, dependency: Dependency, comparator: @escaping (Dependency, Dependency) -> Bool) {
        self.resolver = .init(resolver: resolver)
        self.dependency = dependency
        self.comparator = comparator
    }

    private struct EquatableContent: View, Equatable {
        let resolver: LazyScreenResolver
        let dependency: Dependency
        let comparator: (Dependency, Dependency) -> Bool

        var body: some View {
            resolver.screen.asAnyView
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.comparator(lhs.dependency, rhs.dependency)
        }
    }

    var body: some View {
        EquatableContent(resolver: resolver, dependency: dependency, comparator: comparator)
    }
}

extension AppScreenView where Dependency: Equatable {
    init(resolver: @autoclosure @escaping () -> AppScreen, dependency: Dependency) {
        self.init(resolver: resolver(), dependency: dependency, comparator: ==)
    }
}

extension AppScreenView where Dependency == Void {
    init(resolver: @autoclosure @escaping () -> AppScreen) {
        self.init(resolver: resolver(), dependency: (), comparator: ==)
    }
}
