import XCTest

import Repository
import Domain

@testable import UseCase

final class FetchLocationsUseCaseTests: XCTestCase {
    
    // Given we have a FetchLocationsUseCase
    // When we load locations and this succeeds
    // Then we expect to get a valid repsonse
    func test_fetchLocatins_success() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .success)
        
        let useCase = FetchLocationsUseCase(repository: repo)
        
        var returnedLocations: [Location]?
        var returnedError: Error?
        
        do {
            returnedLocations = try await useCase.execute()
        } catch {
            returnedError = error
        }
        
        XCTAssertNil(returnedError)
        XCTAssertNotNil(returnedLocations)
    }
    
    // Given we have a FetchLocationsUseCase
    // When we load locations and this fails
    // Then we expect an error to be thrown
    func test_fetchLocatins_error() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .failure)
                
        let useCase = FetchLocationsUseCase(repository: repo)
        
        var returnedLocations: [Location]?
        var returnedError: Error?
        
        do {
            returnedLocations = try await useCase.execute()
        } catch {
            returnedError = error
        }
        
        XCTAssertNotNil(returnedError)
        XCTAssertNil(returnedLocations)
    }
}
