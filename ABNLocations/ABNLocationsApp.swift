//
//  ABNLocationsApp.swift
//  ABNLocations
//
//  Created by Joris Dijkstra on 04/10/2024.
//

import SwiftUI
import SwiftData
import Domain
import Presentation

@main
struct ABNLocationsApp: App {
    var presentationFactory: any PresentationFactoryProtocol
    
    init() {
        
        var modelContainerFactory: ModelContainerFactoryProtocol
        modelContainerFactory = ModelContainerFactory()
        
        let locationsRepository = LocationsRepositoryFactor(modelContainer: modelContainerFactory.createModelContainer()).provideReportRepository()
        
        self.presentationFactory = PresentationFactory(locationsRepository: locationsRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            LocationsOverview(
                viewModel: presentationFactory.createLocationsOverviewViewModel()
            )
        }
    }
}
