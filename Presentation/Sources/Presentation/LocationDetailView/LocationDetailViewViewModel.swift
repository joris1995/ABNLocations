//
//  LocationDetailViewViewModel.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Foundation
import UseCase
import Domain
import Repository
import UIKit
import SwiftUI
import Combine

enum LocationDetailViewViewModelError: Error {
    case invalidCoordinates
    case unknownError
    case cannotSaveServerRecord
}

enum AutoCompleteViewModel {
    case noConnection
    case results([LocationPreview])
}

struct LocationDetailViewModelErrorMessage {
    let localizedKey: LocalizedStringKey
    let serverMessage: String?
    
    init(localizedKey: LocalizedStringKey, serverMessage: String? = nil) {
        self.localizedKey = localizedKey
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
    private let autoCompleteUseCase: any LocationsAutoCompleteUseCaseProtocol
    
    let location: Location?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(location: Location? = nil, editModeEnabled: Bool = false, addLocationUseCase: any AddLocationUseCaseProtocol, autoCompleteUseCase: any LocationsAutoCompleteUseCaseProtocol) {
        self.location = location
        self.addLocationUseCase = addLocationUseCase
        self.autoCompleteUseCase = autoCompleteUseCase
        
        self.isEditable = editModeEnabled
        
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
    
    // MARK: Logic
    func saveLocation() async throws -> Location {
        guard isEditable, Double(latitude) != nil, Double(longitude) != nil else {
            self.errorMessage = LocationDetailViewModelErrorMessage(
                localizedKey: String.localized("location_detail_view_error_messages_invalid_coordinates")
            )
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
            // TODO: Fix error handling, this is messy
            if let receivevError = error as? LocationDetailViewViewModelError {
                switch receivevError {
                case .invalidCoordinates:
                    self.errorMessage = LocationDetailViewModelErrorMessage(
                        localizedKey: String.localized("location_detail_view_error_messages_invalid_coordinates")
                    )
                default:
                    self.errorMessage = LocationDetailViewModelErrorMessage(
                        localizedKey: String.localized("location_detail_view_autocomplete_section_load_failure_message_generic")
                    )
                }
            }
            
            if let locationsRepositoryError = error as? LocationsRepositoryError {
                switch locationsRepositoryError {
                case .cannotModifyOnlineRecord:
                    self.errorMessage = LocationDetailViewModelErrorMessage(
                        localizedKey: String.localized("location_detail_view_actions_section_save_title")
                    )
                    throw LocationDetailViewViewModelError.cannotSaveServerRecord
                default:
                    self.errorMessage = LocationDetailViewModelErrorMessage(
                        localizedKey: String.localized("location_detail_view_autocomplete_section_load_failure_message_generic")
                    )
                    throw LocationDetailViewViewModelError.unknownError
                }
            } else {
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    localizedKey: String.localized("location_detail_view_autocomplete_section_load_failure_message_generic")
                )
                throw LocationDetailViewViewModelError.unknownError
            }
        }
    }
    
    func openWikipedia() {
        guard let location = location, let url = URL(string: "wikipedia://places?WMFLocationCoordinates=long=\(location.longitude),lat=\(location.latitude)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func loadSuggestions(text: String) {
        Task {
            do {
                let suggestions = try await autoCompleteUseCase.execute(with: text)
                self.autoCompletePreview = .results(suggestions)
            } catch {
                if let autoCompleteError = error as? LocationsAutoCompleteRepositoryError {
                    switch autoCompleteError {
                    case .noConnection:
                        self.autoCompletePreview = .noConnection
                    case .invalidResponse(let message):
                        self.errorMessage = LocationDetailViewModelErrorMessage(
                            localizedKey: String.localized("location_detail_view_error_messages_invalid_response_title"),
                            serverMessage: message
                        )
                    }
                } else {
                    // TODO: Improve error handling
                    self.errorMessage = LocationDetailViewModelErrorMessage(
                        localizedKey: String.localized("location_detail_view_autocomplete_section_load_failure_message_generic")
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
