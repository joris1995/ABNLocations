//
//  LocationsAutoCompleteUseCase.swift
//  UseCase
//
//  Created by Joris Dijkstra on 06/10/2024.
//

import Foundation
import Domain
import Repository

public enum LocationsAutoCompleteUseCaseError: Error {
    case loadingFailed(String?)
    case noConnection
}

public protocol LocationsAutoCompleteUseCaseProtocol: Sendable {
    func execute(with query: String) async throws(LocationsAutoCompleteUseCaseError) -> [LocationPreview]
}

public final class LocationsAutoCompleteUseCase: LocationsAutoCompleteUseCaseProtocol {
    private let locationRepository: LocationsAutoCompleteRepositoryProtocol
    
    public init(locationRepository: any LocationsAutoCompleteRepositoryProtocol) {
        self.locationRepository = locationRepository
    }
    
    public func execute(with query: String) async throws(LocationsAutoCompleteUseCaseError) -> [LocationPreview] {
        do {
            return try await locationRepository.fetchLocations(query: query)
        } catch {
            switch error {
            case .invalidResponse(let message):
                throw .loadingFailed(message)
            case .noConnection:
                throw .noConnection
            }
        }
    }
}
