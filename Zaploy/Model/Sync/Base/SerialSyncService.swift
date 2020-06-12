//
//  SerialSyncService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

class SerialSyncService: SyncService, ObservableObject {
    let childServices: [SyncService]
    init(childServices: [SyncService]) {
        self.childServices = childServices
    }

    var status: SyncStatus {
        if isInProgress { return .running }
        var isNew = false
        var firstError: Error?
        for child in childServices {
            switch child.status {
            case .new:
                isNew = true
            case .running:
                return .running
            case let .failure(error):
                firstError = firstError ?? error
            case .success:
                break
            }
        }
        if isNew {
            return .new
        } else if let error = firstError {
            return .failure(error)
        } else {
            return .success
        }
    }

    var lastStartDate: Date? {
        childServices.first?.lastStartDate
    }

    private typealias ProgressToken = NSObject
    private var progressTokens: [ProgressToken] = []
    var isInProgress: Bool { !progressTokens.isEmpty }

    func start() {
        let progressToken = ProgressToken()
        progressTokens.append(progressToken)
        var failed = false
        var completion: () -> Void = {
            self.progressTokens.removeAll(where: { $0 == progressToken })
            self.objectWillChange.send()
        }
        for childService in childServices.reversed() {
            completion = { [completion] in
                guard !failed else { return completion() }
                childService.perform { result in
                    if case .failure(_) = result {
                        failed = true
                    }
                    completion()
                }
            }
        }
        completion()
        objectWillChange.send()
    }
}
