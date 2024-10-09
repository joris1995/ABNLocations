//
//  LocalLocationsServiceProtocol.swift
//  Service
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Domain
import Foundation

public enum LocalLocationsServiceError: Error {
    case notFound
    case fetchFailed(String?)
    case insertFailed(String?)
    case updateFailed(String?)
    case deleteFailed(String?)
}

public protocol LocalLocationsServiceProtocol: Sendable {
    func getLocations(_ filter: Predicate<DBLocation>?) async throws(LocalLocationsServiceError) -> [Location]
    func createLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location
    func updateLocation(_ location: Location) async throws(LocalLocationsServiceError) -> Location
    func deleteLocation(_ location: Location) async throws(LocalLocationsServiceError)
}
