//
//  DockIconController.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import AppKit

// MARK: - DockIconControlling

@MainActor
protocol DockIconControlling: AnyObject {
    /// Applies the requested Dock visibility by adjusting the app's activation policy.
    func updateVisibility(showDockIcon: Bool)
}

// MARK: - DockIconController

@MainActor
final class DockIconController: DockIconControlling {
    // MARK: - Properties

    private var appliedPolicy: NSApplication.ActivationPolicy?

    // MARK: - Public Methods

    func updateVisibility(showDockIcon: Bool) {
        guard let application = NSApp else { return }

        let targetPolicy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory

        guard targetPolicy != appliedPolicy else { return }

        application.setActivationPolicy(targetPolicy)
        appliedPolicy = targetPolicy

        application.activate(ignoringOtherApps: true)
    }
}
