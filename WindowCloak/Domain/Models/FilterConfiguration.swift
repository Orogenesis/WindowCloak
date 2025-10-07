//
//  FilterConfiguration.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation

// MARK: - FilterConfiguration

struct FilterConfiguration: Codable, Equatable {
    /// Bundle identifiers of applications to hide.
    var hiddenApplications: Set<String>
    /// Whether the shared stream should hide the cursor.
    var hideCursor: Bool = false

    init(hiddenApplications: Set<String> = [], hideCursor: Bool = false) {
        self.hiddenApplications = hiddenApplications
        self.hideCursor = hideCursor
    }

    private enum CodingKeys: String, CodingKey {
        case hiddenApplications
        case hideCursor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hiddenApplications = try container.decodeIfPresent(Set<String>.self, forKey: .hiddenApplications) ?? []
        hideCursor = try container.decodeIfPresent(Bool.self, forKey: .hideCursor) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hiddenApplications, forKey: .hiddenApplications)
        try container.encode(hideCursor, forKey: .hideCursor)
    }
}
