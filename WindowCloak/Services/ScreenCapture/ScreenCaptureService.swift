//
//  ScreenCaptureService.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import ScreenCaptureKit
import CoreGraphics
import CoreMedia
import Combine

// MARK: - ScreenCaptureError

/// Errors related to screen capture.
enum ScreenCaptureError: LocalizedError {
    case noDisplayAvailable
    case noContentAvailable
    case streamNotStarted
    case streamAlreadyRunning
    case captureFailure(Error)

    var errorDescription: String? {
        switch self {
        case .noDisplayAvailable:
            return "No display available for capture."
        case .noContentAvailable:
            return "No shareable content available."
        case .streamNotStarted:
            return "Stream has not been started."
        case .streamAlreadyRunning:
            return "Stream is already running."
        case .captureFailure(let error):
            return "Capture failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - ScreenCaptureServiceDelegate

protocol ScreenCaptureServiceDelegate: AnyObject {
    func screenCaptureService(_ service: ScreenCaptureService, didCaptureFrame frame: CGImage)
    func screenCaptureService(_ service: ScreenCaptureService, didEncounterError error: Error)
}

// MARK: - ScreenCaptureService

final class ScreenCaptureService: NSObject {
    // MARK: - Properties

    weak var delegate: ScreenCaptureServiceDelegate?

    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    private var activeDisplay: SCDisplay?

    private let filterEngine: WindowFilterEngine
    private let permissionService: PermissionServiceProtocol

    @Published private(set) var isRunning = false
    @Published private(set) var availableDisplays: [SCDisplay] = []
    @Published private(set) var availableApplications: [AppInfo] = []

    // MARK: - Initialization

    init(
        filterEngine: WindowFilterEngine = WindowFilterEngine(),
        permissionService: PermissionServiceProtocol = PermissionService()
    ) {
        self.filterEngine = filterEngine
        self.permissionService = permissionService
        super.init()
    }

    // MARK: - Public Methods

    func refreshAvailableContent() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        await MainActor.run {
            self.availableDisplays = content.displays
            self.availableApplications = content.applications.map { AppInfo(from: $0) }
        }
    }

    /// Starts screen capture with the given configuration.
    func startCapture(
        display: SCDisplay? = nil,
        configuration: FilterConfiguration
    ) async throws {
        guard !isRunning else {
            throw ScreenCaptureError.streamAlreadyRunning
        }

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        let selectedDisplay: SCDisplay
        if let display = display {
            selectedDisplay = display
        } else {
            guard let mainDisplay = content.displays.first else {
                throw ScreenCaptureError.noDisplayAvailable
            }
            selectedDisplay = mainDisplay
        }

        // Add WindowCloak itself to excluded apps.
        var excludedApps = configuration.hiddenApplications
        if let bundleId = Bundle.main.bundleIdentifier {
            excludedApps.insert(bundleId)
        }

        let filter = filterEngine.createContentFilter(
            from: content.applications,
            excluding: excludedApps,
            display: selectedDisplay
        )

        let streamConfig = makeStreamConfiguration(for: selectedDisplay, configuration: configuration)

        let stream = SCStream(filter: filter, configuration: streamConfig, delegate: self)
        let output = StreamOutput(delegate: self)
        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        try await stream.startCapture()

        await MainActor.run {
            self.stream = stream
            self.streamOutput = output
            self.isRunning = true
            self.activeDisplay = selectedDisplay
            self.availableDisplays = content.displays
            self.availableApplications = content.applications.map { AppInfo(from: $0) }
        }
    }

    func stopCapture() async throws {
        guard isRunning else {
            throw ScreenCaptureError.streamNotStarted
        }

        try await stream?.stopCapture()

        await MainActor.run {
            self.stream = nil
            self.streamOutput = nil
            self.isRunning = false
            self.activeDisplay = nil
        }
    }

    /// Updates the filter configuration without stopping the stream.
    func updateFilter(configuration: FilterConfiguration) async throws {
        guard isRunning, let stream = stream else {
            throw ScreenCaptureError.streamNotStarted
        }

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        let display = activeDisplay ?? content.displays.first

        guard let selectedDisplay = display else {
            throw ScreenCaptureError.noDisplayAvailable
        }

        // Add WindowCloak itself to excluded apps.
        var excludedApps = configuration.hiddenApplications
        if let bundleId = Bundle.main.bundleIdentifier {
            excludedApps.insert(bundleId)
        }

        let filter = filterEngine.createContentFilter(
            from: content.applications,
            excluding: excludedApps,
            display: selectedDisplay
        )

        let streamConfig = makeStreamConfiguration(for: selectedDisplay, configuration: configuration)

        try await stream.updateContentFilter(filter)
        try await stream.updateConfiguration(streamConfig)

        await MainActor.run {
            self.availableDisplays = content.displays
            self.availableApplications = content.applications.map { AppInfo(from: $0) }
            self.activeDisplay = selectedDisplay
        }
    }
}

// MARK: - SCStreamDelegate

extension ScreenCaptureService: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            self.isRunning = false
            delegate?.screenCaptureService(self, didEncounterError: error)
        }
    }
}

private extension ScreenCaptureService {
    func makeStreamConfiguration(for display: SCDisplay, configuration: FilterConfiguration) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        streamConfig.width = Int(display.width)
        streamConfig.height = Int(display.height)
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60) // 60 FPS.
        streamConfig.queueDepth = 5
        streamConfig.showsCursor = !configuration.hideCursor
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
        return streamConfig
    }
}

// MARK: - StreamOutput

extension ScreenCaptureService {
    private final class StreamOutput: NSObject, SCStreamOutput {
        weak var delegate: ScreenCaptureService?
        private let ciContext = CIContext()

        init(delegate: ScreenCaptureService) {
            self.delegate = delegate
            super.init()
        }

        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            guard type == .screen,
                  let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                return
            }

            guard let service = delegate else { return }

            Task { @MainActor [service] in
                service.delegate?.screenCaptureService(service, didCaptureFrame: cgImage)
            }
        }
    }
}
