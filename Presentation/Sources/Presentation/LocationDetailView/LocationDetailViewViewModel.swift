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

enum LocationDetailViewViewModelError: Error {
    case invalidCoordinates
    case unknownError
    case cannotSaveServerRecord
}

@MainActor
public final class LocationDetailViewModel: ObservableObject {
    @Published var name: String
    @Published var latitude: String
    @Published var longitude: String
    @Published var isEditable: Bool
    @Published var errorMessage: String?

    private let addLocationUseCase: any AddLocationUseCaseProtocol
    
    let location: Location?
    
    init(location: Location? = nil, editModeEnabled: Bool = false, addLocationUseCase: any AddLocationUseCaseProtocol) {
        self.location = location
        self.addLocationUseCase = addLocationUseCase
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
    
    func saveLocation() async throws -> Location {
        guard isEditable, Double(latitude) != nil, Double(longitude) != nil else {
            errorMessage = NSLocalizedString("invalid_coordinates", comment: "")
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
            errorMessage = NSLocalizedString("add_location_failed", comment: "")
            if let locationsRepositoryError = error as? LocationsRepositoryError {
                switch locationsRepositoryError {
                case .cannotModifyOnlineRecord:
                    throw LocationDetailViewViewModelError.cannotSaveServerRecord
                default:
                    throw LocationDetailViewViewModelError.unknownError
                }
            } else {
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
}
