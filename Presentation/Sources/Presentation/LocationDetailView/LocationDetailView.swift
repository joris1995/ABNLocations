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
                    TextField(String.localized("location_detail_view_sections_name_title"), text: $viewModel.name, onEditingChanged: { editing in
                        if (editing) {
                            viewModel.setupDebounce()
                        }})
                        .disabled(!viewModel.isEditable)
                        .accessibilityLabel( String.localized("location_detail_view_sections_name_title"))
                }
                
                if let viewModel = viewModel.autoCompletePreview {
                    autoCompleteSection(viewModel)
                } else {
                    coordinatesView
                }
                
                Section(header: (Text(String.localized("location_detail_view_actions_section_title")))) {
                    if viewModel.isEditable {
                        Button(String.localized("location_detail_view_actions_section_save_title")) {
                            onSavePressed()
                        }
                        .accessibilityLabel(String.localized("location_detail_view_actions_section_save_title"))
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
                        Text(errorMessage.localizedKey)
                            .foregroundColor(.red)
                        
                        if let serverMessage = errorMessage.serverMessage {
                            Text(serverMessage)
                        }
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
                    .accessibilityLabel(String.localized("location_detail_view_navigation_bar_dismiss_title"))
                }
            }
        }
    }
    
    func autoCompleteSection(_ viewmodel: AutoCompleteViewModel) -> some View {
        return Section(header: (Text(String.localized("location_detail_view_autocomplete_section_title")))) {
            switch viewmodel {
            case .results(let results):
                List(results) { result in
                    Button(result.name) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.onSelectSuggestion(result)
                    }
                    .accessibilityLabel(result.name)
                }
            case .noConnection:
                Text(String.localized("location_detail_view_autocomplete_section_no_connection_title"))
                    .accessibilityLabel(String.localized("location_detail_view_autocomplete_section_no_connection_title"))
            }
        }.accessibilityLabel( String.localized("location_detail_view_autocomplete_section_title"))
    }
    
    var coordinatesView: some View {
        return Section(header: (Text(String.localized("location_detail_view_coordinates_section_title")))) {
            TextField(String.localized("location_detail_view_coordinates_section_fields_latitude_placeholder"), text: $viewModel.latitude)
                .keyboardType(.decimalPad)
                .disabled(!viewModel.isEditable)
                .accessibilityLabel( String.localized("location_detail_view_coordinates_section_fields_latitude_placeholder"))
            
            TextField(String.localized("location_detail_view_coordinates_section_fields_longitude_placeholder"), text: $viewModel.longitude)
                .keyboardType(.decimalPad)
                .disabled(!viewModel.isEditable)
                .accessibilityLabel(String.localized("location_detail_view_coordinates_section_fields_longitude_placeholder"))
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
