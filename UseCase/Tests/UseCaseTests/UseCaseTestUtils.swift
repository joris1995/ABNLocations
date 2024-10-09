//
//  UseCaseTestUtils.swift
//  UseCase
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Repository
import Foundation
import Domain
import Service

public enum UseCaseTestServiceResponseType {
    case success
    case failure
}

public class UseCaseTestUtils {
    static public func provideRepository(serviceResponseType: UseCaseTestServiceResponseType) -> LocationsRepository {
        let mockLocalLocationsService: any LocalLocationsServiceProtocol = serviceResponseType == .success ? MockLocalLocationsServiceSuccessResponse() : MockLocalLocationsServiceFailureResponse()
        let mockRemoteLocationsService: any RemoteLocationsServiceProtocol = serviceResponseType == .success ? MockRemoteLocationsServiceSuccessResponse(configuration: RemoteLocationsServiceConfiguration(baseUrl: "", locationsEndpoint: "")) : MockRemoteLocationsServiceFailureResponse(configuration: RemoteLocationsServiceConfiguration(baseUrl: "", locationsEndpoint: ""))
        let mockNetworkMonitor = MockNetworkMonitor()
        let repository = LocationsRepository(remoteLocationsSerivce: mockRemoteLocationsService, localLocationsSerivce: mockLocalLocationsService, networkService: mockNetworkMonitor)
        return repository
    }
    
    static public func provideAutoCompleteRepository(serviceResponseType: UseCaseTestServiceResponseType, hasNetworkConnection: Bool) -> LocationsAutoCompleteRepository {
        let mockNetworkMonitor = MockNetworkMonitor(hasConnection: hasNetworkConnection)
        let autoCompleteService: any LocationsAutocompleteServiceProtocol = serviceResponseType == .success ? MockAutoCompleteServiceSuccessResponse() : MockAutoCompleteServiceFailureResponse()
        return LocationsAutoCompleteRepository(autocompleteService: autoCompleteService, networkService: mockNetworkMonitor)
    }
}

// Mock Classes
final class MockLocalLocationsServiceSuccessResponse: LocalLocationsServiceProtocol, @unchecked Sendable {

    var mockLocations: [Location] = []
    var didRemoveLocation: Bool = false

    func getLocations(_ filter: Predicate<DBLocation>?) async throws(LocalLocationsServiceError) -> [Location] {
        return mockLocations
    }
    
    func createLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location {
        return location
    }
    
    func updateLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location {
        return location
    }
    
    func removeLocation(_ location: Location) async throws(LocalLocationsServiceError) {
        mockLocations.removeAll {$0.id == location.id}
        didRemoveLocation = true
    }
}

final class MockLocalLocationsServiceFailureResponse: LocalLocationsServiceProtocol, @unchecked Sendable {

    var mockLocations: [Location] = []
    var didRemoveLocation: Bool = false

    func getLocations(_ filter: Predicate<DBLocation>?) async throws(LocalLocationsServiceError) -> [Location] {
        throw LocalLocationsServiceError.fetchFailed("Failre")
    }
    
    func createLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location {
        throw LocalLocationsServiceError.insertFailed("Failre")
    }
    
    func updateLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location {
        throw LocalLocationsServiceError.updateFailed("Failre")
    }
    
    func removeLocation(_ location: Location) async throws(LocalLocationsServiceError) {
        throw LocalLocationsServiceError.removeFailed("Failre")
    }
}

final class MockRemoteLocationsServiceSuccessResponse: RemoteLocationsServiceProtocol, @unchecked Sendable {

    var configuration: RemoteLocationsServiceConfiguration
    var mockLocations: [Location] = []
    
    init(configuration: RemoteLocationsServiceConfiguration) {
        self.configuration = configuration
    }
        
    func readLocations() async throws(RemoteLocationsServiceError) -> [Location] {
        return mockLocations
    }
}

final class MockRemoteLocationsServiceFailureResponse: RemoteLocationsServiceProtocol, @unchecked Sendable {

    var configuration: RemoteLocationsServiceConfiguration
    var mockLocations: [Location] = []
    
    init(configuration: RemoteLocationsServiceConfiguration) {
        self.configuration = configuration
    }
        
    func readLocations() async throws(RemoteLocationsServiceError) -> [Location] {
        throw RemoteLocationsServiceError.invalidResponse("Error")
    }
}

final class MockNetworkMonitor: NetworkServiceProtocol, @unchecked Sendable {
    var hasConnection: Bool = false
    
    init(hasConnection: Bool = false) {
        self.hasConnection = hasConnection
    }
    
    func isConnected() async -> Bool {
        return hasConnection
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
