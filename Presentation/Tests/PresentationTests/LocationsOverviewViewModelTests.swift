import XCTest
import Domain
import UseCase
@preconcurrency import Combine

@testable import Presentation

@MainActor
final class PresentationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func test_fetchLocations_whenFetchSucceeds_shouldUpdateLocations() async {
        // Given
        let mockFetchUseCase = MockFetchLocationsUseCase()
        let mockRemoveUseCase = MockRemoveLocationUseCase()
        mockFetchUseCase.mockLocations = [Location(id: UUID(), name: "Location 1", latitude: 0, longitude: 1, source: .custom), Location(id: UUID(), name: "Location 2", latitude: 0, longitude: 1, source: .custom)]
        let viewModel = LocationsOverviewViewModel(fetchLocationsUseCase: mockFetchUseCase, removeLocationUseCase: mockRemoveUseCase, locationDetailViewViewModelFactory: MockLocationDetailViewModelFactory())
        
        // When
        viewModel.fetchLocations()
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for locations to be updated")
        viewModel.$locations
            .dropFirst()
            .sink { locations in
                XCTAssertEqual(locations.count, 2)
                XCTAssertEqual(locations.first?.name, "Location 1")
                XCTAssertEqual(locations.last?.name, "Location 2")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func test_fetchLocations_whenFetchFails_shouldNotUpdateLocations() async {
        // Given
        let mockFetchUseCase = MockFetchLocationsUseCase()
        let mockRemoveUseCase = MockRemoveLocationUseCase()
        mockFetchUseCase.shouldThrowError = true
        let viewModel = LocationsOverviewViewModel(fetchLocationsUseCase: mockFetchUseCase, removeLocationUseCase: mockRemoveUseCase, locationDetailViewViewModelFactory: MockLocationDetailViewModelFactory())
        
        // When
        viewModel.fetchLocations()
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for locations to remain empty")
        viewModel.$locations
            .sink { locations in
                XCTAssertTrue(locations.isEmpty, "Locations should remain empty when fetch fails")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func test_removeLocation_whenRemoveSucceeds_shouldRefreshLocations() async {
        // Given
        let initialLocations = [
            Location(id: UUID(), name: "Location 1", latitude: 0, longitude: 1, source: .custom),
            Location(id: UUID(), name: "Location 2", latitude: 0, longitude: 1, source: .custom)
        ]
        
        let mockFetchUseCase = MockFetchLocationsUseCase(mockLocations: initialLocations)
        let mockRemoveUseCase = MockRemoveLocationUseCase()
        let viewModel = LocationsOverviewViewModel(fetchLocationsUseCase: mockFetchUseCase, removeLocationUseCase: mockRemoveUseCase, locationDetailViewViewModelFactory: MockLocationDetailViewModelFactory())

        let fetchExpectation = XCTestExpectation(description: "Wait for initial fetchLocations to complete")
        viewModel.$locations
            .dropFirst()
            .sink { locations in
                if locations.count == 2 {
                    fetchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.fetchLocations()
        await fulfillment(of: [fetchExpectation], timeout: 2.0)

        // THhen
        let removeExpectation = XCTestExpectation(description: "Wait for removeLocation to succeed and refresh locations")
        viewModel.$locations
            .dropFirst()
            .sink { locations in
                XCTAssertEqual(mockRemoveUseCase.removedLocation?.name, "Location 1", "The location should be removed from the use case")
                XCTAssertEqual(locations.count, 2, "Expect to have two locations again, since the fetch use case still returns 2")
                removeExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.removeLocation(initialLocations.first!)
        await fulfillment(of: [removeExpectation], timeout: 2.0)
    }

    func test_removeLocation_whenRemoveFails_shouldNotRefreshLocations() async {
        // Given
        let mockFetchUseCase = MockFetchLocationsUseCase(
            mockLocations: [
                Location(id: UUID(), name: "Location 1", latitude: 0, longitude: 1, source: .custom),
                Location(id: UUID(), name: "Location 2", latitude: 0, longitude: 1, source: .custom)
            ]
        )
        let mockRemoveUseCase = MockRemoveLocationUseCase(shouldThrowError: true)
        let viewModel = LocationsOverviewViewModel(fetchLocationsUseCase: mockFetchUseCase, removeLocationUseCase: mockRemoveUseCase, locationDetailViewViewModelFactory: MockLocationDetailViewModelFactory())

        // When
        let locationsExpectation = XCTestExpectation(description: "Wait for initial fetchLocations to complete")
        viewModel.$locations
            .dropFirst()
            .sink { locations in
                if locations.count == 2 {
                    locationsExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.fetchLocations()
        await fulfillment(of: [locationsExpectation], timeout: 2.0)

        // Then
        let removeExpectation = XCTestExpectation(description: "Wait for removeLocation to fail and locations to remain unchanged")
        viewModel.$locations
            .sink { locations in
                XCTAssertNil(mockRemoveUseCase.removedLocation, "The location should not be removed when an error occurs")
                XCTAssertEqual(locations.count, 2, "Locations should remain the same if removal fails")
                removeExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.removeLocation(mockFetchUseCase.mockLocations.first!)
        await fulfillment(of: [removeExpectation], timeout: 2.0)
    }
}


// Mock implementations of the use case protocols
final class MockFetchLocationsUseCase: FetchLocationsUseCaseProtocol, @unchecked Sendable {
    var shouldThrowError: Bool
    var mockLocations: [Location]

    init(shouldThrowError: Bool = false, mockLocations: [Location] = []) {
        self.shouldThrowError = shouldThrowError
        self.mockLocations = mockLocations
    }

    func execute() async throws -> [Location] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockLocations
    }
}

final class MockAddLocationsUseCase: AddLocationUseCaseProtocol, @unchecked Sendable {
    
    init() { }

    func execute(_ location: Location) async throws -> Location {
        return location
    }
}

final class MockRemoveLocationUseCase: RemoveLocationUseCaseProtocol, @unchecked Sendable {
    var shouldThrowError: Bool
    var removedLocation: Location?

    init(shouldThrowError: Bool = false) {
        self.shouldThrowError = shouldThrowError
    }

    func execute(_ location: Location) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 2, userInfo: nil)
        }
        removedLocation = location
    }
}

@MainActor
final class MockLocationDetailViewModelFactory: @preconcurrency LocationDetailViewModelFactoryProtocol, @unchecked Sendable {
    func createLocationDetailViewViewModel(_ location: Location?) -> LocationDetailViewModel {
        return LocationDetailViewModel(addLocationUseCase: MockAddLocationsUseCase())
    }
}
