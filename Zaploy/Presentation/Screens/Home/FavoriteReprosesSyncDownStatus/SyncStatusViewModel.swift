//
//  SyncStatusViewModel.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 16.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Combine

protocol SyncStatusViewModel: ObservableModel {
    var description: String { get }
    var status: String { get }
    var isInProgress: Bool { get }
    func didTap()
}

class SyncStatusViewModelImpl: SyncStatusViewModel, ObservableObject {
    let description: String
    let syncService: SyncService
    private var disposables: [AnyCancellable] = []

    internal init(description: String, syncService: SyncService) {
        self.description = description
        self.syncService = syncService
        self.syncService.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &disposables)
    }

    private static let dateFormatter = ISO8601DateFormatter()
    private var lastDateString: String {
        syncService.lastStartDate
            .map { Self.dateFormatter.string(from: $0) }
            .optionalDescription
    }

    var status: String {
        switch syncService.status {
        case .new:
            return "new"
        case .running:
            return "running"
        case let .failure(error):
            return "error: \(error)"
        case .success:
            return "success at \(lastDateString)"
        }
    }

    var isInProgress: Bool { syncService.isInProgress }

    func didTap() {
        syncService.start()
    }
}
