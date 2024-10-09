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
    case cannotSaveServerRecord
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
                title: String.localized("alert_title_error"),
                serverMessage: String.localized("location_detail_view_error_messages_invalid_coordinates")
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
            switch error {
            case .failedToAdd(let message):
                self.errorMessage = LocationDetailViewModelErrorMessage(
                    title: String.localized("alert_title_error"),
                    serverMessage: message
                )
                throw error
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
