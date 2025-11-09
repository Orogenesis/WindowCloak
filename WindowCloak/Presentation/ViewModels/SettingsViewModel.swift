//
//  SettingsViewModel.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine
import CoreGraphics
import AppKit

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var hiddenApplications: Set<String>
    @Published var hideCursor: Bool
    @Published var showDockIcon: Bool
    @Published var hiddenWindowsByApp: [String: Set<CGWindowID>]
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
        self.hiddenWindowsByApp = config.hiddenWindowsByApp

        setupBindings()
    }

    // MARK: - Public Methods

    func saveConfiguration() {
        do {
            let configuration = FilterConfiguration(
                hiddenApplications: hiddenApplications,
                hiddenWindowsByApp: hiddenWindowsByApp,
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
            hiddenWindowsByApp[bundleIdentifier] = nil
        } else {
            hiddenApplications.insert(bundleIdentifier)
            // Hide entire app by default; ensure no stale overrides.
            hiddenWindowsByApp[bundleIdentifier] = nil
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

    func hiddenWindowIDs(for bundleIdentifier: String) -> Set<CGWindowID> {
        hiddenWindowsByApp[bundleIdentifier] ?? []
    }

    func isCustomWindowSelectionEnabled(for bundleIdentifier: String) -> Bool {
        hiddenWindowsByApp[bundleIdentifier] != nil
    }

    func updateHiddenWindows(_ windowIDs: Set<CGWindowID>, for bundleIdentifier: String) {
        guard hiddenApplications.contains(bundleIdentifier) else { return }
        hiddenWindowsByApp[bundleIdentifier] = windowIDs
        saveConfiguration()
    }

    func clearHiddenWindows(for bundleIdentifier: String) {
        hiddenWindowsByApp[bundleIdentifier] = nil
        saveConfiguration()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        configurationRepository.$currentConfiguration
            .sink { [weak self] config in
                self?.hiddenApplications = config.hiddenApplications
                self?.hideCursor = config.hideCursor
                self?.showDockIcon = config.showDockIcon
                self?.hiddenWindowsByApp = config.hiddenWindowsByApp
            }
            .store(in: &cancellables)

        WindowEventsNotifier.shared.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.pruneClosedHiddenWindows()
            }
            .store(in: &cancellables)
    }

    private func pruneClosedHiddenWindows() {
        guard !hiddenWindowsByApp.isEmpty else { return }
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return
        }

        let availableWindowIDs = Set(
            windowInfoList.compactMap { info in
                info[kCGWindowNumber as String] as? CGWindowID
            }
        )

        var updated = hiddenWindowsByApp
        var didChange = false

        for (bundleId, storedIDs) in hiddenWindowsByApp {
            let pruned = storedIDs.intersection(availableWindowIDs)
            if pruned != storedIDs {
                updated[bundleId] = pruned
                didChange = true
            }
        }

        guard didChange else { return }
        hiddenWindowsByApp = updated
        saveConfiguration()
    }
}
