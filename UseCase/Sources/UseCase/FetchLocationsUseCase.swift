// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Domain
import Repository

public enum FetchLocationsUseCaseError: Error {
    case fetchFailed(String?)
}

public protocol FetchLocationsUseCaseProtocol: Sendable {
    func execute() async throws(FetchLocationsUseCaseError) -> [Location]
}

public final class FetchLocationsUseCase: FetchLocationsUseCaseProtocol {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws(FetchLocationsUseCaseError) -> [Location] {
        do {
            return try await repository.getLocations()
        } catch {
            switch error {
            case .loadingFailed(let message):
                throw FetchLocationsUseCaseError.fetchFailed(message)
            }
        }
    }
}
