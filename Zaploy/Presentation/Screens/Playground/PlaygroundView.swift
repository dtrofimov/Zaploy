//
//  PlaygroundView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI
import MobileSync

struct PlaygroundView: View {
    @ObservedObject var playground = SyncDownPlayground.shared

    var body: some View {
        let syncStatusString: String = {
            guard let syncState = playground.syncState else { return "nil" }
            return SyncState.syncStatus(toString: syncState.status)
        }()
        return List {
            LoginStatusView()
            Text("Sync status: \(syncStatusString)")
            Button("Sync Down") {
                self.playground.syncDown()
            }
            Button("Resync") {
                self.playground.resync()
            }
            Button("Clean Ghosts") {
                self.playground.cleanGhosts()
            }
            Button("Delete Sync") {
                self.playground.deleteSync()
            }
            Text("")
            ForEach(playground.leadDicts, id: \.id) { dict in
                Text(dict["Name"] as! String)
            }
        }
    }
}

fileprivate extension NSDictionary {
    var id: String { self["Id"] as! String }
}
