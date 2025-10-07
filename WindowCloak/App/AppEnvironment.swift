//
//  AppEnvironment.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine

// MARK: - AppEnvironment

@MainActor
final class AppEnvironment: ObservableObject {
    typealias PreviewWindowFactory = @MainActor (MainViewModel) -> PreviewWindowController

    let appCoordinator: AppCoordinator
    let configurationRepository: ConfigurationRepository

    private let screenCaptureService: ScreenCaptureService
    private let permissionService: PermissionServiceProtocol
    private let previewWindowFactory: PreviewWindowFactory

    init(
        configurationRepository: ConfigurationRepository = ConfigurationRepository(),
        screenCaptureService: ScreenCaptureService = ScreenCaptureService(),
        permissionService: PermissionServiceProtocol = PermissionService(),
        previewWindowFactory: @escaping PreviewWindowFactory = { DefaultPreviewWindowControllerFactory().make(viewModel: $0) }
    ) {
        self.configurationRepository = configurationRepository
        self.screenCaptureService = screenCaptureService
        self.permissionService = permissionService
        self.previewWindowFactory = previewWindowFactory
        self.appCoordinator = AppCoordinator()
    }

    func makeMainViewModel() -> MainViewModel {
        MainViewModel(
            captureService: screenCaptureService,
            permissionService: permissionService,
            configurationRepository: configurationRepository,
            previewWindowFactory: previewWindowFactory
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(configurationRepository: configurationRepository)
    }
}
