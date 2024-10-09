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

    func execute(with query: String) async throws -> [LocationPreview] {
        if !hasConnection {
            throw LocationsAutoCompleteRepositoryError.noConnection
        }
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        
        return mockSuggestions ?? [
            LocationPreview(name: "Test 1", longitude: 1, latitude: 0)
        ]
    }
}
