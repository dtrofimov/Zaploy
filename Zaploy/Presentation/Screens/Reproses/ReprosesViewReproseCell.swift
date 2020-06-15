//
//  ReprosesViewReproseCell.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct ReprosesViewReproseCell: View {
    @ObservedModel var reprose: Reprose

    var body: some View {
        Text(reprose.name)
    }
}
