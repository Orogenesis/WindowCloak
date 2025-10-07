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
        window.contentView = NSHostingView(
            rootView: PreviewWindowContentView(viewModel: viewModel)
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.aspectRatio = NSSize(width: screenFrame.width, height: screenFrame.height)

        self.init(window: window)
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
