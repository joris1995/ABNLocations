//
//  LocationsAutoCompleteRepositoryError.swift
//  Repository
//
//  Created by Joris Dijkstra on 06/10/2024.
//

public enum LocationsAutoCompleteRepositoryError: Error {
    case invalidResponse(String)
    case noConnection
}
