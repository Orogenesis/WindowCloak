//
//  WindowCloakApp.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import SwiftUI
import Combine

// MARK: - WindowCloakApp

@main
struct WindowCloakApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .environmentObject(environment.appCoordinator)
                .environmentObject(environment.configurationRepository)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About WindowCloak") {
                    environment.appCoordinator.showAbout()
                }
            }
        }
    }
}
