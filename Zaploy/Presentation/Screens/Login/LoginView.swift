//
//  LoginView.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 24.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import SwiftUI

struct LoginView: View, AppScreen {
    @ObservedObject var loginManager: LoginManager
    let nextScreenResolver: (UserContext) -> AppScreen

    var body: some View {
        if loginManager.isInProgress {
            return Spinner(style: .medium).asAnyView
        } else if let userContext = loginManager.userContext {
            return nextScreenResolver(userContext).asAnyView
        } else {
            return Button("Login") {
                self.loginManager.login()
            }
            .asAnyView
        }
    }
}
