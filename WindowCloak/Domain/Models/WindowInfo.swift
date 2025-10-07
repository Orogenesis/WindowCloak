//
//  WindowInfo.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import ScreenCaptureKit

// MARK: - WindowInfo

struct WindowInfo: Identifiable, Hashable {
    let id: CGWindowID
    let title: String
    let owningApplication: AppInfo
    let frame: CGRect
    let layer: Int
    let isOnScreen: Bool

    /// Creates a WindowInfo from a SCWindow.
    init(from scWindow: SCWindow) {
        self.id = scWindow.windowID
        self.title = scWindow.title ?? "Untitled"
        self.owningApplication = AppInfo(from: scWindow.owningApplication)
        self.frame = scWindow.frame
        self.layer = scWindow.windowLayer
        self.isOnScreen = scWindow.isOnScreen
    }

    init(
        id: CGWindowID,
        title: String,
        owningApplication: AppInfo,
        frame: CGRect,
        layer: Int,
        isOnScreen: Bool
    ) {
        self.id = id
        self.title = title
        self.owningApplication = owningApplication
        self.frame = frame
        self.layer = layer
        self.isOnScreen = isOnScreen
    }
}
