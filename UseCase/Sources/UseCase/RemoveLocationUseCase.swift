//
//  RemoveLocationUseCase.swift
//  UseCase
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Foundation
import Domain
import Repository

public enum RemoveLocationUseCaseError: Error, Equatable {
    case cannotRemoveServerLocation
    case removingFailed(String?)
}

public protocol RemoveLocationUseCaseProtocol: Sendable {
    func execute(_ location: Location) async throws(RemoveLocationUseCaseError)
}

public final class RemoveLocationUseCase: RemoveLocationUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ location: Location) async throws(RemoveLocationUseCaseError) {
        do {
            return try await repository.removeLocation(location)
        } catch {
            switch error {
            case .cannotRemoveOnlineRecord:
                throw .cannotRemoveServerLocation
            case .removeRecordFailed(let message):
                throw .removingFailed(message)
            }
        }
    }
}
