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
    @ObservedModel var userContextManager: UserContextManager
    let nextScreenResolver: (UserContext) -> AppScreen

    var body: some View {
        if loginManager.isInProgress || userContextManager.isInProgress {
            return Spinner(style: .medium).asAnyView
        } else if let userContext = userContextManager.userContext {
            return AppScreenView(resolver: self.nextScreenResolver(userContext), dependency: userContext, comparator: ===).asAnyView
        } else {
            return Button("Login") {
                self.loginManager.login()
            }
            .asAnyView
        }
    }
}
