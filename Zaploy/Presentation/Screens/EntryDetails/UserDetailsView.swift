//
//  UserDetailsView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 04.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct UserDetailsView: View, AppScreen {
    @ObservedModel var user: User

    var body: some View {
        VStack {
            Text("Id: \(user.id.optionalDescription)")
            Text("First name: \(user.firstName.optionalDescription)")
            Text("Last name: \(user.lastName)")
            Text("Username: \(user.username)")
        }
    }
}
