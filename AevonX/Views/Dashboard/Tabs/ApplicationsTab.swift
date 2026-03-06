//
//  ApplicationsTab.swift
//  AevonX
//
//  Applications/Stack management tab — Premium Redesign
//  Card-based layout with hover, glow, and gradient effects
//

import SwiftUI
import AevonXCore

struct ApplicationsTab: View {
    let server: Server?
    let serverId: String?
    let connectionViewModel: ServerConnectionViewModel?

    @StateObject private var viewModel: ApplicationsListViewModel

    init(server: Server? = nil, serverId: String? = nil, connectionViewModel: ServerConnectionViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        self._viewModel = StateObject(wrappedValue: ApplicationsListViewModel(serverId: serverId))
    }

    var body: some View {
        Group {
            if let selectedApplication = viewModel.selectedApplication {
                ApplicationDetailView(
                    application: selectedApplication,
                    serverId: serverId ?? "",
                    onBack: { viewModel.deselectApplication() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                applicationsList
            }
        }
        .task {
            await viewModel.loadApplications()
        }
        .alert(item: $viewModel.appPendingUninstall) { app in
            Alert(
                title: Text("Uninstall \(app.name)?"),
                message: Text("This will remove \(app.name) from the server. This action cannot be undone."),
                primaryButton: .destructive(Text("Uninstall")) {
                    Task { await viewModel.uninstallApplication(app) }
                },
                secondaryButton: .cancel()
            )
        }
        .keyboardShortcut("r", modifiers: .command)
    }

    // MARK: - Applications List

    private var applicationsList: some View {
        ScrollView {
            LazyVStack(spacing: AXSpacing.xl) {
                // Summary Cards Row
                summaryCardsSection

                // Search & Filters
                searchFilterBar

                // Services Grid
                servicesSection
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Summary Cards

    private var summaryCardsSection: some View {
        HStack(spacing: AXSpacing.md) {
            let installedApps = viewModel.applications.filter { $0.status != .notInstalled }
            let avgScore = installedApps.isEmpty ? 0 : installedApps.map { viewModel.healthScore(for: $0) }.reduce(0, +) / installedApps.count

            SummaryStatCard(
                icon: "checkmark.circle.fill",
                title: "Running",
                value: "\(viewModel.runningApps.count)",
                subtitle: "of \(viewModel.applications.count) services",
                gradient: [Color(hex: "#10b981"), Color(hex: "#059669")],
                glowColor: Color(hex: "#10b981")
            )

            SummaryStatCard(
                icon: "xmark.circle.fill",
                title: "Stopped",
                value: "\(viewModel.stoppedApps.count)",
                subtitle: "of \(viewModel.applications.count) services",
                gradient: [Color(hex: "#6b7280"), Color(hex: "#4b5563")],
                glowColor: Color(hex: "#6b7280")
            )

            SummaryStatCard(
                icon: "power",
                title: "Auto-start",
                value: "\(viewModel.applications.filter { $0.autoStart }.count)",
                subtitle: "of \(viewModel.applications.count) services",
                gradient: [Color(hex: "#3b82f6"), Color(hex: "#2563eb")],
                glowColor: Color(hex: "#3b82f6")
            )

            SummaryStatCard(
                icon: "memorychip",
                title: "Memory",
                value: "\(Int(viewModel.applications.compactMap { $0.memoryUsage }.reduce(0, +)))",
                subtitle: "MB total usage",
                gradient: [Color(hex: "#f59e0b"), Color(hex: "#d97706")],
                glowColor: Color(hex: "#f59e0b")
            )

            SummaryStatCard(
                icon: "heart.fill",
                title: "Health",
                value: "\(avgScore)",
                subtitle: "/ 100 avg score",
                gradient: [
                    avgScore >= 80 ? Color(hex: "#10b981") : avgScore >= 50 ? Color(hex: "#f59e0b") : Color(hex: "#ef4444"),
                    avgScore >= 80 ? Color(hex: "#059669") : avgScore >= 50 ? Color(hex: "#d97706") : Color(hex: "#dc2626")
                ],
                glowColor: avgScore >= 80 ? Color(hex: "#10b981") : avgScore >= 50 ? Color(hex: "#f59e0b") : Color(hex: "#ef4444")
            )
        }
    }

    // MARK: - Search / Filter

    private var searchFilterBar: some View {
        HStack(spacing: AXSpacing.md) {
            // Modern Search Field
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.axTextMuted)

                TextField("Search services…", text: $viewModel.searchText)
                    .font(AXTypography.body)
                    .textFieldStyle(.plain)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
            )

            Spacer()

            // Filter Pills
            HStack(spacing: AXSpacing.xs) {
                ForEach(ApplicationsListViewModel.StatusFilter.allCases, id: \.rawValue) { filter in
                    ServiceFilterPill(
                        title: filter.rawValue,
                        isSelected: viewModel.statusFilter == filter,
                        accent: filterColor(for: filter)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.statusFilter = filter
                        }
                    }
                }
            }

            // Refresh Button
            Button {
                Task { await viewModel.loadApplications(forceRefresh: true) }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Refresh")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func filterColor(for filter: ApplicationsListViewModel.StatusFilter) -> Color {
        switch filter {
        case .all: return .axAccentBlue
        case .running: return .axSuccess
        case .stopped: return .axTextMuted
        case .notInstalled: return .axWarning
        }
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                VStack(spacing: AXSpacing.lg) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonServiceCard()
                    }
                }
            } else if let error = viewModel.errorMessage {
                AXPlaceholder(
                    icon: "exclamationmark.triangle",
                    title: "Discovery Failed",
                    subtitle: error
                )
                .padding(AXSpacing.xxl)
            } else if viewModel.applications.isEmpty {
                AXPlaceholder(
                    icon: "app.badge",
                    title: "No Applications Detected",
                    subtitle: "No services found on this server"
                )
                .padding(AXSpacing.xxl)
            } else if viewModel.filteredApplications.isEmpty {
                AXPlaceholder(
                    icon: "magnifyingglass",
                    title: "No Results",
                    subtitle: "No services match your search or filter"
                )
                .padding(AXSpacing.xxl)
            } else {
                // Running Services
                let running = viewModel.filteredApplications.filter { $0.isRunning }
                let stopped = viewModel.filteredApplications.filter { !$0.isRunning && $0.status != .notInstalled }
                let notInstalled = viewModel.filteredApplications.filter { $0.status == .notInstalled }

                if !running.isEmpty {
                    ServiceGroupHeader(title: "Running Services", count: running.count, color: .axSuccess)

                    VStack(spacing: AXSpacing.sm) {
                        ForEach(running) { app in
                            ServiceCard(
                                application: app,
                                onStart: { await viewModel.startApplication(app) },
                                onStop: { await viewModel.stopApplication(app) },
                                onRestart: { await viewModel.restartApplication(app) },
                                onToggleAutoStart: { await viewModel.toggleAutoStart(app) },
                                onInstall: { await viewModel.installApplication(app) },
                                onRequestUninstall: { viewModel.appPendingUninstall = app },
                                isInstalling: viewModel.installingApplicationId == app.id,
                                installProgress: viewModel.installProgressByAppId[app.id],
                                installMessage: viewModel.installMessageByAppId[app.id],
                                onOpenDetails: { viewModel.selectApplication(app) },
                                healthScore: viewModel.healthScore(for: app),
                                healthColor: viewModel.healthColor(for: viewModel.healthScore(for: app))
                            )
                        }
                    }
                    .padding(.bottom, AXSpacing.lg)
                }

                if !stopped.isEmpty {
                    ServiceGroupHeader(title: "Stopped Services", count: stopped.count, color: .axTextMuted)

                    VStack(spacing: AXSpacing.sm) {
                        ForEach(stopped) { app in
                            ServiceCard(
                                application: app,
                                onStart: { await viewModel.startApplication(app) },
                                onStop: { await viewModel.stopApplication(app) },
                                onRestart: { await viewModel.restartApplication(app) },
                                onToggleAutoStart: { await viewModel.toggleAutoStart(app) },
                                onInstall: { await viewModel.installApplication(app) },
                                onRequestUninstall: { viewModel.appPendingUninstall = app },
                                isInstalling: viewModel.installingApplicationId == app.id,
                                installProgress: viewModel.installProgressByAppId[app.id],
                                installMessage: viewModel.installMessageByAppId[app.id],
                                onOpenDetails: { viewModel.selectApplication(app) },
                                healthScore: viewModel.healthScore(for: app),
                                healthColor: viewModel.healthColor(for: viewModel.healthScore(for: app))
                            )
                        }
                    }
                    .padding(.bottom, AXSpacing.lg)
                }

                if !notInstalled.isEmpty {
                    ServiceGroupHeader(title: "Available to Install", count: notInstalled.count, color: .axWarning)

                    // 2-column grid for not-installed
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AXSpacing.sm),
                        GridItem(.flexible(), spacing: AXSpacing.sm)
                    ], spacing: AXSpacing.sm) {
                        ForEach(notInstalled) { app in
                            InstallableServiceCard(
                                application: app,
                                onInstall: { await viewModel.installApplication(app) },
                                isInstalling: viewModel.installingApplicationId == app.id,
                                installProgress: viewModel.installProgressByAppId[app.id],
                                installMessage: viewModel.installMessageByAppId[app.id]
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let gradient: [Color]
    let glowColor: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.15))
                    )

                Spacer()

                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .shadow(color: .white.opacity(0.4), radius: 4, x: 0, y: 0)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle glass overlay
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(color: glowColor.opacity(isHovered ? 0.4 : 0.15), radius: isHovered ? 16 : 8, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Filter Pill

private struct ServiceFilterPill: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(isSelected ? accent : (isHovered ? accent.opacity(0.1) : Color.axSurface))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(isSelected ? Color.clear : Color.axBorder.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Group Header

private struct ServiceGroupHeader: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 4)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            Text("(\(count))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextMuted)

            Rectangle()
                .fill(Color.axBorder.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.bottom, AXSpacing.sm)
    }
}

// MARK: - Skeleton Loading Card

private struct SkeletonServiceCard: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.axSurface)
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.axSurface)
                    .frame(width: 80, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurface)
                .frame(width: 60, height: 24)
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface.opacity(0.3))
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Service Card (Running / Stopped — Premium Design)

struct ServiceCard: View {
    let application: ApplicationInstance
    let onStart: () async -> Void
    let onStop: () async -> Void
    let onRestart: () async -> Void
    let onToggleAutoStart: () async -> Void
    let onInstall: () async -> Void
    let onRequestUninstall: () -> Void
    let isInstalling: Bool
    let installProgress: Double?
    let installMessage: String?
    let onOpenDetails: () -> Void
    var healthScore: Int = 0
    var healthColor: Color = .axTextMuted

    @State private var isProcessing = false
    @State private var localAutoStart: Bool
    @State private var isHovered = false

    init(
        application: ApplicationInstance,
        onStart: @escaping () async -> Void,
        onStop: @escaping () async -> Void,
        onRestart: @escaping () async -> Void,
        onToggleAutoStart: @escaping () async -> Void,
        onInstall: @escaping () async -> Void,
        onRequestUninstall: @escaping () -> Void,
        isInstalling: Bool = false,
        installProgress: Double? = nil,
        installMessage: String? = nil,
        onOpenDetails: @escaping () -> Void,
        healthScore: Int = 0,
        healthColor: Color = .axTextMuted
    ) {
        self.application = application
        self.onStart = onStart
        self.onStop = onStop
        self.onRestart = onRestart
        self.onToggleAutoStart = onToggleAutoStart
        self.onInstall = onInstall
        self.onRequestUninstall = onRequestUninstall
        self.isInstalling = isInstalling
        self.installProgress = installProgress
        self.installMessage = installMessage
        self.onOpenDetails = onOpenDetails
        self.healthScore = healthScore
        self.healthColor = healthColor
        self._localAutoStart = State(initialValue: application.autoStart)
    }

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            // App Icon with Status Glow
            serviceIcon

            // Name + Version + Status
            serviceInfo

            Spacer()

            // Health Score Badge
            healthBadge

            // Memory Usage
            memoryIndicator

            // Auto-start Toggle
            autoStartToggle

            // Action Buttons
            actionButtons
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axSurface)

                // Left accent border
                if application.isRunning {
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.axSuccess, Color.axSuccess.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
                }

                // Hover border glow
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .stroke(
                        isHovered ? (application.isRunning ? Color.axSuccess.opacity(0.3) : Color.axBorder.opacity(0.5)) : Color.axBorder.opacity(0.15),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 12 : 4, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: application.isRunning)
        .animation(.easeInOut(duration: 0.15), value: isProcessing)
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetails() }
    }

    // MARK: - Service Icon

    private var serviceIcon: some View {
        ZStack {
            // Background circle with brand color glow
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            application.isRunning ? brandColor.opacity(0.2) : Color.axTextMuted.opacity(0.1),
                            application.isRunning ? brandColor.opacity(0.05) : Color.axTextMuted.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)

            if let customIconName = customIconAsset {
                Image(customIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .opacity(application.isRunning ? 1.0 : 0.5)
            } else {
                Image(systemName: sfSymbolIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(application.isRunning ? brandColor : .axTextMuted)
            }

            // Running pulse indicator
            if application.isRunning {
                Circle()
                    .fill(Color.axSuccess)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.axSurface, lineWidth: 2)
                    )
                    .shadow(color: .axSuccess.opacity(0.5), radius: 3)
                    .offset(x: 18, y: -18)
            }
        }
    }

    // MARK: - Service Info

    private var serviceInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(application.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.sm) {
                // Version badge
                if let version = application.version {
                    Text("v\(version)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(4)
                }

                // Status text
                HStack(spacing: 4) {
                    Circle()
                        .fill(application.isRunning ? Color.axSuccess : Color.axTextMuted)
                        .frame(width: 5, height: 5)

                    Text(application.isRunning ? "Running" : "Stopped")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(application.isRunning ? .axSuccess : .axTextMuted)
                }

                // Port
                if let port = application.port, application.isRunning {
                    HStack(spacing: 2) {
                        Image(systemName: "network")
                            .font(.system(size: 8))
                        Text(":\(port)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.axTextTertiary)
                }
            }
        }
        .frame(minWidth: 180, alignment: .leading)
    }

    // MARK: - Health Badge

    @ViewBuilder
    private var healthBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: healthScore >= 80 ? "heart.fill" : healthScore >= 50 ? "heart" : "heart.slash")
                .font(.system(size: 9))

            Text("\(healthScore)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .foregroundColor(healthColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(healthColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(healthColor.opacity(0.2), lineWidth: 1)
                )
        )
        .frame(width: 65)
    }

    // MARK: - Memory Indicator

    @ViewBuilder
    private var memoryIndicator: some View {
        if let memory = application.memoryUsage, memory > 0 {
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.0f", memory)) MB")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextSecondary)

                GeometryReader { _ in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.axBorder.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: memory > 400 ? [.axError, .axWarning] : [.axAccentBlue, Color(hex: "#06b6d4")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, CGFloat(min(memory / 500, 1.0)) * 70), height: 4)
                    }
                }
                .frame(width: 70, height: 4)
            }
            .frame(width: 80, alignment: .trailing)
        } else {
            Text("—")
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)
                .frame(width: 80)
        }
    }

    // MARK: - Auto-start Toggle

    private var autoStartToggle: some View {
        HStack(spacing: 4) {
            Text("Auto")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextMuted)
                .fixedSize()

            Toggle("", isOn: $localAutoStart)
                .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                .frame(width: 36)
                .onChange(of: localAutoStart) { _, _ in
                    Task { await onToggleAutoStart() }
                }
                .disabled(isProcessing)
        }
        .frame(width: 90)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 6) {
            // Start/Stop
            ServiceActionBtn(
                icon: application.isRunning ? "stop.fill" : "play.fill",
                color: application.isRunning ? .axError : .axSuccess,
                isProcessing: isProcessing,
                tooltip: application.isRunning ? "Stop" : "Start"
            ) {
                isProcessing = true
                if application.isRunning { await onStop() } else { await onStart() }
                isProcessing = false
            }

            // Restart
            ServiceActionBtn(
                icon: "arrow.clockwise",
                color: .axAccentBlue,
                isProcessing: isProcessing,
                tooltip: "Restart"
            ) {
                isProcessing = true
                await onRestart()
                isProcessing = false
            }

            // Uninstall
            ServiceActionBtn(
                icon: "trash",
                color: .axError.opacity(0.7),
                isProcessing: isProcessing,
                tooltip: "Uninstall"
            ) { onRequestUninstall() }

            // Settings
            Button(action: onOpenDetails) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var brandColor: Color {
        switch application.type {
        case .nginx: return Color(hex: "#009639")
        case .apache: return Color(hex: "#D22128")
        case .phpFpm: return Color(hex: "#777BB4")
        case .mysql: return Color(hex: "#4479A1")
        case .postgresql: return Color(hex: "#336791")
        case .redis: return Color(hex: "#DC382D")
        case .mongodb: return Color(hex: "#47A248")
        case .elasticsearch: return Color(hex: "#FEC514")
        case .mariadb: return Color(hex: "#003545")
        case .nodejs: return Color(hex: "#339933")
        default: return .axAccentBlue
        }
    }

    private var customIconAsset: String? {
        switch application.type {
        case .nginx: return "nginx-logo"
        case .apache: return "apache-logo"
        case .phpFpm: return "php-logo"
        default: return nil
        }
    }

    private var sfSymbolIcon: String {
        switch application.type {
        case .nginx, .apache: return "server.rack"
        case .phpFpm: return "p.circle.fill"
        case .mysql, .postgresql, .mariadb, .cockroachdb: return "cylinder.fill"
        case .redis: return "bolt.fill"
        case .mongodb: return "leaf.fill"
        case .elasticsearch: return "magnifyingglass"
        case .sqlite: return "square.stack.3d.up.fill"
        case .cassandra: return "server.rack"
        case .nodejs: return "n.circle.fill"
        default: return "gearshape.fill"
        }
    }
}

// MARK: - Service Action Button

private struct ServiceActionBtn: View {
    let icon: String
    let color: Color
    let isProcessing: Bool
    var tooltip: String = ""
    let action: () async -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            if isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 34, height: 34)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isHovered ? .white : color)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isHovered ? color : color.opacity(0.1))
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .help(tooltip)
    }
}

// MARK: - Installable Service Card (Not Installed — Compact Grid)

private struct InstallableServiceCard: View {
    let application: ApplicationInstance
    let onInstall: () async -> Void
    let isInstalling: Bool
    let installProgress: Double?
    let installMessage: String?

    @State private var isProcessing = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axTextMuted.opacity(0.08))
                    .frame(width: 42, height: 42)

                Image(systemName: iconForType)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(application.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text("Not Installed")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axWarning)
            }

            Spacer()

            // Install Button
            if isInstalling {
                VStack(spacing: 4) {
                    ProgressView(value: installProgress ?? 0)
                        .progressViewStyle(.linear)
                        .frame(width: 60)
                        .tint(.axAccentBlue)

                    if let msg = installMessage, !msg.isEmpty {
                        Text(msg)
                            .font(.system(size: 8))
                            .foregroundColor(.axTextMuted)
                            .lineLimit(1)
                    }
                }
            } else {
                Button {
                    Task {
                        isProcessing = true
                        await onInstall()
                        isProcessing = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                        Text("Install")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#3b82f6"), Color(hex: "#2563eb")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: Color(hex: "#3b82f6").opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(
                            isHovered ? Color.axAccentBlue.opacity(0.3) : Color.axBorder.opacity(0.15),
                            lineWidth: 1
                        )
                        .overlay(
                            // Dashed border effect for "available"
                            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                .foregroundColor(Color.axBorder.opacity(0.15))
                        )
                )
        )
        .onHover { isHovered = $0 }
    }

    private var iconForType: String {
        switch application.type {
        case .mysql, .postgresql, .mariadb, .cockroachdb: return "cylinder.fill"
        case .redis: return "bolt.fill"
        case .mongodb: return "leaf.fill"
        case .elasticsearch: return "magnifyingglass"
        case .sqlite: return "square.stack.3d.up.fill"
        case .cassandra: return "server.rack"
        default: return "gearshape.fill"
        }
    }
}

#Preview {
    ApplicationsTab()
        .padding()
        .background(Color.axBackground)
}
