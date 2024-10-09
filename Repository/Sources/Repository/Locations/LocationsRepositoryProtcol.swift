//
//  LocationsRepositoryProtcol.swift
//  Repository
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Domain
import Service

public protocol LocationsRepositoryProtocol: Sendable {
    
    var networkService: NetworkServiceProtocol { get }
    var remoteLocationsSerivce: RemoteLocationsServiceProtocol { get }
    var localLocationsSerivce: LocalLocationsServiceProtocol { get }
    
    init(remoteLocationsSerivce: RemoteLocationsServiceProtocol, localLocationsSerivce: LocalLocationsServiceProtocol, networkService: NetworkServiceProtocol)
    
    func getLocations() async throws(LocationsRepositoryFetchError) -> [Location]
    func createLocation(_ location: Location) async throws(LocationsRepositoryAddError) -> Location
    func updatelocation(_ location: Location) async throws(LocationsRepositoryUpdateError) -> Location
    func removeLocation(_ location: Location) async throws(LocationsRepositoryRemoveError)
}
