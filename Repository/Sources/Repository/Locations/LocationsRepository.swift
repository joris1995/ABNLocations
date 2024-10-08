// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftData
import Domain
import Service

public final class LocationsRepository: LocationsRepositoryProtocol {
    
    public let networkService: any NetworkServiceProtocol
    public let remoteLocationsSerivce: any RemoteLocationsServiceProtocol
    public let localLocationsSerivce: any LocalLocationsServiceProtocol
    
    required public init(remoteLocationsSerivce: any RemoteLocationsServiceProtocol, localLocationsSerivce: any LocalLocationsServiceProtocol, networkService: any NetworkServiceProtocol) {
        self.remoteLocationsSerivce = remoteLocationsSerivce
        self.localLocationsSerivce = localLocationsSerivce
        self.networkService = networkService
    }
    
    public func getLocations() async throws -> [Location] {
        let hasConnection = await networkService.isConnected()
        
        var locations: [Location]
        
        if hasConnection {
            // we load and then remove all existing records sourced from the server
            try await removeAllOnlineLocations()
            
            // we now load online records, and store them in our local persistence
            var workingObject = try await loadAndStoreOnlineLocations();
            
            // we complete our search by adding custom locations
            let customLocations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "custom" })
            workingObject.append(contentsOf: customLocations)
            
            locations = workingObject
            
        } else {
            // we first remove expired locations from the datastore
            try await removeExpiredLocations()
            locations = try await localLocationsSerivce.getLocations(nil);
        }
        
        // we sort locations on name upon return.
        return locations.sorted(by: { $0.name < $1.name })
    }
    
    public func createLocation(_ location: Location) async throws -> Location {
        return try await localLocationsSerivce.createLocation(location)
    }
    
    public func updateloation(_ location: Location) async throws -> Location {
        guard location.source == .custom else {
            throw LocationsRepositorError.cannotModifyOnlineRecord
        }
        return try await localLocationsSerivce.updateLocation(location)
    }
    
    public func deleteLocation(_ location: Location) async throws {
        guard location.source == .custom else {
            throw LocationsRepositorError.cannotDeleteOnlineRecord
        }
        return try await localLocationsSerivce.deleteLocation(location)
    }
    
    // MARK: Convenience functions
    func removeAllOnlineLocations() async throws {
        let locations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "server" })
        for location in locations {
            try await localLocationsSerivce.deleteLocation(location)
        }
    }
    
    func loadAndStoreOnlineLocations() async throws -> [Location] {
        let locations = try await remoteLocationsSerivce.readLocations()
        for location in locations {
            _ = try await localLocationsSerivce.createLocation(location)
        }
        
        return locations
    }
    
    func removeExpiredLocations() async throws {
        let expiredLocations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "server" }).filter { $0.expirationDate ?? Date() < Date() }
        
        print("Removing expired locations: ", expiredLocations)
        
        for location in expiredLocations {
            try await localLocationsSerivce.deleteLocation(location)
        }
    }
    
}
