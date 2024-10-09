//
//  RepositoryTestUtils.swift
//  Repository
//
//  Created by Joris Dijkstra on 09/10/2024.
//

import Foundation
import Service

final class MockNetworkMonitor: NetworkServiceProtocol, @unchecked Sendable {
    var hasConnection: Bool = false
    
    init(hasConnection: Bool = false) {
        self.hasConnection = hasConnection
    }
    
    func isConnected() async -> Bool {
        return hasConnection
    }
}
