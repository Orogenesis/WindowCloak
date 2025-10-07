//
//  AppCoordinator.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import Foundation
import Combine

// MARK: - AppCoordinator

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var isAboutPresented = false

    func showAbout() {
        isAboutPresented = true
    }
}
