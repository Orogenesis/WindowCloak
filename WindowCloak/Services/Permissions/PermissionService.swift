//
//  PermissionService.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import AppKit
import ScreenCaptureKit
import AVFoundation

// MARK: - PermissionError

enum PermissionError: LocalizedError {
    case screenRecordingDenied
    case screenRecordingRestricted
    case unknown

    var errorDescription: String? {
        switch self {
        case .screenRecordingDenied:
            return "Screen recording permission denied. Please enable it in System Settings > Privacy & Security > Screen Recording."
        case .screenRecordingRestricted:
            return "Screen recording is restricted on this system."
        case .unknown:
            return "An unknown permission error occurred."
        }
    }
}

// MARK: - PermissionServiceProtocol

protocol PermissionServiceProtocol {
    func checkScreenRecordingPermission() async -> Bool
    func requestScreenRecordingPermission() async -> Bool
    func openSystemPreferences()
}

// MARK: - PermissionService

final class PermissionService: PermissionServiceProtocol {
    /// Checks if screen recording permission is granted.
    /// - Returns: True if permission is granted.
    func checkScreenRecordingPermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            return true
        } catch {
            return false
        }
    }

    /// Requests screen recording permission from the user.
    /// This will trigger the system permission dialog on first request.
    /// - Returns: True if the dialog was likely shown, false if it was already denied.
    func requestScreenRecordingPermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            return true
        } catch {
            // If permission was never requested, this triggers the dialog.
            // If permission was already denied, this fails immediately without showing dialog.
            // We can't distinguish between these cases.
            return false
        }
    }

    func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
