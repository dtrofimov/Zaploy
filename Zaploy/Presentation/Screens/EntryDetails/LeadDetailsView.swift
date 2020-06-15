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
    @ObservedModel var lead: Lead

    var body: some View {
        return VStack {
            Text("Id: \(lead.id.optionalDescription)")
            Text("First name: \(lead.firstName.optionalDescription)")
            Text("Last name: \(lead.lastName)")
            Text("Company: \(lead.company)")
            Text("Some bool: \(lead.someBool.description)")
            Text("Some currency: \(lead.someCurrency.optionalDescription)")
            Text(" ")
            Text("CREATED BY:")
            if lead.createdBy != nil {
                UserDetailsView(user: lead.createdBy!)
            } else {
                Text("nil")
            }
        }
    }
}
