// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Domain
import Repository

public protocol FetchLocationsUseCaseProtocol: Sendable {
    func execute() async throws -> [Location]
}

public final class FetchLocationsUseCase: FetchLocationsUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Location] {
        return try await repository.getLocations()
    }
}
