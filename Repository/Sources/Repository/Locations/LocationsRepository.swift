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
                var workingObject: [Location]
                do {
                    // we first attempt to load locations from the server.
                    workingObject = try await remoteLocationsSerivce.readLocations()
                    
                    // if this was successful, we clean the local cache
                    try await removeAllServerRecords()
                    
                    // now, we store the newly fetched records in our local store as fallback for later
                    for location in workingObject {
                        _ = try await localLocationsSerivce.createLocation(location)
                    }
                } catch {
                    // however, if we fail, we fail silently and fall back to our local cache
                    // TODO: Still let the user know we were not able to connect to the server and we're working with cached data here
                    workingObject = try await loadLocalLocations(sources: [.server])
                }
                
                // we complete our search by adding custom locations
                let customLocations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "custom" })
                workingObject.append(contentsOf: customLocations)
                
                locations = workingObject
            } catch {
                throw LocationsRepositoryFetchError.loadingFailed("Error while loading online data: \(error.localizedDescription)")
            }
            
        } else {
            // we first remove expired locations from the datastore
            locations = try await loadLocalLocations(sources: [.server, .custom])
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
            case .notFound, .fetchFailed, .updateFailed, .removeFailed:
                throw LocationsRepositoryAddError.addLocationFailed("An unanticipated error occured")
            }
            
        }
    }
    
    public func updatelocation(_ location: Location) async throws(LocationsRepositoryUpdateError) -> Location {
        guard location.source == .custom else {
            throw LocationsRepositoryUpdateError.cannotModifyOnlineRecord
        }
        
        do {
            return try await localLocationsSerivce.updateLocation(location)
        } catch let error {
            switch error {
            case .updateFailed(let message):
                throw LocationsRepositoryUpdateError.updateLocationFailed("Error while updating location: \(message ?? "unkown")")
            case .notFound, .fetchFailed, .insertFailed, .removeFailed:
                throw LocationsRepositoryUpdateError.updateLocationFailed("An unanticipated error occured")
            }
        }
    }
    
    public func removeLocation(_ location: Location) async throws(LocationsRepositoryRemoveError) {
        guard location.source == .custom else {
            throw LocationsRepositoryRemoveError.cannotRemoveOnlineRecord
        }
        do {
            return try await localLocationsSerivce.removeLocation(location)
        } catch {
            switch error {
            case .removeFailed(let message):
                throw LocationsRepositoryRemoveError.removeRecordFailed("Error while deleting location: \(message ?? "unkown")")
            case .notFound, .fetchFailed, .insertFailed, .updateFailed:
                throw LocationsRepositoryRemoveError.removeRecordFailed("An unanticipated error occured")
            }
        }
    }
    
    // MARK: Convenience functions
    private func removeAllServerRecords() async throws {
        let locations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "server" })
        for location in locations {
            try await localLocationsSerivce.removeLocation(location)
        }
    }
    
    private func removeExpiredLocations() async throws {
        let expiredLocations = try await localLocationsSerivce.getLocations(#Predicate { $0.sourceRawValue == "server" }).filter { $0.expirationDate ?? Date() < Date() }
                
        for location in expiredLocations {
            try await localLocationsSerivce.removeLocation(location)
        }
    }
    
    private func loadLocalLocations(removeExpiredRecords: Bool = true, sources: [LocationSource]) async throws(LocationsRepositoryFetchError) -> [Location] {
        // we first remove expired locations from the datastore
        if removeExpiredRecords {
            do {
                try await removeExpiredLocations()
            } catch {
                throw LocationsRepositoryFetchError.loadingFailed("Error while cleaning up local data cache: \(error.localizedDescription)")
            }
        }
        
        let rawValues = sources.map(\.rawValue)
        
        do {
            return try await localLocationsSerivce.getLocations(#Predicate { rawValues.contains($0.sourceRawValue) });
        } catch {
            throw (LocationsRepositoryFetchError).loadingFailed("Error while loading local data: \(error.localizedDescription)")
        }
    }
    
}
