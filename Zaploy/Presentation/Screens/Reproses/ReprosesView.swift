//
//  ReprosesView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct ReprosesView: View, AppScreen {
    @ObservedModel var model: ReprosesViewModel

    var body: some View {
        List {
            Section {
                ForEach(model.reproses, id: \.guid) { reprose in
                    ReprosesViewReproseCell(reprose: reprose)
                }
            }
        }
        .navigationBarTitle("Reproses")
    }
}
