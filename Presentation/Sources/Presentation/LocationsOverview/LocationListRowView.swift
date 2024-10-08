//
//  LocationListRowView.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Domain
import SwiftUI

public struct LocationRow: View {
    let location: Location

    public var body: some View {
        VStack(alignment: .leading) {
            Text(location.name)
                .font(.headline)
                .accessibility(label: Text(NSLocalizedString("location_name", comment: "")))
            Text("Lat: \(location.latitude), Lon: \(location.longitude)")
                .font(.subheadline)
                .accessibility(label: Text("\(location.latitude), \(location.longitude)"))
        }
    }
}
