//
//  WindowFilterEngine.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import ScreenCaptureKit
import CoreGraphics

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
        windows: [SCWindow],
        excluding excludedBundleIds: Set<String>,
        hiddenWindowsByApp: [String: Set<CGWindowID>],
        display: SCDisplay
    ) -> SCContentFilter {
        let appsToExclude = applications.filter { app in
            let bundleId = app.bundleIdentifier
            return excludedBundleIds.contains(bundleId)
        }

        let exceptedWindows = Self.makeExceptedWindows(
            for: excludedBundleIds,
            hiddenWindowsByApp: hiddenWindowsByApp,
            windows: windows
        )

        return SCContentFilter(
            display: display,
            excludingApplications: appsToExclude,
            exceptingWindows: exceptedWindows
        )
    }

    private static func makeExceptedWindows(
        for excludedBundleIds: Set<String>,
        hiddenWindowsByApp: [String: Set<CGWindowID>],
        windows: [SCWindow]
    ) -> [SCWindow] {
        guard !hiddenWindowsByApp.isEmpty else { return [] }

        let windowsByBundle = Dictionary(grouping: windows) { window -> String in
            window.owningApplication?.bundleIdentifier ?? ""
        }

        var exceptedWindows: [SCWindow] = []

        for (bundleId, hiddenWindowIDs) in hiddenWindowsByApp {
            guard excludedBundleIds.contains(bundleId),
                  let bundleWindows = windowsByBundle[bundleId] else { continue }

            let visibleWindows = bundleWindows.filter { scWindow in
                !hiddenWindowIDs.contains(scWindow.windowID) && scWindow.isOnScreen
            }

            exceptedWindows.append(contentsOf: visibleWindows)
        }

        return exceptedWindows
    }
}
