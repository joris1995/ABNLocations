//
//  LocationsAutoCompleteUseCase.swift
//  UseCase
//
//  Created by Joris Dijkstra on 06/10/2024.
//

import Foundation
import Domain
import Repository

public protocol LocationsAutoCompleteUseCaseProtocol: Sendable {
    func execute(with query: String) async throws -> [LocationPreview]
}

public final class LocationsAutoCompleteUseCase: LocationsAutoCompleteUseCaseProtocol {
    private let locationRepository: LocationsAutoCompleteRepositoryProtocol
    
    public init(locationRepository: any LocationsAutoCompleteRepositoryProtocol) {
        self.locationRepository = locationRepository
    }
    
    public func execute(with query: String) async throws -> [LocationPreview] {
        return try await locationRepository.fetchLocations(query: query)
    }
}
