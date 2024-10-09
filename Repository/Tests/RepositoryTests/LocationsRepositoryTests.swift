import XCTest
import Testing
import Service
import Domain
import Foundation

@testable import Repository

enum RepositoryTestsError: Error {
    case invalidData
    case invalidResponse
    case invalidURL
    case noRepository
}

final class RepositoryTests: XCTestCase {
        
    var repository: LocationsRepository?
    var mockLocalLocationsService: MockLocalLocationsService!
    var mockRemoteLocationsService: MockRemoteLocationsService!
    var mockNetworkMonitor: MockNetworkMonitor!
    
    override func setUp() {
        super.setUp()
        mockLocalLocationsService = MockLocalLocationsService()
        mockRemoteLocationsService = MockRemoteLocationsService(configuration: RemoteLocationsServiceConfiguration(baseUrl: "", locationsEndpoint: ""))
        mockNetworkMonitor = MockNetworkMonitor()
        repository = LocationsRepository(remoteLocationsSerivce: mockRemoteLocationsService, localLocationsSerivce: mockLocalLocationsService, networkService: mockNetworkMonitor)
    }
    
    override func tearDown() {
        repository = nil
        mockLocalLocationsService = nil
        mockRemoteLocationsService = nil
        mockNetworkMonitor = nil
        super.tearDown()
    }
    
    // Given network is available
    // When we fetch locations
    // We expect the locations present in the service to be returned from the repository correctly
    func test_FetchLocations_FetchFromService() async throws {
        guard let repository = repository else { throw RepositoryTestsError.noRepository }
        mockNetworkMonitor.hasConnection = true
        mockRemoteLocationsService.mockLocations = [
            Location(id: UUID(), name: "Amsterdam", latitude: 52.3676, longitude: 4.9041, source: .server),
            Location(id: UUID(), name: "Berlin", latitude: 52.5200, longitude: 13.4050, source: .server),
            Location(id: UUID(), name: "New York", latitude: 40.7128, longitude: -74.0060, source: .server)
        ]
        
        let locations = try await repository.getLocations()
        XCTAssertEqual(locations.count, 3)
        XCTAssertEqual(locations[0].name, "Amsterdam")
    }
    
    // Given network is available
    // When we fetch locations, but already have the loaded locations in our cache
    // We expect only one instance of each location to be returnes
    func test_FetchLocations_FetchFromServiceAndRemoveCache() async throws {
        guard let repository = repository else { throw RepositoryTestsError.noRepository }
        mockNetworkMonitor.hasConnection = true
        mockRemoteLocationsService.mockLocations = [
            Location(id: UUID(), name: "Amsterdam", latitude: 52.3676, longitude: 4.9041, source: .server),
            Location(id: UUID(), name: "Berlin", latitude: 52.5200, longitude: 13.4050, source: .server),
            Location(id: UUID(), name: "New York", latitude: 40.7128, longitude: -74.0060, source: .server)
        ]
        
        mockLocalLocationsService.mockLocations = [
            Location(id: UUID(), name: "Amsterdam", latitude: 52.3676, longitude: 4.9041, source: .server),
            Location(id: UUID(), name: "Berlin", latitude: 52.5200, longitude: 13.4050, source: .server),
            Location(id: UUID(), name: "New York", latitude: 40.7128, longitude: -74.0060, source: .server)
        ]
        
        let locations = try await repository.getLocations()
        XCTAssertEqual(locations.count, 3)
        XCTAssertEqual(locations[0].name, "Amsterdam")
    }
    
    // Given we have no connection and expired locations in our local storage
    // When we fetch locations
    // We expect those to be filtered out
    func test_FetchLocations_deletingExpiredLocations() async throws {
        guard let repository = repository else { throw RepositoryTestsError.noRepository }
        mockNetworkMonitor.hasConnection = false
        
        mockLocalLocationsService.mockLocations = [
            Location(id: UUID(), name: "Test", latitude: 0, longitude: 0, source: .server, expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())),
            Location(id: UUID(), name: "Test", latitude: 0, longitude: 0, source: .server, expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())),
            Location(id: UUID(), name: "Test", latitude: 0, longitude: 0, source: .server, expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())),
            Location(id: UUID(), name: "Test", latitude: 0, longitude: 0, source: .server, expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())),
            Location(id: UUID(), name: "Test", latitude: 0, longitude: 0, source: .server, expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()))
        ]
        
        let locations = try await repository.getLocations()
        XCTAssertEqual(locations.count, 2)
    }
    
    // Given network is unavailable
    // When we fetch locations
    // We expect to fetch locations from the local service only
    func test_FetchLocations_FetchFromLocalService() async throws {
        guard let repository = repository else { throw RepositoryTestsError.noRepository }
        mockNetworkMonitor.hasConnection = false
        mockLocalLocationsService.mockLocations = [
            Location(id: UUID(), name: "LocalLocation1", latitude: 52.3676, longitude: 4.9041, source: .custom)
        ]
        let locations = try await repository.getLocations()
        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations[0].name, "LocalLocation1")
    }
    
    // Given location is custom
    // When we delete the location
    // We expect to delete the location from the local service
    func test_DeleteCustomLocation_Success() async throws {
        guard let repository = repository else { throw RepositoryTestsError.noRepository }
        let customLocation = Location(id: UUID(), name: "LocalLocation", latitude: 52.3676, longitude: 4.9041, source: .custom)
        try await repository.deleteLocation(customLocation)
        XCTAssertTrue(mockLocalLocationsService.didDeleteLocation)
    }
    
    // Given location is from service
    // When we delete the location
    // We expect to throw cannot delete service location error
    func test_DeleteServiceLocation_Failure() async throws {
        guard let repository = repository else { throw RepositoryTestsError.noRepository }
        let serviceLocation = Location(id: UUID(), name: "ServiceLocation", latitude: 52.5200, longitude: 13.4050, source: .server)
        do {
            try await repository.deleteLocation(serviceLocation)
        } catch {
            XCTAssertEqual(error as? LocationsRepositoryError, .cannotDeleteOnlineRecord)
        }
    }
}

// Mock Classes
final class MockLocalLocationsService: LocalLocationsServiceProtocol, @unchecked Sendable {

    var mockLocations: [Location] = []
    var didDeleteLocation: Bool = false

    func getLocations(_ filter: Predicate<DBLocation>?) async throws -> [Location] {
        return mockLocations
    }
    
    func createLocation(_ location: Location) async throws -> Location {
        return location
    }
    
    func updateLocation(_ location: Location) async throws -> Location {
        return location
    }
    
    func deleteLocation(_ location: Location) async throws {
        mockLocations.removeAll {$0.id == location.id}
        didDeleteLocation = true
    }
}

final class MockRemoteLocationsService: RemoteLocationsServiceProtocol, @unchecked Sendable {

    var configuration: RemoteLocationsServiceConfiguration
    var mockLocations: [Location] = []
    
    init(configuration: RemoteLocationsServiceConfiguration) {
        self.configuration = configuration
    }
        
    func readLocations() async throws -> [Location] {
        return mockLocations
    }
}
