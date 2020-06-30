//
//  SyncService.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 05.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import Combine

enum SyncStatus {
    case new
    case running
    case failure(Error)
    case success
}

protocol SyncService: ObservableModel {
    var status: SyncStatus { get }
    var lastStartDate: Date? { get }
    func start()
}

extension SyncService {
    func perform(completion: @escaping (Result<(), Error>) -> Void) {
        if case .running = status {} else {
            self.start()
        }
        var singleCompletion: ((Result<(), Error>) -> Void)? = completion
        var task: AnyCancellable?
        func checkStatus() {
            guard let completion = singleCompletion else { return }
            switch status {
            case .new:
                return
            case .running:
                return
            case let .failure(error):
                completion(.failure(error))
            case .success:
                completion(.success(()))
            }
            singleCompletion = nil
            task?.cancel()
            task = nil
        }
        task = self.objectWillChange.sink { _ in
            checkStatus()
        }
        checkStatus()
    }

    var isInProgress: Bool {
        switch status {
        case .new, .failure(_), .success:
            return false
        case .running:
            return true
        }
    }
}
