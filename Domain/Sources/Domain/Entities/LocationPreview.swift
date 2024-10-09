//
//  LocationPreview.swift
//  Domain
//
//  Created by Joris Dijkstra on 09/10/2024.
//

import Foundation

public struct LocationPreview: Decodable, Sendable, Identifiable {
    public let id: UUID = UUID()
    public let name: String
    public let longitude: Double
    public let latitude: Double
    
    public init (name: String, longitude: Double, latitude: Double) {
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
    }
    
    enum CodingKeys: CodingKey {
        case name
        case longitude
        case latitude
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
    }
}
