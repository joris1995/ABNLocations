//
//  LocationsOverview.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import SwiftUI
import UseCase
import Service
import Repository
import Domain

public struct LocationsOverview: View {
    @StateObject private var viewModel: LocationsOverviewViewModel
    
    public init(viewModel: LocationsOverviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.locations) { location in
                    Button(action: {
                        viewModel.modalPresentationState = LocationsOverviewPresentingEditorState(presentingLocation: location)
                    }) {
                        LocationRow(location: location)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(action: {
                            viewModel.removeLocation(location)
                        }) {
                            Label(String.localized("locations_overview_list_item_actions_remove_title"), systemImage: "trash")
                        }
                    }
                    .accessibilityLabel(location.name)
                }
            }
            .refreshable {
                viewModel.fetchLocations()
            }
            .navigationTitle(String.localized("locations_overview_navigationbar_title"))
            .accessibilityLabel(String.localized("locations_overview_navigationbar_title"))
            .navigationBarItems(trailing:
                Button(action: {
                // Set modalPresentationState with presentingLocation as nil
                viewModel.modalPresentationState = .init(presentingLocation: nil)
            }) {
                Image(systemName: "plus")
                    .imageScale(.large)
            }.accessibilityLabel(String.localized("locations_overview_add_button_accessibility_label"))
            )
            .sheet(isPresented: .init(get: { viewModel.modalPresentationState != nil}, set: { _ in viewModel.modalPresentationState = nil }) ) {
                LocationDetailView(viewModel: viewModel.createDetailViewViewModel(for: viewModel.modalPresentationState?.presentingLocation)) {
                    viewModel.fetchLocations()
                }
            }
        }.onAppear {
            viewModel.fetchLocations()
        }
    }
}
