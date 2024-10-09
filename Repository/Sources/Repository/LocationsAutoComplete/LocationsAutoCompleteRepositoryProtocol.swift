//
//  LocationsAutoCompleteRepositoryProtocol.swift
//  Repository
//
//  Created by Joris Dijkstra on 06/10/2024.
//

import Foundation
import Service
import Domain

public protocol LocationsAutoCompleteRepositoryProtocol: Sendable {
    var autocompleteService: LocationsAutocompleteServiceProtocol { get }
    var netowkService: NetworkServiceProtocol { get }
    
    init (autocompleteService: LocationsAutocompleteServiceProtocol, networkService: NetworkServiceProtocol)
    
    func fetchLocations(query: String) async throws(LocationsAutoCompleteRepositoryError) -> [LocationPreview]
}
