//
//  SettingsView.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .applications

    init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: environment.makeSettingsViewModel())
    }

    enum SettingsTab: String, CaseIterable {
        case applications = "Applications"
        case capture = "Capture"
        case about = "About"

        var icon: String {
            switch self {
            case .applications: return "app.badge"
            case .capture: return "cursorarrow.click"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(20)

            Divider()

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        SidebarButton(
                            title: tab.rawValue,
                            icon: tab.icon,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }

                    Spacer()
                }
                .frame(width: 180)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))

                Group {
                    switch selectedTab {
                    case .applications:
                        ApplicationsView(viewModel: viewModel)
                    case .capture:
                        CaptureSettingsView(viewModel: viewModel)
                    case .about:
                        AboutView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 450, idealHeight: 550)
    }
}

// MARK: - SidebarButton

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 20)

                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .primary : .secondary)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(NSColor.controlAccentColor).opacity(0.15)
        } else if isHovered {
            return Color(NSColor.separatorColor).opacity(0.5)
        } else {
            return Color.clear
        }
    }
}

// MARK: - ApplicationsView

struct ApplicationsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingAppPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hidden Applications")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Applications in this list will be filtered from screen sharing")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                if viewModel.hiddenApplications.isEmpty {
                    EmptyStateView()
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.hiddenApplications), id: \.self) { bundleId in
                            HiddenAppCard(
                                bundleIdentifier: bundleId,
                                onRemove: {
                                    viewModel.toggleApplication(bundleId)
                                }
                            )
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                Button(action: { showingAppPicker = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Application")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !viewModel.hiddenApplications.isEmpty {
                    Button(action: { viewModel.resetToDefaults() }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                }
            }
        }
        .padding(24)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(
                hiddenApps: viewModel.hiddenApplications,
                onToggle: { viewModel.toggleApplication($0) }
            )
        }
    }
}

// MARK: - CaptureSettingsView

struct CaptureSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Capture Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Fine-tune how WindowCloak presents your shared screen.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            SettingToggleCard(
                title: "Hide cursor in shared window",
                subtitle: "Prevents your pointer from appearing in the captured preview.",
                systemImage: "cursorarrow.rays",
                isOn: Binding(
                    get: { viewModel.hideCursor },
                    set: { viewModel.setHideCursor($0) }
                )
            )

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - SettingToggleCard

struct SettingToggleCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [
                                Color.blue.opacity(0.15),
                                Color.purple.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)

                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Hidden Applications")
                .font(.title3)
                .fontWeight(.medium)

            Text("Add applications to hide them from screen sharing")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - HiddenAppCard

struct HiddenAppCard: View {
    let bundleIdentifier: String
    let onRemove: () -> Void

    @State private var appName: String?
    @State private var appIcon: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 36, height: 36)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: "app")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appName ?? bundleIdentifier)
                    .font(.body)
                    .fontWeight(.medium)

                Text(bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .task {
            loadAppInfo()
        }
    }

    private func loadAppInfo() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            appName = FileManager.default.displayName(atPath: appURL.path)
            appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        }
    }
}

// MARK: - AboutView

struct AboutView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("WindowCloak")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Hide applications from screen sharing\nwhile keeping them visible to you")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(width: 300)

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                Text("© 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Licensed under MIT License")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

// MARK: - AppPickerView

struct AppPickerView: View {
    let hiddenApps: Set<String>
    let onToggle: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var runningApps: [NSRunningApplication] = []
    @State private var searchText = ""

    var filteredApps: [NSRunningApplication] {
        let sorted = runningApps.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { app in
            app.localizedName?.lowercased().contains(searchText.lowercased()) ?? false ||
            app.bundleIdentifier?.lowercased().contains(searchText.lowercased()) ?? false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header.
            HStack {
                Text("Select Applications")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)

            Divider()

            // Search bar.
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // App list.
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredApps, id: \.processIdentifier) { app in
                        if let bundleId = app.bundleIdentifier {
                            AppPickerCard(
                                app: app,
                                bundleId: bundleId,
                                isHidden: hiddenApps.contains(bundleId),
                                onToggle: { onToggle(bundleId) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .frame(minWidth: 500, idealWidth: 550, minHeight: 400, idealHeight: 500)
        .task {
            loadRunningApps()
        }
    }

    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
    }
}

// MARK: - AppPickerCard

struct AppPickerCard: View {
    let app: NSRunningApplication
    let bundleId: String
    let isHidden: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 36, height: 36)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.localizedName ?? "Unknown")
                        .font(.body)
                        .fontWeight(isHidden ? .semibold : .regular)

                    Text(bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isHidden {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(isHidden ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
