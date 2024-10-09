//
//  LocationDetailView.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import SwiftUI
import Domain

struct LocationDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LocationDetailViewModel
    
    var onSave: (() -> Void)?
    
    init(viewModel: LocationDetailViewModel, onSave: (() -> Void)?) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String.localized("location_detail_view_sections_name_title"))) {
                    TextField(String.localized("location_detail_view_sections_name_title"), text: $viewModel.name)
                        .disabled(!viewModel.isEditable)
                        .accessibility(label: Text(String.localized("location_detail_view_sections_name_title")))
                }
            
                Section(header: (Text(String.localized("location_detail_view_coordinates_section_title")))) {
                    TextField(String.localized("location_detail_view_coordinates_section_fields_latitude_placeholder"), text: $viewModel.latitude)
                        .keyboardType(.decimalPad)
                        .disabled(!viewModel.isEditable)
                        .accessibility(label: Text(String.localized("location_detail_view_coordinates_section_fields_latitude_placeholder")))
                    
                    TextField(String.localized("location_detail_view_coordinates_section_fields_longitude_placeholder"), text: $viewModel.longitude)
                        .keyboardType(.decimalPad)
                        .disabled(!viewModel.isEditable)
                        .accessibility(label: Text(String.localized("location_detail_view_coordinates_section_fields_longitude_placeholder")))
                }
                
                Section(header: (Text(String.localized("location_detail_view_actions_section_title")))) {
                    if viewModel.isEditable {
                        Button(String.localized("location_detaik_view_actions_section_save_title")) {
                            onSavePressed()
                        }
                        .accessibility(label: Text(String.localized("location_detaik_view_actions_section_save_title")))
                    }
                    
                    if viewModel.location != nil {
                        Button(String.localized("location_detail_view_actions_section_wikipedia_link_title")) {
                            viewModel.openWikipedia()
                        }
                        .accessibilityLabel(String.localized("location_detail_view_actions_section_wikipedia_link_title"))
                    }
                }
            
            if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(String.localized("location_detail_view_navigationbar_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String.localized("location_detail_view_navigation_bar_dismiss_title")) {
                        dismiss()
                    }
                    .accessibility(label: Text(String.localized("location_detail_view_navigation_bar_dismiss_title")))
                }
            }
        }
    }
    
    func onSavePressed() {
        Task {
            do {
                _ = try await viewModel.saveLocation()
                dismiss()
                if let onSave = onSave {
                    onSave()
                }
            }
        }
    }
}
