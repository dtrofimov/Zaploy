//
//  HomeView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 15.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct HomeView: View, AppScreen {
    let reprosesScreenResolver: () -> AppScreen
    let leadsScreenResolver: () -> AppScreen
    let deegsScreenResolver: () -> AppScreen
    let playgroundScreenResolver: () -> AppScreen

    var body: some View {
        List {
            Section {
                NavigationLink(destination: LazyView(self.reprosesScreenResolver().asAnyView)) {
                    Text("Reproses")
                }
                NavigationLink(destination: LazyView(self.leadsScreenResolver().asAnyView)) {
                    Text("Leads")
                }
                NavigationLink(destination: LazyView(self.deegsScreenResolver().asAnyView)) {
                    Text("Deegs")
                }
                NavigationLink(destination: LazyView(self.playgroundScreenResolver().asAnyView)) {
                    Text("Old Playground")
                }
            }
        }
        .navigationBarTitle("Home")
    }
}
