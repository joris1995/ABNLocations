//
//  RemoveLcationUseCaseTests.swift
//  UseCase
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import XCTest

import Repository
import Service
import Domain

@testable import UseCase

final class RemoveLocationUseCaseTests: XCTestCase {
    
    // Given we have an AddLocationUseCase
    // When we remove a custom location and remove this
    // Then we expect to get a valid repsonse
    func test_removeCustomLocation_success() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .success)
        
        let useCase = RemoveLocationUseCase(repository: repo)
        
        var returnedError: Error?
        
        do {
            try await useCase.execute(Location(id: UUID(), name: "Test", latitude: 1, longitude: 2, source: .custom))
        } catch {
            returnedError = error
        }
        
        XCTAssertNil(returnedError)
    }
    
    // Given we have an AddLocationUseCase
    // When we remove a server location and remove this
    // Then we expect to get an error repsonse
    func test_removeServerLocation_error() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .success)
        
        let useCase = RemoveLocationUseCase(repository: repo)
        
        var returnedError: Error?
        
        do {
            try await useCase.execute(Location(id: UUID(), name: "Test", latitude: 1, longitude: 2, source: .server))
        } catch {
            returnedError = error
        }
        
        XCTAssertNotNil(returnedError)
        guard let serviceError = returnedError as? LocationsRepositorError else {
            XCTFail("Unexpected error type returned")
            return
        }
        XCTAssert(serviceError == LocationsRepositorError.cannotDeleteOnlineRecord)
    }
    
    // Given we have an AddLocationUseCase
    // When we remove a location and this fails
    // Then we expect an error to be thrown
    func test_removeLocation_error() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .failure)
                
        let useCase = RemoveLocationUseCase(repository: repo)
        
        var returnedError: Error?
        
        do {
            try await useCase.execute(Location(id: UUID(), name: "Test", latitude: 1, longitude: 2, source: .custom))
        } catch {
            returnedError = error
        }
        
        XCTAssertNotNil(returnedError)
    }
}
