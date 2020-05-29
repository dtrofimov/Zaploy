//
//  MultiTaskTracker.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 29.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

/// A thread-unsafe analogue of DispatchGroup, calling its completion synchronously within the last task completion.
class MultiTaskTracker {
    private typealias ProgressToken = NSObject
    private var progressTokens: [ProgressToken] = []
    var isInProgress: Bool { !progressTokens.isEmpty }

    func track(task: (_ completion: @escaping () -> Void) -> Void) {
        let progressToken = ProgressToken()
        progressTokens.append(progressToken)
        task {
            self.progressTokens.removeAll { $0 == progressToken }
            self.checkCompletion()
        }
    }

    private var completions: [() -> Void] = []

    func onComplete(completion: @escaping () -> Void) {
        completions.append(completion)
        checkCompletion()
    }

    private func checkCompletion() {
        if isInProgress { return }
        while !completions.isEmpty {
            completions.removeFirst()()
        }
    }
}
