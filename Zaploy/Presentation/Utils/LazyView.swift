//
//  LazyView.swift
//  Rivora
//
//  Created by Dmitrii Trofimov on 16.03.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import SwiftUI

struct LazyView<Wrapped: View>: View {
    let bodyBlock: () -> Wrapped

    var body: Wrapped { bodyBlock() }

    init(_ body: @autoclosure @escaping () -> Wrapped) {
        bodyBlock = body
    }
}
