//
//  FilterConfiguration.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import CoreGraphics

// MARK: - FilterConfiguration

struct FilterConfiguration: Codable, Equatable {
    /// Bundle identifiers of applications to hide.
    var hiddenApplications: Set<String>
    /// Windows of hidden applications that should remain hidden specifically. When absent,
    /// the entire application is hidden.
    var hiddenWindowsByApp: [String: Set<CGWindowID>]
    /// Whether the shared stream should hide the cursor.
    var hideCursor: Bool = false
    /// Whether the application should appear in the Dock.
    var showDockIcon: Bool = true

    init(
        hiddenApplications: Set<String> = [],
        hiddenWindowsByApp: [String: Set<CGWindowID>] = [:],
        hideCursor: Bool = false,
        showDockIcon: Bool = true
    ) {
        self.hiddenApplications = hiddenApplications
        self.hiddenWindowsByApp = hiddenWindowsByApp
        self.hideCursor = hideCursor
        self.showDockIcon = showDockIcon
    }

    private enum CodingKeys: String, CodingKey {
        case hiddenApplications
        case hideCursor
        case showDockIcon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hiddenApplications = try container.decodeIfPresent(Set<String>.self, forKey: .hiddenApplications) ?? []
        hideCursor = try container.decodeIfPresent(Bool.self, forKey: .hideCursor) ?? false
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? true
        hiddenWindowsByApp = [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hiddenApplications, forKey: .hiddenApplications)
        try container.encode(hideCursor, forKey: .hideCursor)
        try container.encode(showDockIcon, forKey: .showDockIcon)
    }
}

// MARK: - Hidden Window Helpers

extension FilterConfiguration {
    /// Returns the hidden window identifiers for the given bundle identifier.
    func hiddenWindows(for bundleIdentifier: String) -> Set<CGWindowID> {
        hiddenWindowsByApp[bundleIdentifier] ?? []
    }

    /// Returns a copy of the configuration with unknown window identifiers removed.
    func pruningHiddenWindows(with availableWindowIds: Set<CGWindowID>) -> FilterConfiguration {
        var copy = self
        copy.hiddenWindowsByApp = hiddenWindowsByApp.mapValues { storedSet in
            storedSet.intersection(availableWindowIds)
        }
      
        return copy
    }
}
