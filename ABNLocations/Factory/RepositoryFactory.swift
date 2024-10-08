//
//  RepositoryFactory.swift
//  ABNLocations
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import SwiftData
import Repository
import Service

protocol LocationsRepositoryFactoryProtocol {
    var modelContainer: ModelContainer { get set }
    init (modelContainer: ModelContainer)
    
    func provideReportRepository() -> LocationsRepository
}

class LocationsRepositoryFactor: LocationsRepositoryFactoryProtocol {
    var modelContainer: ModelContainer {
        didSet {
            sharedRepository = nil
        }
    }
    
    var sharedRepository: LocationsRepository?
    
    required init (modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func provideReportRepository() -> LocationsRepository {
        if let sharedRepository {
            return sharedRepository
        }
        
        let repo = LocationsRepository(
            remoteLocationsSerivce: provideRemoteLocationsService(),
            localLocationsSerivce: providelocalLocationsSerivce(),
            networkService: provideNetworkService())
        
        sharedRepository = repo
        
        return repo
    }
    
    private func provideRemoteLocationsService() -> RemoteLocationsService {
        return RemoteLocationsService(
            configuration: RemoteLocationsServiceConfiguration(
                baseUrl: "https://raw.githubusercontent.com/",
                locationsEndpoint: "abnamrocoesd/assignment-ios/main/locations.json"
            )
        )
    }
    
    private func providelocalLocationsSerivce() -> LocalLocationsService {
        return LocalLocationsService(modelContainer: modelContainer)
    }
    
    private func provideNetworkService() -> NetworkService {
        return NetworkService()
    }
}
