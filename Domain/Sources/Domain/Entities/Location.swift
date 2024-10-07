//
//  Location.swift
//  Domain
//
//  Created by Joris Dijkstra on 07/10/2024.
//

import Foundation

public struct Location: Sendable, Decodable, Identifiable {
    
    public let id: UUID
    
    public let name: String
    public let latitude: Double
    public let longitude: Double
    
    public let source: LocationSource
    public let expirationDate: Date?
    
    public init(id: UUID, name: String, latitude: Double, longitude: Double, source: LocationSource, expirationDate: Date? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.expirationDate = expirationDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .lat) ?? 0
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .long) ?? 0
        self.source = .server
        self.expirationDate = nil
    }
    
    // Define CodingKeys enum to map properties to keys
    private enum CodingKeys: String, CodingKey {
        case name
        case lat
        case long
    }
}
