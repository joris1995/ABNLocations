import XCTest

import Repository
import Domain

@testable import UseCase

final class AddLocationUseCaseTests: XCTestCase {
    
    // Given we have an AddLocationUseCase
    // When we add a location and this succeeds
    // Then we expect to get a valid repsonse
    func test_addLocation_success() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .success)
        
        let useCase = AddLocationUseCase(repository: repo)
        
        var returnedLocation: Location?
        var returnedError: Error?
        
        do {
            returnedLocation = try await useCase.execute(Location(id: UUID(), name: "Test", latitude: 1, longitude: 2, source: .custom))
        } catch {
            returnedError = error
        }
        
        XCTAssertNil(returnedError)
        XCTAssertNotNil(returnedLocation)
    }
    
    // Given we have an AddLocationUseCase
    // When we add a location and this fails
    // Then we expect an error to be thrown
    func test_addLocation_error() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .failure)
                
        let useCase = AddLocationUseCase(repository: repo)
        
        var returnedLocation: Location?
        var returnedError: Error?
        
        do {
            returnedLocation = try await useCase.execute(Location(id: UUID(), name: "Test", latitude: 1, longitude: 2, source: .custom))
        } catch {
            returnedError = error
        }
        
        XCTAssertNotNil(returnedError)
        XCTAssertNil(returnedLocation)
    }
}
