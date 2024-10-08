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

@MainActor
public class LocationsOverviewViewModel: ObservableObject {
    
    @Published var locations: [Location] = []
    @Published var modalPresentationState: LocationsOverviewPresentingEditorState? = nil
 
    private let fetchLocationsUseCase: FetchLocationsUseCaseProtocol
    private let removeLocationUseCase: RemoveLocationUseCaseProtocol
    
    public init(fetchLocationsUseCase: FetchLocationsUseCaseProtocol, removeLocationUseCase: RemoveLocationUseCaseProtocol) {
        self.fetchLocationsUseCase = fetchLocationsUseCase
        self.removeLocationUseCase = removeLocationUseCase
    }
    
    func fetchLocations() {
        Task {
            do {
                let fetchedLocations = try await fetchLocationsUseCase.execute()
                self.locations = fetchedLocations
            } catch {
                // TODO: Handle errors
                print("Error: \(error)")
            }
        }
    }
    
    func removeLocation(_ location: Location) {
        Task {
            do {
                try await removeLocationUseCase.execute(location)
                fetchLocations()
            } catch {
                // TODO: Handle errors
                print("Error: \(error)")
            }
        }
    }
}
