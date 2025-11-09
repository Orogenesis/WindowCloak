//
//  WindowEventsNotifier.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine
import AppKit

// MARK: - WindowEventsNotifier

/// Broadcasts high-level signals whenever the global window landscape likely changed.
/// Uses Workspace notifications and global event monitors instead of polling.
final class WindowEventsNotifier {
    static let shared = WindowEventsNotifier()

    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    private let subject = PassthroughSubject<Void, Never>()
    private var notificationTokens: [(NotificationCenter, NSObjectProtocol)] = []
    private var localMonitor: Any?
    private var globalMonitor: Any?

    private init(workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        observeWorkspaceNotifications(center: workspaceCenter)
        observeSpaceChanges()
        observeInputEvents()

        // Emit once so subscribers can perform initial refreshes.
        subject.send(())
    }

    deinit {
        for (center, token) in notificationTokens {
            center.removeObserver(token)
        }

        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
    }

    private func observeWorkspaceNotifications(center: NotificationCenter) {
        let names: [Notification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didDeactivateApplicationNotification,
            NSWorkspace.activeSpaceDidChangeNotification
        ]

        for name in names {
            let observer = center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.subject.send(())
            }
       
            notificationTokens.append((center, observer))
        }
    }

    private func observeSpaceChanges() {
        let displayCenter = NotificationCenter.default
        let displayObserver = displayCenter.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.subject.send(())
        }
    
        notificationTokens.append((displayCenter, displayObserver))
    }

    private func observeInputEvents() {
        let mask: NSEvent.EventTypeMask = [
            .leftMouseUp,
            .rightMouseUp,
            .otherMouseUp,
            .keyUp,
            .flagsChanged
        ]

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.subject.send(())
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            self?.subject.send(())
        }
    }
}
