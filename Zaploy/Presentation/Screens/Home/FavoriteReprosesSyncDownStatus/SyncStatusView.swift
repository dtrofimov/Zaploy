//
//  SyncStatusView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 16.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct SyncStatusView: View {
    @ObservedModel var model: SyncStatusViewModel

    var body: some View {
        Button(action: {
            self.model.didTap()
        }) {
            HStack {
                Text(model.description)
                Text("|")
                Text(model.status)
                if model.isInProgress {
                    Spinner(style: .medium)
                }
            }
        }
    }
}
