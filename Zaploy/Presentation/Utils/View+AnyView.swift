//
//  View+AnyView.swift
//  Rivora
//
//  Created by Dmitrii Trofimov on 16.03.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

extension View {
    var asAnyView: AnyView {
        .init(self)
    }
}
