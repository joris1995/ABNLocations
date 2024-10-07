//
//  DBLocation.swift
//  Domain
//
//  Created by Joris Dijkstra on 07/10/2024.
//

import Foundation
import SwiftData

@Model
public class DBLocation {
    
    @Attribute(.unique) public var id: UUID
    
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var expirationDate: Date?
    
    // setup for conveniently storing the raw value of LocationSource (string), while being able to work with the enum throughout the rest of the code. We'll need this for querying using Predicates.
    public var sourceRawValue: String
    public var source: LocationSource {
        get {
            LocationSource(rawValue: sourceRawValue) ?? .custom
        }
        set {
            sourceRawValue = newValue.rawValue
        }
    }
    
    public init(id: UUID?, name: String, latitude: Double, longitude: Double, source: LocationSource, expirationDate: Date? = nil) {
        self.id = id ?? UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.sourceRawValue = source.rawValue
        self.expirationDate = expirationDate
    }
}
