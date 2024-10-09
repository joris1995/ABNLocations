//
//  UpdateLocationUseCase.swift
//  UseCase
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Foundation
import Domain
import Repository

public enum UpdateLocationUseCaseError: Error {
    case locationNotFound
    case cannotModifyServerLocation
    case updateFailed(String?)
}

public protocol UpdateLocationUseCaseProtocol: Sendable {
    func execute(_ location: Location) async throws(UpdateLocationUseCaseError) -> Location
}

public final class UpdateLocationUseCase: UpdateLocationUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ location: Location) async throws(UpdateLocationUseCaseError) -> Location {
        do {
            return try await repository.updatelocation(location)
        } catch {
            switch error {
            case .cannotModifyOnlineRecord:
                throw .cannotModifyServerLocation
            case .updateLocationFailed(let message):
                throw .updateFailed(message)
            }
        }
    }
}
