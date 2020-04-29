//
//  UserContextManager.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 29.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

protocol UserContextManager: ObservableModel {
    func userAccountDidChange(to userAccount: UserAccount?)
    var isInProgress: Bool { get }
    var userContext: UserContext? { get }
}

class UserContextManagerImpl: UserContextManager, ObservableObject {
    typealias UserContextAsyncResolver = (UserAccount, _ completion: @escaping (UserContext) -> Void) -> Void

    let userContextAsyncResolver: UserContextAsyncResolver

    init(userContextAsyncResolver: @escaping UserContextAsyncResolver) {
        self.userContextAsyncResolver = userContextAsyncResolver
    }

    @Published private(set) var userContext: UserContext?
    @Published private var progressTokens: Set<NSObject> = []
    var isInProgress: Bool { !progressTokens.isEmpty }

    func userAccountDidChange(to userAccount: UserAccount?) {
        // TODO: Handle switching userAccount in the middle of UserContext loading/unloading
        if userAccount == userContext?.userAccount { return }
        userContext = nil
        if let userAccount = userAccount {
            let progressToken = NSObject()
            progressTokens.insert(progressToken)
            userContextAsyncResolver(userAccount) { userContext in
                self.progressTokens.remove(progressToken)
                self.userContext = userContext
            }
        }
    }
}
