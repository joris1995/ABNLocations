//
//  ModelContainerFactory.swift
//  ABNLocations
//
//  Created by Joris Dijkstra on 08/10/2024.
//
import SwiftData
import Domain

protocol ModelContainerFactoryProtocol {
    func createModelContainer() -> ModelContainer
}

class ModelContainerFactory: ModelContainerFactoryProtocol {
    func createModelContainer() -> ModelContainer {
        let schema = Schema([
            DBLocation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
