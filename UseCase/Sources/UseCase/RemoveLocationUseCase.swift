//
//  RemoveLocationUseCase.swift
//  UseCase
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Foundation
import Domain
import Repository

public protocol RemoveLocationUseCaseProtocol: Sendable {
    func execute(_ location: Location) async throws
}

public final class RemoveLocationUseCase: RemoveLocationUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ location: Location) async throws {
        return try await repository.deleteLocation(location)
    }
}
