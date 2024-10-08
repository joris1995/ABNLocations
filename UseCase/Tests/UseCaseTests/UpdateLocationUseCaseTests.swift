import XCTest

import Repository
import Domain

@testable import UseCase

final class UpdateLocationUseCaseTests: XCTestCase {
    
    // Given we have an UpdateLocationUseCase
    // When we update a custom location
    // Then we expect to get a valid repsonse
    func test_updateCustomLocation_success() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .success)
        
        let useCase = UpdateLocationUseCase(repository: repo)
        
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
    
    // Given we have an UpdateLocationUseCase
    // When we update a server location
    // Then we expect to get a valid repsonse
    func test_updateServerLocation_failure() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .success)
        
        let useCase = UpdateLocationUseCase(repository: repo)
        
        var returnedLocation: Location?
        var returnedError: Error?
        
        do {
            returnedLocation = try await useCase.execute(Location(id: UUID(), name: "Test", latitude: 1, longitude: 2, source: .server))
        } catch {
            returnedError = error
        }
        
        XCTAssertNotNil(returnedError)
        XCTAssertNil(returnedLocation)
    }
    
    // Given we have an UpdateLocationUseCase
    // When we update a location and this fails
    // Then we expect an error to be thrown
    func test_updateLocation_error() async {
        let repo = UseCaseTestUtils.provideRepository(serviceResponseType: .failure)
                
        let useCase = UpdateLocationUseCase(repository: repo)
        
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
