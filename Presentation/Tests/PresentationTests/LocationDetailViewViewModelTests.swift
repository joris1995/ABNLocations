//
//  LocationDetailViewViewModelTests.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import XCTest
import Combine
import UIKit
import Domain
import UseCase
@testable import Presentation


@MainActor
final class LocationDetailViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // Mock implementation of the AddLocationUseCaseProtocol
    final class MockAddLocationUseCase: AddLocationUseCaseProtocol, @unchecked Sendable {
        var shouldThrowError: Bool = false
        var addedLocation: Location?

        func execute(_ location: Location) async throws -> Location {
            if shouldThrowError {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            self.addedLocation = location
            return location
        }
    }

    // MARK: - Test saveLocation Success
    func test_saveLocation_whenCoordinatesAreValid_shouldSaveSuccessfully() async {
        // Given
        let mockUseCase = MockAddLocationUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockUseCase
        )
        viewModel.name = "Test Location"
        viewModel.latitude = "52.0"
        viewModel.longitude = "4.0"

        var receivedErrorMessage: String? = nil
        viewModel.$errorMessage
            .sink { errorMessage in
                receivedErrorMessage = errorMessage
            }
            .store(in: &cancellables)

        // When
        do {
            let savedLocation = try await viewModel.saveLocation()

            // Then
            XCTAssertNil(receivedErrorMessage, "Error message should remain nil on successful save")
            XCTAssertEqual(savedLocation.name, "Test Location", "The location should be saved successfully")
            XCTAssertEqual(savedLocation.latitude, 52.0, "The latitude of the saved location should be correct")
            XCTAssertEqual(savedLocation.longitude, 4.0, "The longitude of the saved location should be correct")
        } catch {
            XCTFail("Expected saveLocation to succeed, but it failed with error: \(error)")
        }
    }

    // MARK: - Test saveLocation Invalid Coordinates
    func test_saveLocation_whenCoordinatesAreInvalid_shouldSetErrorMessage() async {
        // Given
        let mockUseCase = MockAddLocationUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockUseCase
        )
        viewModel.name = "Test Location"
        viewModel.latitude = "invalid_latitude"
        viewModel.longitude = "invalid_longitude"

        // When
        do {
            _ = try await viewModel.saveLocation()
            XCTFail("Expected saveLocation to fail due to invalid coordinates, but it succeeded.")
        } catch {
            // Then
            XCTAssertEqual(viewModel.errorMessage, NSLocalizedString("invalid_coordinates", comment: ""), "Error message should indicate invalid coordinates")
        }
    }

    // MARK: - Test saveLocation Failure Case
    func test_saveLocation_whenSaveFails_shouldSetErrorMessage() async {
        // Given
        let mockUseCase = MockAddLocationUseCase()
        mockUseCase.shouldThrowError = true
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockUseCase
        )
        viewModel.name = "Test Location"
        viewModel.latitude = "52.0"
        viewModel.longitude = "4.0"

        // When
        do {
            _ = try await viewModel.saveLocation()
            XCTFail("Expected saveLocation to fail with an error, but it succeeded.")
        } catch {
            // Then
            XCTAssertEqual(viewModel.errorMessage, NSLocalizedString("add_location_failed", comment: ""), "Error message should indicate that location saving failed")
        }
    }
}
