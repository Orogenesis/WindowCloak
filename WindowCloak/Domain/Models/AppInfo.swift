//
//  AppInfo.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import ScreenCaptureKit
import AppKit

// MARK: - AppInfo

struct AppInfo: Identifiable, Hashable, Codable {
    let bundleIdentifier: String
    let applicationName: String
    let processID: pid_t

    var id: String { bundleIdentifier }

    /// Creates an AppInfo from a SCRunningApplication.
    init(from scApp: SCRunningApplication?) {
        self.bundleIdentifier = scApp?.bundleIdentifier ?? "unknown"
        self.applicationName = scApp?.applicationName ?? "Unknown"
        self.processID = scApp?.processID ?? -1
    }

    init(bundleIdentifier: String, applicationName: String, processID: pid_t) {
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.processID = processID
    }

    /// Gets the application icon.
    func getIcon() -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
      
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
