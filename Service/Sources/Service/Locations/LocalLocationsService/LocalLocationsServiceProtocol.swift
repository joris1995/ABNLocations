//
//  LocalLocationsServiceProtocol.swift
//  Service
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Domain
import Foundation

public protocol LocalLocationsServiceProtocol: Sendable {
    func getLocations(_ filter: Predicate<DBLocation>?) async throws -> [Location]
    func createLocation(_ location: Location) async throws -> Location
    func updateLocation(_ location: Location) async throws -> Location
    func deleteLocation(_ location: Location) async throws
}
