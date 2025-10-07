//
//  ConfigurationStore.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine

// MARK: - ConfigurationStoreProtocol

protocol ConfigurationStoreProtocol {
    func save(_ configuration: FilterConfiguration) throws
    func load() throws -> FilterConfiguration
    func observeChanges() -> AnyPublisher<FilterConfiguration, Never>
}

/// UserDefaults-based configuration store.
// MARK: - UserDefaultsConfigurationStore

final class UserDefaultsConfigurationStore: ConfigurationStoreProtocol {
    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let configurationKey = "com.windowcloak.filterConfiguration"
    private let configurationSubject = PassthroughSubject<FilterConfiguration, Never>()

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    func save(_ configuration: FilterConfiguration) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(configuration)
        userDefaults.set(data, forKey: configurationKey)

        configurationSubject.send(configuration)
    }

    func load() throws -> FilterConfiguration {
        guard let data = userDefaults.data(forKey: configurationKey) else {
            // Return default configuration if none exists.
            return FilterConfiguration()
        }

        let decoder = JSONDecoder()
        return try decoder.decode(FilterConfiguration.self, from: data)
    }

    func observeChanges() -> AnyPublisher<FilterConfiguration, Never> {
        configurationSubject.eraseToAnyPublisher()
    }
}

/// File-based configuration store.
// MARK: - FileConfigurationStore

final class FileConfigurationStore: ConfigurationStoreProtocol {
    // MARK: - Properties

    private let fileURL: URL
    private let configurationSubject = PassthroughSubject<FilterConfiguration, Never>()
    private let fileManager = FileManager.default

    // MARK: - Initialization

    init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!

            let bundleId = Bundle.main.bundleIdentifier ?? "com.windowcloak"
            let appDirectory = appSupport.appendingPathComponent(bundleId)

            try? fileManager.createDirectory(
                at: appDirectory,
                withIntermediateDirectories: true
            )

            self.fileURL = appDirectory.appendingPathComponent("configuration.json")
        }
    }

    // MARK: - Public Methods

    func save(_ configuration: FilterConfiguration) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(configuration)

        try data.write(to: fileURL, options: .atomic)
        configurationSubject.send(configuration)
    }

    func load() throws -> FilterConfiguration {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return FilterConfiguration()
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(FilterConfiguration.self, from: data)
    }

    func observeChanges() -> AnyPublisher<FilterConfiguration, Never> {
        configurationSubject.eraseToAnyPublisher()
    }
}
