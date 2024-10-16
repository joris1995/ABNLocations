//
//  LocationsOverview.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import SwiftUI
import UseCase
import Service
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
                        Button(role: .destructive, action: {
                            withAnimation {
                                viewModel.removeLocation(location)
                            }
                        }) {
                            Label(String.localized("locations_overview_list_item_actions_remove_title"), systemImage: "trash")
                        }
                    }
                    .accessibilityLabel(location.name)
                }
            }
            .refreshable {
                withAnimation {
                    viewModel.fetchLocations()
                }
            }
            .navigationTitle(String.localized("locations_overview_navigationbar_title"))
            .accessibilityLabel(String.localized("locations_overview_navigationbar_title"))
            .navigationBarItems(trailing:
                Button(action: {
                viewModel.modalPresentationState = .init(presentingLocation: nil)
            }) {
                Image(systemName: "plus")
                    .imageScale(.large)
            }.accessibilityLabel(String.localized("locations_overview_add_button_accessibility_label"))
            ).alert(item: $viewModel.activeError) { errorMessage in
                Alert(
                    title: Text(errorMessage.title),
                    message: Text(errorMessage.message ?? ""),
                    dismissButton: .default(Text(String.localized("alert_buttons_dismiss")), action: {
                        viewModel.activeError = nil
                    })
                )
            }
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
