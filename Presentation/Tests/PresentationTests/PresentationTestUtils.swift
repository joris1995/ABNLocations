//
//  PresentationTestUtils.swift
//  Presentation
//
//  Created by Joris Dijkstra on 09/10/2024.
//

import Foundation
import UseCase
import Domain
import Repository

final class MockAutoCompleteUseCase: LocationsAutoCompleteUseCaseProtocol, @unchecked Sendable {
    var shouldThrowError: Bool = false
    var hasConnection: Bool = true
    
    var mockSuggestions: [LocationPreview]?

    func execute(with query: String) async throws(LocationsAutoCompleteUseCaseError) -> [LocationPreview] {
        if !hasConnection {
            throw LocationsAutoCompleteUseCaseError.noConnection
        }
        if shouldThrowError {
            throw .loadingFailed("TestError")
        }
        
        return mockSuggestions ?? [
            LocationPreview(name: "Test 1", longitude: 1, latitude: 0)
        ]
    }
}
