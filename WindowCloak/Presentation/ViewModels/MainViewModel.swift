//
//  MainViewModel.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine
import AppKit

// MARK: - MainViewModel

@MainActor
final class MainViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isCapturing = false
    @Published var currentFrame: CGImage?
    @Published var errorMessage: String?
    @Published var hasScreenRecordingPermission = false
    @Published var availableApplications: [AppInfo] = []
    @Published private(set) var isPreviewWindowHidden = true

    // MARK: - Dependencies

    private let captureService: ScreenCaptureService
    private let permissionService: PermissionServiceProtocol
    private let configurationRepository: ConfigurationRepository
    private let previewWindowFactory: @MainActor (MainViewModel) -> PreviewWindowController

    private var cancellables = Set<AnyCancellable>()
    private var previewWindowController: PreviewWindowController?

    // MARK: - Initialization

    init(
        captureService: ScreenCaptureService,
        permissionService: PermissionServiceProtocol,
        configurationRepository: ConfigurationRepository,
        previewWindowFactory: @escaping @MainActor (MainViewModel) -> PreviewWindowController
    ) {
        self.captureService = captureService
        self.permissionService = permissionService
        self.configurationRepository = configurationRepository
        self.previewWindowFactory = previewWindowFactory

        setupBindings()
        self.captureService.delegate = self
    }

    // MARK: - Public Methods

    func checkPermissions() async {
        hasScreenRecordingPermission = await permissionService.checkScreenRecordingPermission()
    }

    func requestPermissions() async {
        _ = await permissionService.requestScreenRecordingPermission()

        hasScreenRecordingPermission = await permissionService.checkScreenRecordingPermission()
        if !hasScreenRecordingPermission {
            errorMessage = "Please grant permission in System Settings and restart the app."
        }
    }

    func openSystemPreferences() {
        permissionService.openSystemPreferences()
    }

    func startCapture() async {
        guard hasScreenRecordingPermission else {
            errorMessage = "Screen recording permission required."
            return
        }

        do {
            try await captureService.refreshAvailableContent()
            availableApplications = captureService.availableApplications

            let configuration = configurationRepository.currentConfiguration
            try await captureService.startCapture(configuration: configuration)

            isCapturing = true
            errorMessage = nil

            openPreviewWindow()
        } catch {
            errorMessage = "Failed to start capture: \(error.localizedDescription)"
            isCapturing = false
        }
    }

    func stopCapture() async {
        do {
            try await captureService.stopCapture()
            isCapturing = false
            closePreviewWindow()
        } catch {
            errorMessage = "Failed to stop capture: \(error.localizedDescription)"
        }
    }

    // MARK: - Preview Window Management

    private func openPreviewWindow() {
        guard previewWindowController == nil else { return }

        let controller = previewWindowFactory(self)
        controller.showWindow(nil)
        controller.parkForBackgroundSharing()
        previewWindowController = controller
        isPreviewWindowHidden = true
    }

    private func closePreviewWindow() {
        previewWindowController?.resetParkingState()
        previewWindowController?.close()
        previewWindowController = nil
        isPreviewWindowHidden = true
    }

    func toggleCapture() async {
        if isCapturing {
            await stopCapture()
        } else {
            await startCapture()
        }
    }

    func updateFilter() async {
        guard isCapturing else { return }

        do {
            let configuration = configurationRepository.currentConfiguration
            try await captureService.updateFilter(configuration: configuration)
        } catch {
            errorMessage = "Failed to update filter: \(error.localizedDescription)"
        }
    }

    func togglePreviewWindowVisibility() {
        guard let controller = previewWindowController else { return }

        if controller.isParked {
            controller.presentToUser()
            isPreviewWindowHidden = false
        } else {
            controller.parkForBackgroundSharing()
            isPreviewWindowHidden = true
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        configurationRepository.$currentConfiguration
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateFilter()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - ScreenCaptureServiceDelegate

extension MainViewModel: ScreenCaptureServiceDelegate {
    func screenCaptureService(_ service: ScreenCaptureService, didCaptureFrame frame: CGImage) {
        currentFrame = frame
    }

    func screenCaptureService(_ service: ScreenCaptureService, didEncounterError error: Error) {
        errorMessage = error.localizedDescription
        isCapturing = false
    }
}
