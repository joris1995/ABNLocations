//
//  RemoteLocationsServiceProtocol.swift
//  Service
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Foundation
import Domain

public struct RemoteLocationsServiceConfiguration: Sendable {
    let baseUrl: String
    let locationsEndpoint: String
    
    public init(baseUrl: String, locationsEndpoint: String) {
        self.baseUrl = baseUrl
        self.locationsEndpoint = locationsEndpoint
    }
}

public protocol RemoteLocationsServiceProtocol: Sendable {
    var configuration: RemoteLocationsServiceConfiguration { get }
    
    init(configuration: RemoteLocationsServiceConfiguration)
    
    func readLocations() async throws -> [Location]
}

extension RemoteLocationsServiceProtocol {
    var locationsUrl: URL? {
        return URL.init(string: configuration.baseUrl + configuration.locationsEndpoint)
    }
}
