//
//  String+localized.swift
//  Presentation
//
//  Created by Joris Dijkstra on 08/10/2024.
//

import Foundation
import SwiftUI

public extension String {
    static func localized(_ key: String) -> String {
        return NSLocalizedString(key, tableName: nil, bundle: .module, value: "", comment: "")
    }
}
