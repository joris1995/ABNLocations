//
//  ContentView.swift
//  ABNLocations
//
//  Created by Joris Dijkstra on 04/10/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    

    var body: some View {
        HStack {
            
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
}
