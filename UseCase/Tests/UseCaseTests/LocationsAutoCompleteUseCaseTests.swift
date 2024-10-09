
import XCTest

import Repository
import Domain

@testable import UseCase

final class LocationsAutoCompleteUseCaseTests: XCTestCase {

    // Test case for a successful fetch of locations
    func text_execte_successful_with_connection() async throws {
        // Given
        let repository = UseCaseTestUtils.provideAutoCompleteRepository(serviceResponseType: .success, hasNetworkConnection: true)
        let useCase = LocationsAutoCompleteUseCase(locationRepository: repository)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await useCase.execute(with: "Test")
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
        let repository = UseCaseTestUtils.provideAutoCompleteRepository(serviceResponseType: .success, hasNetworkConnection: false)
        let useCase = LocationsAutoCompleteUseCase(locationRepository: repository)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await useCase.execute(with: "Test")
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
        let repository = UseCaseTestUtils.provideAutoCompleteRepository(serviceResponseType: .failure, hasNetworkConnection: true)
        let useCase = LocationsAutoCompleteUseCase(locationRepository: repository)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await useCase.execute(with: "Test")
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
        let repository = UseCaseTestUtils.provideAutoCompleteRepository(serviceResponseType: .failure, hasNetworkConnection: false)
        let useCase = LocationsAutoCompleteUseCase(locationRepository: repository)
        
        // When
        var locationsResult: [LocationPreview]?
        var thrownError: Error?
        do {
            locationsResult = try await useCase.execute(with: "Test")
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertNil(locationsResult)
        XCTAssertNotNil(thrownError)
    }
}
