//
//  NetworkService.swift
//  Service
//
//  Created by Joris Dijkstra on 05/10/2024.
//

import Network
import Foundation

public final class NetworkService: NetworkServiceProtocol {
    
    public init() {}
    
    public func isConnected() async -> Bool {
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue.global()
            
            // Start the monitor and listen on the global queue
            monitor.start(queue: queue)
            
            // Set up the initial network status check
            if monitor.currentPath.status == .satisfied {
                continuation.resume(returning: true)  // Connection is available
                monitor.cancel()  // Stop the monitor immediately
            } else {
                // Listen for network changes and resume continuation when status changes
                monitor.pathUpdateHandler = { path in
                    continuation.resume(returning: path.status == .satisfied)
                    monitor.cancel()  // Stop the monitor after we have the result
                }
            }
        }
    }
}
