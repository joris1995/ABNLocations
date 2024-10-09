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

public enum LocationsRepositoryRemoveError: Error, Equatable {
    case cannotRemoveOnlineRecord
    case removeRecordFailed(String?)
}

public enum LocationsRepositoryAddError: Error, Equatable {
    case addLocationFailed(String?)
}
