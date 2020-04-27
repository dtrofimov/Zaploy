//
//  AppScreen.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 23.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

/// A non-generic node of the app screen hierarchy not coupled to a specific UI framework. Wrap this in conditional compilation for unit testing.
protocol AppScreen {
    var asAnyView: AnyView { get }
}

extension AnyView: AppScreen {
    var asAnyView: AnyView { self }
}

typealias EmptyScreen = EmptyView

extension EmptyScreen: AppScreen {}
