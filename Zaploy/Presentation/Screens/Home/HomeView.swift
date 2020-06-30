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
    let favoriteReprosesSyncDownStatusView: AnyView
    let nonFavoriteReprosesSyncDownStatusView: AnyView

    var body: some View {
        List {
            Section {
                favoriteReprosesSyncDownStatusView
                nonFavoriteReprosesSyncDownStatusView
                NavigationLink(screen: self.reprosesScreenResolver()) {
                    Text("Reproses")
                }
                NavigationLink(screen: self.leadsScreenResolver()) {
                    Text("Leads")
                }
                NavigationLink(screen: self.deegsScreenResolver()) {
                    Text("Deegs")
                }
                NavigationLink(screen: self.playgroundScreenResolver()) {
                    Text("Old Playground")
                }
            }
        }
        .navigationBarTitle("Home")
    }
}
