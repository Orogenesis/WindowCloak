//
//  ConfigurationRepository.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine
import CoreGraphics

// MARK: - ConfigurationRepository

final class ConfigurationRepository: ObservableObject {
    // MARK: - Properties

    @Published private(set) var currentConfiguration: FilterConfiguration

    private let store: ConfigurationStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(store: ConfigurationStoreProtocol = UserDefaultsConfigurationStore()) {
        self.store = store

        do {
            self.currentConfiguration = try store.load()
        } catch {
            print("Failed to load configuration: \(error). Using defaults.")
            self.currentConfiguration = FilterConfiguration()
        }

        store.observeChanges()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] configuration in
                self?.currentConfiguration = configuration
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Saves the current configuration.
    func save() throws {
        try store.save(currentConfiguration)
    }

    /// Updates configuration and saves.
    func update(_ configuration: FilterConfiguration) throws {
        currentConfiguration = configuration
        try store.save(configuration)
    }

    /// Adds an application to the hidden list.
    func hideApplication(_ bundleIdentifier: String) throws {
        var config = currentConfiguration
        config.hiddenApplications.insert(bundleIdentifier)
        try update(config)
    }

    /// Removes an application from the hidden list.
    func unhideApplication(_ bundleIdentifier: String) throws {
        var config = currentConfiguration
        config.hiddenApplications.remove(bundleIdentifier)
        try update(config)
    }

    /// Toggles application visibility.
    func toggleApplication(_ bundleIdentifier: String) throws {
        if currentConfiguration.hiddenApplications.contains(bundleIdentifier) {
            try unhideApplication(bundleIdentifier)
        } else {
            try hideApplication(bundleIdentifier)
        }
    }

    /// Resets to default configuration.
    func reset() throws {
        try update(FilterConfiguration())
    }

    /// Updates the in-memory hidden window selections without persisting them.
    func updateHiddenWindowsCache(_ hiddenWindowsByApp: [String: Set<CGWindowID>]) {
        guard currentConfiguration.hiddenWindowsByApp != hiddenWindowsByApp else { return }
        var config = currentConfiguration
        config.hiddenWindowsByApp = hiddenWindowsByApp
        currentConfiguration = config
    }
}
