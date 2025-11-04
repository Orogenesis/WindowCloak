//
//  PreviewWindowController.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import SwiftUI
import AppKit

// MARK: - DefaultPreviewWindowControllerFactory

@MainActor
struct DefaultPreviewWindowControllerFactory {
    func make(viewModel: MainViewModel) -> PreviewWindowController {
        PreviewWindowController(viewModel: viewModel)
    }
}

// MARK: - PreviewWindowController

@MainActor
final class PreviewWindowController: NSWindowController {
    private var storedFrame: NSRect?
    private(set) var isParked = false

    convenience init(viewModel: MainViewModel) {
        guard let screen = NSScreen.main else {
            fatalError("No screen available")
        }

        let screenFrame = screen.frame
        let windowWidth = screenFrame.width * 0.7
        let windowHeight = screenFrame.height * 0.7

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "WindowCloak Preview"
        window.isMovableByWindowBackground = true
        window.backgroundColor = .black
        window.hasShadow = true
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary
        ]
        window.contentView = NSHostingView(
            rootView: PreviewWindowContentView(viewModel: viewModel)
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.aspectRatio = NSSize(width: screenFrame.width, height: screenFrame.height)

        self.init(window: window)
    }

    func parkForBackgroundSharing() {
        guard let window = window else { return }
        guard let screen = window.screen ?? NSScreen.main else { return }

        if storedFrame == nil {
            storedFrame = window.frame
        }

        let hiddenOrigin = NSPoint(
            x: screen.frame.maxX + 200,
            y: screen.frame.maxY - window.frame.height - 200
        )

        window.setFrameOrigin(hiddenOrigin)
        window.orderBack(nil)
        isParked = true
    }

    func presentToUser() {
        guard let window = window else { return }

        let targetFrame = storedFrame ?? window.frame
        window.setFrame(targetFrame, display: true)
        window.makeKeyAndOrderFront(nil)
        isParked = false
    }

    func resetParkingState() {
        storedFrame = nil
        isParked = false
    }
}

// MARK: - PreviewWindowContentView

private struct PreviewWindowContentView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        PreviewWindowView(currentFrame: viewModel.currentFrame)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
