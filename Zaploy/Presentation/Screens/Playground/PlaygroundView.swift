//
//  PlaygroundView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct PlaygroundView: View {
    @ObservedObject var playground = SyncDownPlayground.shared

    var body: some View {
        return List {
            LoginStatusView()
            Text("Sync status: \(playground.syncStatus ?? "nil")")
            Group {
                Button("Upsert Local Record") {
                    self.playground.upsertLocalRecord()
                }
                Button("Upsert Non-Local Record") {
                    self.playground.upsertNonLocalRecord()
                }
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
                Button("Sync Down Metadata") {
                    self.playground.syncDownMetadata()
                }
                Button("Load Metadata from Cache") {
                    self.playground.loadMetadataFromCache()
                }
                Button("Sync Down Layout") {
                    self.playground.syncDownLayout()
                }
            }
            Text("")
            ForEach(playground.leadDicts, id: \.soupEntryId) { dict in
                Text(dict["Name"] as! String)
            }
        }
    }
}
