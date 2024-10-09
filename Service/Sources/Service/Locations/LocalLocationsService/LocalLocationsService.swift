//
//  LocalLocationsService.swift
//  Service
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Domain
import Foundation
import SwiftData
import Foundation

@ModelActor
public actor LocalLocationsService: LocalLocationsServiceProtocol {
    
    var modelContext: ModelContext { modelExecutor.modelContext }
    
    public func getLocations(_ filter: Predicate<DBLocation>? = nil) async throws(LocalLocationsServiceError) -> [Location] {
        var results: [Location]
        do {
            if let filter {
                results =  try modelContext.fetch(FetchDescriptor<DBLocation>(predicate: filter))
                    .map{Location(id: $0.id, name: $0.name, latitude: $0.latitude, longitude: $0.longitude, source: $0.source, expirationDate: $0.expirationDate)}
                
                return results
            }
            results =  try modelContext.fetch(FetchDescriptor<DBLocation>())
                .map{Location(id: $0.id, name: $0.name, latitude: $0.latitude, longitude: $0.longitude, source: $0.source, expirationDate: $0.expirationDate)}
        } catch {
            throw LocalLocationsServiceError.fetchFailed(error.localizedDescription)
        }
        
        return results;
    }
    
    public func createLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location {
        do {
            modelContext.insert(DBLocation(id: location.id, name: location.name, latitude: location.latitude, longitude: location.longitude, source: location.source, expirationDate: location.expirationDate))
            try modelContext.save()
            return location
        } catch {
            throw LocalLocationsServiceError.insertFailed(error.localizedDescription)
        }
    }
    
    public func updateLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location {
        do {
            guard let existingRecord = try? modelContext.fetch(FetchDescriptor<DBLocation>()).filter({$0.id == location.id}).first else {
                throw LocalLocationsServiceError.notFound
            }
            
            existingRecord.latitude = location.latitude
            existingRecord.longitude = location.longitude
            existingRecord.name = location.name
            
            try modelContext.save()
            
            return Location(id: existingRecord.id, name: existingRecord.name, latitude: existingRecord.latitude, longitude: existingRecord.longitude, source: existingRecord.source, expirationDate: existingRecord.expirationDate)
        } catch {
            throw LocalLocationsServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    public func deleteLocation(_ location: Location) async throws(LocalLocationsServiceError) {
        do {
            let locationId = location.id
            try modelContext.delete(model: DBLocation.self, where: #Predicate { $0.id == locationId })
            try modelContext.save()
        } catch {
            throw LocalLocationsServiceError.deleteFailed(error.localizedDescription)
        }
    }
}
