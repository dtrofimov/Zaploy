//
//  PlaygroundViewLeadView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct PlaygroundViewLeadView: View {
    @ObservedModel var lead: Lead

    var body: some View {
        Text(lead.fullName)
    }
}
