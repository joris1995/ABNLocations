//
//  LocationDetailViewViewModel.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Foundation
import UseCase
import Domain
import UIKit
import SwiftUI
import Combine

enum LocationDetailViewViewModelError: Error {
    case invalidCoordinates
    case unknownError
    case cannotUpdateServerRecord
    case noExistingLocation
    case saveFailed(String?)
    case locationNotFound
}

enum AutoCompleteViewModel {
    case noConnection
    case results([LocationPreview])
}

struct LocationDetailViewModelErrorMessage: Identifiable {
    var id: UUID = UUID()
    
    let title: String
    let serverMessage: String?
    
    init(title: String, serverMessage: String? = nil) {
        self.title = title
        self.serverMessage = serverMessage
    }
}

@MainActor
public final class LocationDetailViewModel: ObservableObject {
    @Published var name: String
    @Published var latitude: String
    @Published var longitude: String
    @Published var isEditable: Bool
    @Published var errorMessage: LocationDetailViewModelErrorMessage?
    @Published var autoCompletePreview: AutoCompleteViewModel?

    private let addLocationUseCase: any AddLocationUseCaseProtocol
    private let updateLocationUseCase: any UpdateLocationUseCaseProtocol
    private let autoCompleteUseCase: any LocationsAutoCompleteUseCaseProtocol
    
    let location: Location?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        location: Location? = nil,
        addLocationUseCase: any AddLocationUseCaseProtocol,
        updateloctionUseCase: any UpdateLocationUseCaseProtocol,
        autoCompleteUseCase: any LocationsAutoCompleteUseCaseProtocol
    ) {
        self.location = location
        self.addLocationUseCase = addLocationUseCase
        self.updateLocationUseCase = updateloctionUseCase
        self.autoCompleteUseCase = autoCompleteUseCase
        
        self.isEditable = (location?.source ?? .custom) != .server
        
        if let location = location {
            self.name = location.name
            self.latitude = String(location.latitude)
            self.longitude = String(location.longitude)
        } else {
            self.name = ""
            self.latitude = ""
            self.longitude = ""
        }
    }
    
    // MARK: Handling textfield autocomplete anticipation
    func setupDebounce() {
        $name
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newName in
                // Create a Task to call the async function
                Task { [weak self] in
                    self?.loadSuggestions(text: newName)
                }
            }
            .store(in: &cancellables)
    }
    
    func removeDebounce() {
        cancellables.removeAll()
    }
    
    func saveLocation() async throws(LocationDetailViewViewModelError) -> Location {
        do {
            if let _ = location {
                // Modifying an existing location
                return try await updateLocation()
            } else {
                // Adding a new location
                return try await saveNewLocation()
            }
        } catch {
            switch error {
            case .invalidCoordinates:
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    title: String.localized("alert_title_error"),
                    serverMessage: String.localized("location_detail_view_error_messages_invalid_coordinates")
                )
            case .unknownError:
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    title: String.localized("alert_title_error"),
                    serverMessage: String.localized("error_message_server_error_generic")
                )
            case .cannotUpdateServerRecord:
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    title: String.localized("alert_title_error"),
                    serverMessage: String.localized("location_detail_view_error_messages_cannot_modify_server_record")
                )
            case .noExistingLocation, .locationNotFound:
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    title: String.localized("alert_title_error"),
                    serverMessage: String.localized("location_detail_view_update_location_error_not_found")
                )
            case .saveFailed(let message):
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    title: String.localized("alert_title_error"),
                    serverMessage: String.localized("location_detail_view_actions_section_save_title").appending(" \(message ?? String.localized("labels_general_unknown"))")
                )
            
            }
            
            throw error
        }
    }
    
    // MARK: Logic
    private func saveNewLocation() async throws(LocationDetailViewViewModelError) -> Location {
        guard isEditable, Double(latitude) != nil, Double(longitude) != nil else {
            throw LocationDetailViewViewModelError.invalidCoordinates
        }

        do {
            let locationToSave = location ?? Location(
                id: UUID(),
                name: name,
                latitude: Double(latitude) ?? 0.0,
                longitude: Double(longitude) ?? 0.0,
                source: .custom
            )
            
            let result = try await addLocationUseCase.execute(locationToSave)
            return result
        } catch {
            switch error {
            case .failedToAdd(let message):
                throw .saveFailed(message)
            }
        }
    }
    
    private func updateLocation() async throws(LocationDetailViewViewModelError) -> Location {
        guard let location = location else { throw LocationDetailViewViewModelError.noExistingLocation }
        guard let long = Double(latitude), let lat = Double(longitude) else {
            throw LocationDetailViewViewModelError.invalidCoordinates
        }
        
        guard isEditable && location.source == .custom else {
            throw .cannotUpdateServerRecord
        }
        
        let updatedLocation = Location(id: location.id, name: name, latitude: lat, longitude: long, source: .custom)
        
        do {
            let result = try await self.updateLocationUseCase.execute(updatedLocation)
            return result
        } catch {
            switch error {
            case .cannotModifyServerLocation:
                throw .cannotUpdateServerRecord
            case .updateFailed(let message):
                throw .saveFailed(message)
            case .locationNotFound:
                throw .locationNotFound
            }
        }
    }
    
    func openWikipedia() {
        guard let location = location, let url = URL(string: "wikipedia://places?WMFLocationCoordinates=long=\(location.longitude),lat=\(location.latitude)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            self.errorMessage = LocationDetailViewModelErrorMessage(
                title: String.localized("alert_title_error"),
                serverMessage: String.localized("Cannot open Wikipedia. Please make sure you have the Wikipedia app installed!")
            )
        }
    }
    
    func loadSuggestions(text: String) {
        Task {
            do {
                let suggestions = try await autoCompleteUseCase.execute(with: text)
                self.autoCompletePreview = .results(suggestions)
            } catch let error as LocationsAutoCompleteUseCaseError {
                switch error {
                case .noConnection:
                    self.autoCompletePreview = .noConnection
                case .loadingFailed(let message):
                    self.errorMessage = LocationDetailViewModelErrorMessage(
                        title: String.localized("location_detail_view_error_messages_invalid_response_title"),
                        serverMessage: message
                    )
                }
            }
        }
    }
    
    func onSelectSuggestion(_ suggestion: LocationPreview) {
        self.removeDebounce()
        self.name = suggestion.name
        self.longitude = "\(suggestion.longitude)"
        self.latitude = "\(suggestion.latitude)"
        self.autoCompletePreview = nil
    }
}
