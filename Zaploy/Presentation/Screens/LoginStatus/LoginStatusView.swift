//
//  LoginStatusView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct LoginStatusView: View {
    @ObservedObject var loginManager = LoginManager.shared

    var body: some View {
        NSLog("reloading")
        if loginManager.isInProgress {
            return Spinner(style: .medium).asAnyView
        } else if let user = loginManager.user {
            return Text("\(user.idData.username)").asAnyView
        } else {
            return Button("Login") {
                self.loginManager.login()
            }
            .asAnyView
        }
    }
}
