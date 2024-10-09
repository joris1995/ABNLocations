//
//  LocationDetailViewViewModelTests.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import XCTest
import Combine
import Repository
import UIKit
import SwiftUI
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

        func execute(_ location: Location) async throws(AddLocationUseCaseError) -> Location {
            if shouldThrowError {
                throw .failedToAdd("Error")
            }
            self.addedLocation = location
            return location
        }
    }
    
    

    // MARK: - Test saveLocation Success
    func test_saveLocation_when_coordinates_are_valid() async {
        // Given
        let mockAddLocationUseCase = MockAddLocationUseCase()
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddLocationUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
        )
        
        viewModel.name = "Test Location"
        viewModel.latitude = "52.0"
        viewModel.longitude = "4.0"

        var receivedErrorMessage: LocationDetailViewModelErrorMessage? = nil
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
    func test_save_location_when_coordinates_are_invalid() async {
        // Given
        let mockAddLocationUseCase = MockAddLocationUseCase()
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddLocationUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
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
            XCTAssertEqual(viewModel.errorMessage?.serverMessage, String.localized("location_detail_view_error_messages_invalid_coordinates"), "Error message should indicate invalid coordinates")
        }
    }

    // MARK: - Test saveLocation Failure Case
    func test_save_location_when_save_fails() async {
        // Given
        let mockAddLocationUseCase = MockAddLocationUseCase()
        mockAddLocationUseCase.shouldThrowError = true
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddLocationUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
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
            XCTAssertEqual(viewModel.errorMessage?.serverMessage, String.localized("Error"), "Error message should indicate that location saving failed")
            // generic error message, since the error thrown from the mock just says "Error"
        }
    }
    
    // MARK: - Test Autocomplete Debounce Setup
    func test_autocomplete_search_with_connection_successful() {
        // Given
        let mockAddUseCase = MockAddLocationUseCase()
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
        )

        mockAutoCompleteUseCase.mockSuggestions = [LocationPreview(name: "Suggestion 1", longitude: 4.0, latitude: 52.0)]

        let expectation = XCTestExpectation(description: "Wait for autocomplete suggestions to be triggered")

        viewModel.setupDebounce()
        viewModel.$autoCompletePreview
            .dropFirst()
            .sink { autoCompletePreview in
                if case let .results(suggestions) = autoCompletePreview {
                    XCTAssertEqual(suggestions.count, 1, "Autocomplete should return one suggestion")
                    XCTAssertEqual(suggestions.first?.name, "Suggestion 1", "Suggestion name should match the expected value")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.name = "Sug"

        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil")
    }
    
    // MARK: - Test Autocomplete Failure with connection
    func test_autocomplete_search_with_connection_unsuccessful() {
        // Given
        let mockAddUseCase = MockAddLocationUseCase()
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        mockAutoCompleteUseCase.shouldThrowError = true
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
        )

        mockAutoCompleteUseCase.mockSuggestions = [LocationPreview(name: "Suggestion 1", longitude: 4.0, latitude: 52.0)]

        let expectation = XCTestExpectation(description: "Wait for error message to be set")

        viewModel.setupDebounce()
        viewModel.$errorMessage
            .dropFirst()
            .sink { message in
                XCTAssertNotNil(message)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        viewModel.name = "Sug"

        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNil(viewModel.autoCompletePreview, "AutoCompletePreview should be nil")
    }

    // MARK: - Test Autocomplete Failure
    func test_autocomplete_search_without_connection() {
        // Given
        let mockAddUseCase = MockAddLocationUseCase()
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        mockAutoCompleteUseCase.hasConnection = false

        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
        )
        
        let expectation = XCTestExpectation(description: "Wait for autocomplete viewmodel t be triggered")

        viewModel.setupDebounce()
        viewModel.$autoCompletePreview
            .dropFirst() // Ignore initial value
            .sink { autoCompletePreview in
                if case .noConnection = autoCompletePreview {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.loadSuggestions(text: "Sug")

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Test Suggestion Selection
    func test_on_select_suggestion_update_fields() {
        // Given
        let mockAddUseCase = MockAddLocationUseCase()
        let mockAutoCompleteUseCase = MockAutoCompleteUseCase()
        let viewModel = LocationDetailViewModel(
            location: nil,
            editModeEnabled: true,
            addLocationUseCase: mockAddUseCase,
            autoCompleteUseCase: mockAutoCompleteUseCase
        )

        let suggestion = LocationPreview(name: "Selected Suggestion", longitude: 3.0, latitude: 51.0)

        // When
        viewModel.onSelectSuggestion(suggestion)

        // Then
        XCTAssertEqual(viewModel.name, suggestion.name, "ViewModel's name should match the selected suggestion's name")
        XCTAssertEqual(viewModel.latitude, "\(suggestion.latitude)", "ViewModel's latitude should match the selected suggestion's latitude")
        XCTAssertEqual(viewModel.longitude, "\(suggestion.longitude)", "ViewModel's longitude should match the selected suggestion's longitude")
        XCTAssertNil(viewModel.autoCompletePreview, "AutoCompletePreview should be nil after selecting a suggestion")
    }
}
