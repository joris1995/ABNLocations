//
//  ServiceError.swift
//  Domain
//
//  Created by Joris Dijkstra on 08/10/2024.
//

public enum ServiceError: Error {
    case invalidURL
    case invalidResponse(String)
    case parsingError(String)
    case networkError(Error)
    case notFound
}
