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

    private let dockIconController: DockIconControlling
    private let screenCaptureService: ScreenCaptureService
    private let permissionService: PermissionServiceProtocol
    private let previewWindowFactory: PreviewWindowFactory
    private var cancellables = Set<AnyCancellable>()

    init(
        configurationRepositoryFactory: @MainActor () -> ConfigurationRepository = { ConfigurationRepository() },
        screenCaptureServiceFactory: @MainActor () -> ScreenCaptureService = { ScreenCaptureService() },
        permissionServiceFactory: @MainActor () -> PermissionServiceProtocol = { PermissionService() },
        dockIconControllerFactory: @MainActor () -> DockIconControlling = { DockIconController() },
        previewWindowFactory: @escaping PreviewWindowFactory = { DefaultPreviewWindowControllerFactory().make(viewModel: $0) }
    ) {
        let resolvedRepository = configurationRepositoryFactory()
        let resolvedScreenCaptureService = screenCaptureServiceFactory()
        let resolvedPermissionService = permissionServiceFactory()
        let resolvedDockIconController = dockIconControllerFactory()

        self.configurationRepository = resolvedRepository
        self.screenCaptureService = resolvedScreenCaptureService
        self.permissionService = resolvedPermissionService
        self.dockIconController = resolvedDockIconController
        self.previewWindowFactory = previewWindowFactory
        self.appCoordinator = AppCoordinator()

        setupDockIconBinding()
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

    private func setupDockIconBinding() {
        dockIconController.updateVisibility(showDockIcon: configurationRepository.currentConfiguration.showDockIcon)

        configurationRepository.$currentConfiguration
            .map(\.showDockIcon)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] showDockIcon in
                self?.dockIconController.updateVisibility(showDockIcon: showDockIcon)
            }
            .store(in: &cancellables)
    }
}
