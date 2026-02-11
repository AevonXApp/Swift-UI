//
//  ApplicationsTab.swift
//  AevonX
//
//  Applications/Stack management tab (Nginx, PHP, Docker, etc.)
//  Now using 100% REAL data from Core
//

import SwiftUI
import AevonXCore

struct ApplicationsTab: View {
    let server: Server?
    let serverId: String?
    let connectionViewModel: ServerConnectionViewModel?

    @State private var applications: [ApplicationInstance] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(server: Server? = nil, serverId: String? = nil, connectionViewModel: ServerConnectionViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
    }

    var runningApps: [ApplicationInstance] { applications.filter { $0.isRunning } }
    var stoppedApps: [ApplicationInstance] { applications.filter { !$0.isRunning } }

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Summary Cards
            HStack(spacing: AXSpacing.lg) {
                ServiceSummaryCard(
                    title: "Running",
                    count: runningApps.count,
                    total: applications.count,
                    color: .axSuccess,
                    icon: "checkmark.circle.fill"
                )

                ServiceSummaryCard(
                    title: "Stopped",
                    count: stoppedApps.count,
                    total: applications.count,
                    color: .axTextMuted,
                    icon: "xmark.circle.fill"
                )

                ServiceSummaryCard(
                    title: "Auto-start",
                    count: applications.filter { $0.autoStart }.count,
                    total: applications.count,
                    color: .axAccentBlue,
                    icon: "power"
                )

                ServiceSummaryCard(
                    title: "Memory Used",
                    count: Int(applications.compactMap { $0.memoryUsage }.reduce(0, +)),
                    total: 2048,
                    color: .axWarning,
                    icon: "memorychip",
                    isMemory: true
                )
            }

            // Services List
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Services")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        Button(action: { Task { await loadApplications() } }) {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10))
                                Text("Refresh")
                                    .font(AXTypography.caption)
                            }
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xs)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axBackgroundTertiary)

                    Divider()
                        .background(Color.axBorder)

                    // Loading or Content
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(AXSpacing.xl)
                            Spacer()
                        }
                    } else if let error = errorMessage {
                        HStack {
                            Spacer()
                            VStack(spacing: AXSpacing.md) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.axError)
                                Text(error)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(AXSpacing.xl)
                            Spacer()
                        }
                    } else if applications.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: AXSpacing.md) {
                                Image(systemName: "app.badge")
                                    .font(.system(size: 24))
                                    .foregroundColor(.axTextMuted)
                                Text("No applications detected")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                            }
                            .padding(AXSpacing.xl)
                            Spacer()
                        }
                    } else {
                        // Service Rows
                        ForEach(applications) { app in
                            if let serverId = serverId {
                                NavigationLink(destination: ApplicationDetailView(application: app, serverId: serverId)) {
                                    ServiceRow(
                                        application: app,
                                        onStart: { await startApplication(app) },
                                        onStop: { await stopApplication(app) },
                                        onRestart: { await restartApplication(app) },
                                        onToggleAutoStart: { await toggleAutoStart(app) }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            if app.id != applications.last?.id {
                                Divider()
                                    .background(Color.axBorder)
                                    .padding(.leading, AXSpacing.lg)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadApplications()
        }
    }

    // MARK: - Data Loading

    private func loadApplications() async {
        guard let serverId = serverId else {
            errorMessage = "No server selected"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let apps = try await ApplicationManager.shared.discoverInstalledApplications(serverId: serverId)
            await MainActor.run {
                self.applications = apps
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load applications: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Actions

    private func startApplication(_ app: ApplicationInstance) async {
        guard let serverId = serverId else { return }

        do {
            try await ApplicationManager.shared.startService(type: app.type, serverId: serverId)
            await loadApplications()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to start \(app.name): \(error.localizedDescription)"
            }
        }
    }

    private func stopApplication(_ app: ApplicationInstance) async {
        guard let serverId = serverId else { return }

        do {
            try await ApplicationManager.shared.stopService(type: app.type, serverId: serverId)
            await loadApplications()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to stop \(app.name): \(error.localizedDescription)"
            }
        }
    }

    private func restartApplication(_ app: ApplicationInstance) async {
        guard let serverId = serverId else { return }

        do {
            try await ApplicationManager.shared.restartService(type: app.type, serverId: serverId)
            await loadApplications()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to restart \(app.name): \(error.localizedDescription)"
            }
        }
    }

    private func toggleAutoStart(_ app: ApplicationInstance) async {
        guard let serverId = serverId else { return }

        do {
            if app.autoStart {
                try await ApplicationManager.shared.disableOnBoot(type: app.type, serverId: serverId)
            } else {
                try await ApplicationManager.shared.enableOnBoot(type: app.type, serverId: serverId)
            }
            await loadApplications()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to toggle auto-start for \(app.name): \(error.localizedDescription)"
            }
        }
    }
}

struct ServiceSummaryCard: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    let icon: String
    var isMemory: Bool = false

    var body: some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)

                    Spacer()

                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
                }

                HStack(alignment: .lastTextBaseline, spacing: AXSpacing.xs) {
                    Text(isMemory ? "\(count)" : "\(count)")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    if !isMemory {
                        Text("/ \(total)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    } else {
                        Text("MB")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ServiceRow: View {
    let application: ApplicationInstance
    let onStart: () async -> Void
    let onStop: () async -> Void
    let onRestart: () async -> Void
    let onToggleAutoStart: () async -> Void

    @State private var isProcessing = false
    @State private var localAutoStart: Bool

    init(
        application: ApplicationInstance,
        onStart: @escaping () async -> Void,
        onStop: @escaping () async -> Void,
        onRestart: @escaping () async -> Void,
        onToggleAutoStart: @escaping () async -> Void
    ) {
        self.application = application
        self.onStart = onStart
        self.onStop = onStop
        self.onRestart = onRestart
        self.onToggleAutoStart = onToggleAutoStart
        self._localAutoStart = State(initialValue: application.autoStart)
    }

    var body: some View {
        HStack(spacing: AXSpacing.md) {
                // Icon & Name
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(application.isRunning ? Color.axSuccess.opacity(0.15) : Color.axTextMuted.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: serviceIcon)
                            .font(.system(size: 16))
                            .foregroundColor(application.isRunning ? .axSuccess : .axTextMuted)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(application.name)
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)

                        if let version = application.version {
                            Text("v\(version)")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        } else {
                            Text("Version unknown")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                    }
                }
                .frame(width: 160, alignment: .leading)

                // Status
                HStack(spacing: AXSpacing.xs) {
                    Circle()
                        .fill(application.isRunning ? Color.axSuccess : Color.axTextMuted)
                        .frame(width: 6, height: 6)

                    Text(application.isRunning ? "Running" : "Stopped")
                        .font(AXTypography.caption)
                        .foregroundColor(application.isRunning ? .axSuccess : .axTextMuted)
                }
                .frame(width: 80, alignment: .leading)

                // Port
                if let port = application.port {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)

                        Text("\(port)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .monospaced()
                    }
                    .frame(width: 70, alignment: .leading)
                } else {
                    Text("-")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 70, alignment: .leading)
                }

                // Memory
                if let memory = application.memoryUsage {
                    HStack(spacing: AXSpacing.xs) {
                        ProgressView(value: min(memory / 500, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: memory > 400 ? .axError : .axAccentBlue))
                            .frame(width: 60)

                        Text("\(String(format: "%.0f", memory)) MB")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                            .monospaced()
                    }
                    .frame(width: 130, alignment: .leading)
                } else {
                    Text("-")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 130, alignment: .leading)
                }

                Spacer()

                // Auto-start Toggle
                HStack(spacing: AXSpacing.sm) {
                    Text("Auto")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)

                    Toggle("", isOn: $localAutoStart)
                        .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                        .frame(width: 36)
                        .onChange(of: localAutoStart) { _ in
                            Task {
                                await onToggleAutoStart()
                            }
                        }
                        .disabled(isProcessing)
                }
                .frame(width: 80)

                // Actions
                HStack(spacing: AXSpacing.sm) {
                    Button(action: {
                        Task {
                            isProcessing = true
                            if application.isRunning {
                                await onStop()
                            } else {
                                await onStart()
                            }
                            isProcessing = false
                        }
                    }) {
                        if isProcessing {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: application.isRunning ? "stop.fill" : "play.fill")
                                .font(.system(size: 10))
                                .foregroundColor(application.isRunning ? .axError : .axSuccess)
                                .frame(width: 32, height: 32)
                                .background((application.isRunning ? Color.axError : Color.axSuccess).opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessing)

                    Button(action: {
                        Task {
                            isProcessing = true
                            await onRestart()
                            isProcessing = false
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.axAccentBlue)
                            .frame(width: 32, height: 32)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessing)
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface)
    }

    private var serviceIcon: String {
        switch application.type {
        case .nginx, .apache: return "server.rack"
        case .phpFpm: return "p.circle"
        case .mysql, .postgresql: return "cylinder"
        case .redis: return "bolt.fill"
        case .docker: return "shippingbox.fill"
        case .supervisor: return "eye.fill"
        case .elasticsearch: return "magnifyingglass"
        case .mongodb: return "leaf.fill"
        case .nodejs: return "n.circle"
        case .python: return "snake"
        case .rabbitmq: return "hare.fill"
        case .memcached: return "memorychip.fill"
        default: return "gearshape.fill"
        }
    }
}

#Preview {
    ApplicationsTab()
        .padding()
        .background(Color.axBackground)
}
