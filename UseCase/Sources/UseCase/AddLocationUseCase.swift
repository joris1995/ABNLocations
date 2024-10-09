//
//  Untitled.swift
//  UseCase
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Foundation
import Domain
import Repository

public enum AddLocationUseCaseError: Error {
    case failedToAdd(String?)
}

public protocol AddLocationUseCaseProtocol: Sendable {
    func execute(_ location: Location) async throws(AddLocationUseCaseError) -> Location
}

public final class AddLocationUseCase: AddLocationUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ location: Location) async throws(AddLocationUseCaseError) -> Location {
        do {
            return try await repository.createLocation(location)
        } catch {
            switch error {
            case .addLocationFailed(let message):
                throw AddLocationUseCaseError.failedToAdd(message)
            }
        }
    }
}
