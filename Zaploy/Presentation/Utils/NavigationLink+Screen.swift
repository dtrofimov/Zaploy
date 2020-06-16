//
//  NavigationLink+Screen.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 16.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

extension NavigationLink where Destination == LazyView<AnyView> {
    init(screen: @escaping @autoclosure () -> AppScreen, label: () -> Label) {
        self.init(destination: LazyView(screen().asAnyView), label: label)
    }
}
