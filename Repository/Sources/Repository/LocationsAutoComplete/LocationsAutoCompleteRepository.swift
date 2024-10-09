//
//  LocationsAutoCompleteRepository.swift
//  Repository
//
//  Created by Joris Dijkstra on 06/10/2024.
//

import Foundation
import Service
import Domain

public final class LocationsAutoCompleteRepository: LocationsAutoCompleteRepositoryProtocol {
    public let autocompleteService: any LocationsAutocompleteServiceProtocol
    public let netowkService: any NetworkServiceProtocol
    
    required public init(autocompleteService: any LocationsAutocompleteServiceProtocol, networkService: any NetworkServiceProtocol) {
        self.autocompleteService = autocompleteService
        self.netowkService = networkService
    }
    
    public func fetchLocations(query: String) async throws(LocationsAutoCompleteRepositoryError) -> [LocationPreview] {
        let isconnected = await netowkService.isConnected()
        
        guard isconnected else {
            throw LocationsAutoCompleteRepositoryError.noConnection
        }
        
        do {
            return try await autocompleteService.loadSuggestions(for: query)
        } catch {
            switch error {
                case .noConnection:
                throw LocationsAutoCompleteRepositoryError.noConnection
            case .fetchFailed(let message):
                throw .invalidResponse(message)
                
            }
        }
    }
}
