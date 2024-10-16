//
//  LocationsAutoCompleteService.swift
//  Service
//
//  Created by Joris Dijkstra on 09/10/2024.
//

import Foundation
import Domain
import MapKit

public final class LocationsAutocompleteService: LocationsAutocompleteServiceProtocol {
    public init() {}
    
    public func loadSuggestions(for query: String) async throws(LocationsAutoCompleteServiceError) -> [LocationPreview] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            // Filter results to include only cities, regions, or countries
            let filteredResults = response.mapItems.filter { mapItem in
                guard let _ = mapItem.placemark.locality ?? mapItem.placemark.administrativeArea ?? mapItem.placemark.country else {
                    return false
                }
                return true
            }
            
            let locations = filteredResults.compactMap { item -> LocationPreview? in
                guard let name = item.name,
                      let coordinate = item.placemark.location?.coordinate else {
                    return nil
                }
                return LocationPreview(name: name, longitude: coordinate.longitude, latitude: coordinate.latitude)
            }
            
            return locations
        } catch {
            if let networkError = error as? URLError {
                if networkError.code == .notConnectedToInternet {
                    throw .noConnection
                }
            } else if let mapKitError = error as? MKError {
                if mapKitError.code == .serverFailure {
                    throw .noConnection
                } else if mapKitError.code == .placemarkNotFound {
                    // we do not fail when no results are found, we just return an empty array
                    return []
                }
            }
            throw .fetchFailed(error.localizedDescription)
        }
    }
}
