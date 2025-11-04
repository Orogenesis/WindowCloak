//
//  SettingsViewModel.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var hiddenApplications: Set<String>
    @Published var hideCursor: Bool
    @Published var showDockIcon: Bool
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let configurationRepository: ConfigurationRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(configurationRepository: ConfigurationRepository) {
        self.configurationRepository = configurationRepository

        let config = self.configurationRepository.currentConfiguration
        self.hiddenApplications = config.hiddenApplications
        self.hideCursor = config.hideCursor
        self.showDockIcon = config.showDockIcon

        setupBindings()
    }

    // MARK: - Public Methods

    func saveConfiguration() {
        do {
            let configuration = FilterConfiguration(
                hiddenApplications: hiddenApplications,
                hideCursor: hideCursor,
                showDockIcon: showDockIcon
            )
            try configurationRepository.update(configuration)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }
    }

    func toggleApplication(_ bundleIdentifier: String) {
        if hiddenApplications.contains(bundleIdentifier) {
            hiddenApplications.remove(bundleIdentifier)
        } else {
            hiddenApplications.insert(bundleIdentifier)
        }
    
        saveConfiguration()
    }

    func setHideCursor(_ isHidden: Bool) {
        hideCursor = isHidden
        saveConfiguration()
    }

    func setShowDockIcon(_ isVisible: Bool) {
        showDockIcon = isVisible
        saveConfiguration()
    }

    func resetToDefaults() {
        do {
            try configurationRepository.reset()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to reset configuration: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        configurationRepository.$currentConfiguration
            .sink { [weak self] config in
                self?.hiddenApplications = config.hiddenApplications
                self?.hideCursor = config.hideCursor
                self?.showDockIcon = config.showDockIcon
            }
            .store(in: &cancellables)
    }
}
