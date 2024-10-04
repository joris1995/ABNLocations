//
//  Item.swift
//  ABNLocations
//
//  Created by Joris Dijkstra on 04/10/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
