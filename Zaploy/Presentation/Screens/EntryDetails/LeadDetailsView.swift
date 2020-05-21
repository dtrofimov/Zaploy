//
//  LeadDetailsView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 21.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI
import PseudoSmartStore

struct LeadDetailsView: View, AppScreen {
    let lead: Lead

    var body: some View {
        VStack {
            Text("Id: \(lead.id.optionalDescription)")
            Text("First name: \(lead.firstName.optionalDescription)")
            Text("Last name: \(lead.lastName)")
            Text("Company: \(lead.company)")
        }
    }
}