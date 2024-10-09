//
//  LocationsRepositorError.swift
//  Repository
//
//  Created by Joris Dijkstra on 05/10/2024.
//

public enum LocationsRepositoryFetchError: Error, Equatable {
    case loadingFailed(String?)
}

public enum LocationsRepositoryUpdateError: Error, Equatable {
    case cannotModifyOnlineRecord
    case updateLocationFailed(String?)
}

public enum LocationsRepositoryDeleteError: Error, Equatable {
    case cannotDeleteOnlineRecord
    case deleteRecordFailed(String?)
}

public enum LocationsRepositoryAddError: Error, Equatable {
    case addLocationFailed(String?)
}
