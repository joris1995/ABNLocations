// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Domain

public final class RemoteLocationsService: RemoteLocationsServiceProtocol {
    public let configuration: RemoteLocationsServiceConfiguration
    
    required public init(configuration: RemoteLocationsServiceConfiguration) {
        self.configuration = configuration
    }
    
    public func readLocations() async throws(RemoteLocationsServiceError) -> [Location] {
        do {
            guard let url = locationsUrl else {
                throw RemoteLocationsServiceError.invalidURL
            }
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check if the response is valid (status code 200)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw RemoteLocationsServiceError.invalidResponse("Invalid response:")
            }
            
            struct LocationResponse: Decodable {
                let locations: [Location]
                
                enum CodingKeys: CodingKey {
                    case locations
                }
                
                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.locations = try container.decode([Location].self, forKey: .locations)
                }
            }
            
            // Decode the data into an array of Location models
            // We set a placeholder expiration date 
            let locationsResponse = try JSONDecoder().decode(LocationResponse.self, from: data)
            let decodedLocations = locationsResponse.locations.map {
                return Location(id: $0.id, name: $0.name, latitude: $0.latitude, longitude: $0.longitude, source: .server, expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()))
            }
            
            return decodedLocations
        } catch let error as DecodingError {
            throw RemoteLocationsServiceError.parsingError(error.errorDescription ?? "")
        } catch {
            throw RemoteLocationsServiceError.networkError(error)
        }
    }
}
