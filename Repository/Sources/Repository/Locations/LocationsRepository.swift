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
    
    public func getLocations() async throws(LocationsRepositoryFetchError) -> [Location] {
        let hasConnection = await networkService.isConnected()
        
        var locations: [Location]
        
        if hasConnection {
            // we load and then remove all existing records sourced from the server
            do {
                try await removeAllOnlineLocations()
            } catch {
                throw LocationsRepositoryFetchError.loadingFailed("Error while cleaning up local data cache: \(error.localizedDescription)")
            }
            
            do {
                // we now load online records, and store them in our local persistence
                var workingObject = try await loadAndStoreOnlineLocations();
                
                // we complete our search by adding custom locations
                let customLocations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "custom" })
                workingObject.append(contentsOf: customLocations)
                
                locations = workingObject
            } catch {
                throw LocationsRepositoryFetchError.loadingFailed("Error while loading online data: \(error.localizedDescription)")
            }
            
        } else {
            // we first remove expired locations from the datastore
            do {
                try await removeExpiredLocations()
            } catch {
                throw LocationsRepositoryFetchError.loadingFailed("Error while cleaning up local data cache: \(error.localizedDescription)")
            }
            do {
                locations = try await localLocationsSerivce.getLocations(nil);
            } catch {
                throw LocationsRepositoryFetchError.loadingFailed("Error while loading local data: \(error.localizedDescription)")
            }
        }
        
        // we sort locations on name upon return.
        return locations.sorted(by: { $0.name < $1.name })
    }
    
    public func createLocation(_ location: Location) async throws(LocationsRepositoryAddError) -> Location {
        do {
            return try await localLocationsSerivce.createLocation(location)
        } catch {
            switch error {
            case .insertFailed(let message):
                throw LocationsRepositoryAddError.addLocationFailed("Error while adding location: \(message ?? "unkown")")
            case .notFound, .fetchFailed, .updateFailed, .deleteFailed:
                throw LocationsRepositoryAddError.addLocationFailed("An unanticipated error occured")
            }
            
        }
    }
    
    public func updateloation(_ location: Location) async throws(LocationsRepositoryUpdateError) -> Location {
        guard location.source == .custom else {
            throw LocationsRepositoryUpdateError.cannotModifyOnlineRecord
        }
        
        do {
            return try await localLocationsSerivce.updateLocation(location)
        } catch let error {
            switch error {
            case .updateFailed(let message):
                throw LocationsRepositoryUpdateError.updateLocationFailed("Error while updating location: \(message ?? "unkown")")
            case .notFound, .fetchFailed, .insertFailed, .deleteFailed:
                throw LocationsRepositoryUpdateError.updateLocationFailed("An unanticipated error occured")
            }
        }
    }
    
    public func deleteLocation(_ location: Location) async throws(LocationsRepositoryDeleteError) {
        guard location.source == .custom else {
            throw LocationsRepositoryDeleteError.cannotDeleteOnlineRecord
        }
        do {
            return try await localLocationsSerivce.deleteLocation(location)
        } catch {
            switch error {
            case .deleteFailed(let message):
                throw LocationsRepositoryDeleteError.deleteRecordFailed("Error while deleting location: \(message ?? "unkown")")
            case .notFound, .fetchFailed, .insertFailed, .updateFailed:
                throw LocationsRepositoryDeleteError.deleteRecordFailed("An unanticipated error occured")
            }
        }
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
