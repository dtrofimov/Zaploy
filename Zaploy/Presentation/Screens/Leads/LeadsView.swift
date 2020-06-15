//
//  LeadsView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct LeadsView: View, AppScreen {
    @ObservedModel var model: LeadsViewModel

    var body: some View {
        List {
            Section {
                ForEach(model.leads, id: \.id) { lead in
                    LeadsViewLeadCell(lead: lead)
                }
            }
        }
        .navigationBarTitle("Leads")
    }
}
