//
//  LocationsAutoCompleteRepositoryTests.swift
//  Repository
//
//  Created by Joris Dijkstra on 09/10/2024.
//

import XCTest
import Testing
import Service
import Domain
import Foundation

@testable import Repository

final class LocationsAutoCompleteRepositoryTests: XCTestCase {
    
    func provideRepository(successfulResponse: Bool, hasConnection: Bool) -> LocationsAutoCompleteRepository {
        return LocationsAutoCompleteRepository(
            autocompleteService: successfulResponse ? MockAutoCompleteServiceSuccessResponse() : MockAutoCompleteServiceFailureResponse(),
            networkService: MockNetworkMonitor(hasConnection: hasConnection))
    }
    
    // Test case for a successful fetch of locations
    func text_execte_successful_with_connection() async throws {
        // Given
        let repository = provideRepository(successfulResponse: true, hasConnection: true)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await repository.fetchLocations(query: "Test")
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertNil(thrownError)
        XCTAssertNotNil(locationsResult)
    }
    
    // Test case for a fetch of locations without connection
    func text_execte_successful_without_connection() async throws {
        // Given
        let repository = provideRepository(successfulResponse: true, hasConnection: false)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await repository.fetchLocations(query: "Test")
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertNil(locationsResult)
        XCTAssertNotNil(thrownError)
    }

    // Test case for a failed fetch of locations
    func text_exectute_unsuccessful_with_connection() async {
        // Given
        let repository = provideRepository(successfulResponse: false, hasConnection: true)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await repository.fetchLocations(query: "Test")
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertNil(locationsResult)
        XCTAssertNotNil(thrownError)
    }
    
    // Test case for a failed fetch of locations
    func text_exectute_unsuccessful_without_connection() async {
        // Given
        let repository = provideRepository(successfulResponse: false, hasConnection: false)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await repository.fetchLocations(query: "Test")
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertNil(locationsResult)
        XCTAssertNotNil(thrownError)
    }
}

final class MockAutoCompleteServiceSuccessResponse: LocationsAutocompleteServiceProtocol, @unchecked Sendable {
    var mockPreviews: [LocationPreview] = [
        LocationPreview(name: "Test 1", longitude: 1, latitude: 0),
        LocationPreview(name: "Test 2", longitude: 1, latitude: 0),
        LocationPreview(name: "Test 3", longitude: 1, latitude: 0)
    ]
    
    func loadSuggestions(for query: String) async throws(LocationsAutoCompleteServiceError) -> [LocationPreview] {
        return mockPreviews
    }
}

final class MockAutoCompleteServiceFailureResponse: LocationsAutocompleteServiceProtocol, @unchecked Sendable {
    func loadSuggestions(for query: String) async throws(LocationsAutoCompleteServiceError) -> [LocationPreview] {
        throw LocationsAutoCompleteServiceError.fetchFailed("Error")
    }
}
