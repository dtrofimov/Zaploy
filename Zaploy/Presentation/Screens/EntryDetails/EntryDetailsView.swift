//
//  EntryDetailsView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 21.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct EntryDetailsView: View {
    let entry: SoupEntry

    var body: some View {
        ScrollView {
            Text(entry.asPrettyJson!)
                .font(Font.system(Font.TextStyle.body, design: Font.Design.monospaced))
        }
    }
}
