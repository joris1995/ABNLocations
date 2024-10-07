//
//  NetworkService.swift
//  Service
//
//  Created by Joris Dijkstra on 05/10/2024.
//

public protocol NetworkServiceProtocol: Sendable {
    func isConnected() async -> Bool
}
