//
//  WindowFilterEngine.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import ScreenCaptureKit

// MARK: - WindowFilterStrategy

protocol WindowFilterStrategy {
    func filter(windows: [WindowInfo], configuration: FilterConfiguration) -> [WindowInfo]
}

// MARK: - DefaultWindowFilterStrategy

final class DefaultWindowFilterStrategy: WindowFilterStrategy {
    func filter(windows: [WindowInfo], configuration: FilterConfiguration) -> [WindowInfo] {
        windows.filter { window in
            // Keep window if app is NOT in hidden list.
            !configuration.hiddenApplications.contains(window.owningApplication.bundleIdentifier) && window.isOnScreen
        }
    }
}

// MARK: - WindowFilterEngine

final class WindowFilterEngine {
    private let strategy: WindowFilterStrategy

    init(strategy: WindowFilterStrategy = DefaultWindowFilterStrategy()) {
        self.strategy = strategy
    }

    func filterWindows(_ windows: [WindowInfo], using configuration: FilterConfiguration) -> [WindowInfo] {
        strategy.filter(windows: windows, configuration: configuration)
    }

    /// Creates SCContentFilter from filtered applications.
    /// - Parameters:
    ///   - applications: All available applications.
    ///   - excludedBundleIds: Bundle IDs to exclude.
    ///   - display: Display to capture.
    /// - Returns: Content filter for screen capture.
    func createContentFilter(
        from applications: [SCRunningApplication],
        excluding excludedBundleIds: Set<String>,
        display: SCDisplay
    ) -> SCContentFilter {
        let appsToExclude = applications.filter { app in
            let bundleId = app.bundleIdentifier
            return excludedBundleIds.contains(bundleId)
        }

        return SCContentFilter(
            display: display,
            excludingApplications: appsToExclude,
            exceptingWindows: []
        )
    }
}
