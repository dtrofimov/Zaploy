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
            Group {
                LoginStatusView()
                Text("Sync Down Status: \(playground.syncDownStatus ?? "nil")")
                Text("Sync Up Status: \(playground.syncUpStatus ?? "nil")")
                Button("Upsert Local Record") {
                    self.playground.upsertLocalRecord()
                }
                Button("Upsert Non-Local Record") {
                    self.playground.upsertNonLocalRecord()
                }
                Button("Sync Down") {
                    self.playground.syncDown()
                }
                Button("Resync Down") {
                    self.playground.resyncDown()
                }
            }
            Group {
                Button("Clean Ghosts") {
                    self.playground.cleanGhosts()
                }
                Button("Delete Sync Down") {
                    self.playground.deleteSyncDown()
                }
                Button("Sync Up") {
                    self.playground.syncUp()
                }
                Button("Resync Up") {
                    self.playground.resyncUp()
                }
                Button("Delete Sync Up") {
                    self.playground.deleteSyncUp()
                }
                Button("Mark First As Deleted") {
                    self.playground.markFirstAsDeleted()
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
                Text("\(dict["FirstName"] as! String) \(dict["LastName"] as! String)")
            }
        }
    }
}
