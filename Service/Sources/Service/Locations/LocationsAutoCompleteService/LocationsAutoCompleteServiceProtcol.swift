//
//  LocationsAutoCompleteServiceProtcol.swift
//  Service
//
//  Created by Joris Dijkstra on 09/10/2024.
//

import Foundation
import Domain

public protocol LocationsAutocompleteServiceProtocol: Sendable {
    func loadSuggestions(for query: String) async throws -> [LocationPreview]
}
