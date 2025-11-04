//
//  ContentView.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        ContentViewInternal(environment: environment)
    }
}

// MARK: - ContentViewInternal

private struct ContentViewInternal: View {
    @StateObject private var viewModel: MainViewModel
    @State private var showingSettings = false

    private let environment: AppEnvironment

    private var configurationRepository: ConfigurationRepository {
        environment.configurationRepository
    }

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: environment.makeMainViewModel())
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HeaderView(
                    isCapturing: viewModel.isCapturing,
                    hasPermission: viewModel.hasScreenRecordingPermission,
                    onToggleCapture: {
                        Task {
                            await viewModel.toggleCapture()
                        }
                    },
                    onShowSettings: {
                        showingSettings = true
                    }
                )
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if !viewModel.hasScreenRecordingPermission {
                    PermissionRequestView(
                        onRequestPermission: {
                            Task {
                                await viewModel.requestPermissions()
                            }
                        },
                        onOpenSettings: {
                            viewModel.openSystemPreferences()
                        }
                    )
                } else if viewModel.isCapturing {
                    CapturingStatusView(
                        onTogglePreview: {
                            viewModel.togglePreviewWindowVisibility()
                        },
                        isPreviewHidden: viewModel.isPreviewWindowHidden
                    )
                } else {
                    WelcomeView()
                }
            }
            .background(Color(NSColor.windowBackgroundColor))

            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(
                    message: errorMessage,
                    onDismiss: {
                        viewModel.errorMessage = nil
                    }
                )
                .padding(.top, 16)
                .padding(.horizontal, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(environment: environment)
        }
        .task {
            await viewModel.checkPermissions()
        }
    }
}

// MARK: - HeaderView

struct HeaderView: View {
    let isCapturing: Bool
    let hasPermission: Bool
    let onToggleCapture: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)

                    Image(systemName: "eye.slash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("WindowCloak")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)

                        Text(statusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button(action: onShowSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Settings")

                if hasPermission {
                    Button(action: onToggleCapture) {
                        HStack(spacing: 8) {
                            Image(systemName: isCapturing ? "stop.circle.fill" : "play.circle.fill")
                            Text(isCapturing ? "Stop" : "Start")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(isCapturing ? .red : .blue)
                }
            }
        }
    }

    private var statusText: String {
        if !hasPermission {
            return "Permission Required"
        } else if isCapturing {
            return "Live"
        } else {
            return "Ready"
        }
    }

    private var statusColor: Color {
        if !hasPermission {
            return .orange
        } else if isCapturing {
            return .green
        } else {
            return .gray
        }
    }
}

// MARK: - WelcomeView

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)

                Image(systemName: "display")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }

            Spacer()
                .frame(maxHeight: 40)

            VStack(spacing: 12) {
                Text("Welcome to WindowCloak")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Keep your private apps hidden during screen sharing")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }

            Spacer()
                .frame(maxHeight: 40)

            HStack(spacing: 24) {
                FeatureStep(
                    icon: "gearshape.fill",
                    number: "1",
                    title: "Configure",
                    description: "Add apps to hide"
                )

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))

                FeatureStep(
                    icon: "play.circle.fill",
                    number: "2",
                    title: "Start Capture",
                    description: "Begin filtering"
                )

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))

                FeatureStep(
                    icon: "arrow.up.forward.square.fill",
                    number: "3",
                    title: "Share",
                    description: "Share preview window"
                )
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureStep: View {
    let icon: String
    let number: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: 180)
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.green.opacity(0.15), .blue.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)

                Text("\(number)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: 180)
    }
}


// MARK: - PermissionRequestView

struct PermissionRequestView: View {
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.orange)
            }

            Spacer()
                .frame(maxHeight: 40)

            VStack(spacing: 12) {
                Text("Permission Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("WindowCloak needs screen recording access\nto filter and capture your screen")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

            Spacer()
                .frame(maxHeight: 40)

            VStack(spacing: 12) {
                Button(action: onRequestPermission) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Grant Permission")
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onOpenSettings) {
                    Text("Open System Settings")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - CapturingStatusView

struct CapturingStatusView: View {
    let onTogglePreview: () -> Void
    let isPreviewHidden: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }

            Spacer()
                .frame(maxHeight: 32)

            VStack(spacing: 12) {
                Text("Live Capture Active")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Preview window is ready for sharing")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()
                .frame(maxHeight: 28)

            HStack(spacing: 24) {
                InstructionStep(
                    number: 1,
                    title: "Share",
                    description: "Click \"Share\" in Meet/Zoom"
                )

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))

                InstructionStep(
                    number: 2,
                    title: "Window",
                    description: "Choose \"A Window\""
                )

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))

                InstructionStep(
                    number: 3,
                    title: "Select Preview",
                    description: "Pick \"WindowCloak Preview\""
                )
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(maxHeight: 28)

            Button(action: onTogglePreview) {
                HStack(spacing: 8) {
                    Image(systemName: isPreviewHidden ? "rectangle.on.rectangle.angled" : "eye.slash")
                    Text(isPreviewHidden ? "Show Preview Window" : "Hide Preview Window")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isPreviewHidden ? Color.accentColor : Color.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ErrorBannerView

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            // Dismiss button.
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [.red.opacity(0.3), .orange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
