//
//  LocationSource.swift
//  Domain
//
//  Created by Joris Dijkstra on 07/10/2024.
//

public enum LocationSource: String, Codable, Sendable {
    case server = "server"
    case custom = "custom"
}
