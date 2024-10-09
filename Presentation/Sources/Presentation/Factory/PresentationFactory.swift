//
//  ViewModelFactory.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Repository
import UseCase
import Service
import Domain
import SwiftData

public protocol LocationsOverviewViewModelFactory {
    func createLocationsOverviewViewModel() -> LocationsOverviewViewModel
}

public protocol LocationDetailViewModelFactoryProtocol {
    func createLocationDetailViewViewModel(_ location: Location?) -> LocationDetailViewModel
}

public protocol PresentationFactoryProtocol: LocationsOverviewViewModelFactory {
    var repository: LocationsRepositoryProtocol { get }
}

@MainActor
public class PresentationFactory: @preconcurrency PresentationFactoryProtocol, @preconcurrency LocationDetailViewModelFactoryProtocol {
    
    public var repository: any LocationsRepositoryProtocol
    
    public init(locationsRepository: LocationsRepositoryProtocol) {
        self.repository = locationsRepository
    }
    
    public func createLocationsOverviewViewModel() -> LocationsOverviewViewModel {
        return LocationsOverviewViewModel(
            fetchLocationsUseCase: FetchLocationsUseCase(repository: repository),
            removeLocationUseCase: RemoveLocationUseCase(repository: repository), locationDetailViewViewModelFactory: self
        )
    }
    
    public func createLocationDetailViewViewModel(_ location: Location?) -> LocationDetailViewModel {
        return LocationDetailViewModel(
            location: location,
            editModeEnabled: (location?.source ?? .custom) == .custom,
            addLocationUseCase:
                AddLocationUseCase(
                    repository: repository
                ),
            updateloctionUseCase:
                UpdateLocationUseCase(
                    repository: repository
                ),
            autoCompleteUseCase:
                LocationsAutoCompleteUseCase(
                    locationRepository: LocationsAutoCompleteRepository(
                        autocompleteService: LocationsAutocompleteService(),
                        networkService: NetworkService()
                    )
                )
            )
    }
}
