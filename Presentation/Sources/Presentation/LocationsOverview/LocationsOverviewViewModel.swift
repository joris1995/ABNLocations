//
//  LocationsOverviewViewModel.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Foundation
import Domain
import SwiftUI
import UseCase

public struct LocationsOverviewPresentingEditorState {
    public var presentingLocation: Location?
}

struct LocationsOverviewError: Identifiable {
    var id: UUID = UUID()
    var title: String
    var message: String?
    
    init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }
}

@MainActor
public class LocationsOverviewViewModel: ObservableObject {
    
    @Published var locations: [Location] = []
    @Published var modalPresentationState: LocationsOverviewPresentingEditorState? = nil
    @Published var activeError: LocationsOverviewError?
 
    private let fetchLocationsUseCase: FetchLocationsUseCaseProtocol
    private let removeLocationUseCase: RemoveLocationUseCaseProtocol
    private let locationDetailViewViewModelFactory: any LocationDetailViewModelFactoryProtocol

    public init(fetchLocationsUseCase: FetchLocationsUseCaseProtocol, removeLocationUseCase: RemoveLocationUseCaseProtocol, locationDetailViewViewModelFactory: any LocationDetailViewModelFactoryProtocol) {
        self.fetchLocationsUseCase = fetchLocationsUseCase
        self.removeLocationUseCase = removeLocationUseCase
        self.locationDetailViewViewModelFactory = locationDetailViewViewModelFactory
    }
    
    func fetchLocations() {
        Task {
            do {
                let fetchedLocations = try await fetchLocationsUseCase.execute()
                self.locations = fetchedLocations
            } catch let error as FetchLocationsUseCaseError {
                switch error {
                case .fetchFailed(let message):
                    self.activeError = LocationsOverviewError(
                        title: String.localized("locations_overview_error_fetch_failed_title"),
                        message: message
                        )
                }
            }
        }
    }
    
    func removeLocation(_ location: Location) {
        
        // first remove optimistically in place
        if let indexOfLocation = locations.firstIndex(of: location) {
            locations.remove(at: indexOfLocation)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            Task {
                do {
                    try await removeLocationUseCase.execute(location)
                    fetchLocations()
                } catch let error as RemoveLocationUseCaseError {
                    switch error {
                    case .cannotRemoveServerLocation:
                        self.activeError = LocationsOverviewError(
                            title: String.localized("alert_title_error"),
                            message: String.localized("locations_overview_error_cannot_remove_server_location")
                            )
                    case .removingFailed(let message):
                        self.activeError = LocationsOverviewError(
                            title: String.localized("alert_title_error"),
                            message: message
                        )
                    }
                    // also reload locations in case of an error, to ensure the user has a valid representation of the data on their screen
                    fetchLocations()
                }
            }
        }
    }
    
    func createDetailViewViewModel(for location: Location?) -> LocationDetailViewModel {
        return locationDetailViewViewModelFactory.createLocationDetailViewViewModel(location)
    }
}
