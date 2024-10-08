//
//  Untitled.swift
//  UseCase
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Foundation
import Domain
import Repository

public protocol AddLocationUseCaseProtocol: Sendable {
    func execute(_ location: Location) async throws -> Location
}

public final class AddLocationUseCase: AddLocationUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ location: Location) async throws -> Location {
        return try await repository.createLocation(location)
    }
}
