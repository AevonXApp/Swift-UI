//
//  DatabaseEngineDetailView.swift
//  AevonX
//
//  Detailed view for managing a specific database engine
//  Shows engine info, service controls, configuration, logs, and metrics
//

import SwiftUI
import AevonXCore

// MARK: - Database Engine Detail View

public struct DatabaseEngineDetailView: View {
    @StateObject private var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(databaseType: DatabaseType, serverId: String?) {
        _viewModel = StateObject(wrappedValue: DatabaseEngineDetailViewModel(
            databaseType: databaseType,
            serverId: serverId
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Tab Switcher
            tabSwitcher

            // Content
            ZStack {
                contentView

                // Operation progress overlay
                if viewModel.operationResult.isInProgress {
                    operationOverlay
                }
            }
        }
        .background(Color.axBackground)
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
        // Confirmation and result alerts
        .alert(item: $viewModel.activeAlert) { alertType in
            alertContent(for: alertType)
        }
        // Version picker sheet
        .sheet(isPresented: $viewModel.showInstallVersion) {
            VersionPickerSheet(viewModel: viewModel)
        }
        // Configuration editor sheet
        .sheet(isPresented: $viewModel.showConfigEditor) {
            ConfigEditorSheet(viewModel: viewModel)
        }
        // Result toast overlay
        .overlay(alignment: .top) {
            resultToast
        }
    }

    // MARK: - Alert Content

    private func alertContent(for alertType: AlertType) -> Alert {
        switch alertType {
        case .confirmStart:
            return Alert(
                title: Text("Start \(viewModel.databaseType.displayName)?"),
                message: Text("The database service will be started and begin accepting connections."),
                primaryButton: .default(Text("Start")) {
                    Task { await viewModel.startService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmStop:
            return Alert(
                title: Text("Stop \(viewModel.databaseType.displayName)?"),
                message: Text("All active connections will be terminated. Running queries will be interrupted."),
                primaryButton: .destructive(Text("Stop")) {
                    Task { await viewModel.stopService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmRestart:
            return Alert(
                title: Text("Restart \(viewModel.databaseType.displayName)?"),
                message: Text("The service will be briefly interrupted. All active connections will be dropped and re-established."),
                primaryButton: .destructive(Text("Restart")) {
                    Task { await viewModel.restartService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmInstall(let version):
            return Alert(
                title: Text("Install \(viewModel.databaseType.displayName) \(version.version)?"),
                message: Text("This will download and install version \(version.version) on the server."),
                primaryButton: .default(Text("Install")) {
                    if let selected = viewModel.selectedVersion {
                        Task { await viewModel.installVersion(selected) }
                    }
                },
                secondaryButton: .cancel()
            )
        case .confirmUpdate:
            return Alert(
                title: Text("Update \(viewModel.databaseType.displayName)?"),
                message: Text("The database engine will be updated to the latest available version. A service restart will be required."),
                primaryButton: .default(Text("Update")) {
                    Task { await viewModel.updateToLatestVersion() }
                },
                secondaryButton: .cancel()
            )
        case .confirmUninstall:
            return Alert(
                title: Text("Uninstall \(viewModel.databaseType.displayName)?"),
                message: Text("This will completely remove the database engine from the server. All databases and data may be lost. This action cannot be undone."),
                primaryButton: .destructive(Text("Uninstall")) {
                    Task { await viewModel.uninstallEngine() }
                },
                secondaryButton: .cancel()
            )
        case .operationSuccess(let msg):
            return Alert(
                title: Text("Success"),
                message: Text(msg),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissAlert()
                }
            )
        case .operationFailure(let msg):
            return Alert(
                title: Text("Error"),
                message: Text(msg),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissAlert()
                }
            )
        }
    }

    // MARK: - Operation Overlay

    private var operationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: AXSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.axAccentBlue)

                Text(viewModel.operationResult.message ?? "Working...")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if let progress = viewModel.operationResult.progress {
                    VStack(spacing: AXSpacing.xs) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.axAccentBlue)
                            .frame(width: 240)

                        Text("\(Int(progress * 100))%")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }
            .padding(AXSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .fill(Color.axSurface)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
        }
    }

    // MARK: - Result Toast

    @ViewBuilder
    private var resultToast: some View {
        if viewModel.operationResult.isSuccess || viewModel.operationResult.isFailure {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: viewModel.operationResult.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16))
                Text(viewModel.operationResult.message ?? "")
                    .font(AXTypography.subheadline)
                    .lineLimit(1)
            }
            .foregroundColor(viewModel.operationResult.isSuccess ? .axSuccess : .axError)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
                    .shadow(color: .black.opacity(0.2), radius: 8)
            )
            .padding(.top, AXSpacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: viewModel.operationResult.isSuccess)
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    viewModel.dismissAlert()
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Engine icon and name
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(viewModel.databaseType.brandColor.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: viewModel.databaseType.iconName)
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.databaseType.brandColor)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(viewModel.databaseType.displayName)
                            .font(AXTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)

                        Text(viewModel.formattedVersion)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                // Status indicator
                HStack(spacing: AXSpacing.sm) {
                    Circle()
                        .fill(viewModel.statusColor)
                        .frame(width: 8, height: 8)

                    Text(viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                        .font(AXTypography.subheadline)
                        .foregroundColor(viewModel.statusColor)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(viewModel.statusColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.full)
            }

            // Service Controls
            if viewModel.isInstalled {
                serviceControlsView
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axSurface)
    }

    // MARK: - Service Controls

    private var serviceControlsView: some View {
        HStack(spacing: AXSpacing.md) {
            // Start Button — triggers confirmation
            ServiceControlButton(
                title: "Start",
                icon: "play.fill",
                color: .axSuccess,
                isEnabled: !viewModel.isRunning && !viewModel.isOperationInProgress
            ) {
                viewModel.showStartConfirmation()
            }

            // Stop Button — triggers confirmation
            ServiceControlButton(
                title: "Stop",
                icon: "stop.fill",
                color: .axError,
                isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
            ) {
                viewModel.showStopConfirmation()
            }

            // Restart Button — triggers confirmation
            ServiceControlButton(
                title: "Restart",
                icon: "arrow.clockwise",
                color: .axWarning,
                isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
            ) {
                viewModel.showRestartConfirmation()
            }

            Divider()
                .frame(height: 40)

            // Enable/Disable on Boot — based on actual boot status
            ServiceControlButton(
                title: viewModel.isBootEnabled ? "Disable Boot" : "Enable Boot",
                icon: viewModel.isBootEnabled ? "poweroff" : "power",
                color: viewModel.isBootEnabled ? .axTextMuted : .axAccentBlue,
                isEnabled: !viewModel.isOperationInProgress
            ) {
                Task {
                    if viewModel.isBootEnabled {
                        await viewModel.disableOnBoot()
                    } else {
                        await viewModel.enableOnBoot()
                    }
                }
            }

            Spacer()

            // Refresh
            Button(action: { Task { await viewModel.loadData() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    .frame(width: 36, height: 36)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isOperationInProgress)
        }
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            TabButton(title: "Overview", icon: "chart.bar", isSelected: viewModel.activeTab == 0) {
                viewModel.activeTab = 0
            }

            TabButton(title: "Configuration", icon: "gearshape", isSelected: viewModel.activeTab == 1) {
                viewModel.activeTab = 1
            }

            TabButton(title: "Logs", icon: "doc.text", isSelected: viewModel.activeTab == 2) {
                viewModel.activeTab = 2
            }

            TabButton(title: "Optimization", icon: "gauge", isSelected: viewModel.activeTab == 3) {
                viewModel.activeTab = 3
            }

            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
        .overlay(
            Rectangle()
                .fill(Color.axBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if !viewModel.isInstalled {
            notInstalledView
        } else {
            switch viewModel.activeTab {
            case 0:
                overviewTab
            case 1:
                configurationTab
            case 2:
                logsTab
            case 3:
                optimizationTab
            default:
                overviewTab
            }
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Engine Info Card
                engineInfoCard

                // Metrics Cards
                if let metrics = viewModel.metrics {
                    metricsGrid(metrics: metrics)
                }

                // Performance Stats
                if let stats = viewModel.performanceStats {
                    performanceCard(stats: stats)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Engine Info Card

    private var engineInfoCard: some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Engine Information")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                InfoRow(label: "Type", value: viewModel.databaseType.displayName)
                InfoRow(label: "Version", value: viewModel.formattedVersion)
                InfoRow(label: "Install Path", value: viewModel.formattedInstallPath)
                InfoRow(label: "Status", value: viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                InfoRow(label: "Service", value: viewModel.isRunning ? "Running" : "Stopped")
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Metrics Grid

    private func metricsGrid(metrics: DatabaseMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            MetricCard(
                title: "Uptime",
                value: formatUptime(metrics.uptime),
                icon: "clock",
                color: .axAccentBlue
            )

            MetricCard(
                title: "Connections",
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                icon: "link",
                color: .axAccentGreen
            )

            MetricCard(
                title: "Memory",
                value: String(format: "%.1f MB", metrics.memoryUsage),
                icon: "memorychip",
                color: .axWarning
            )
        }
    }

    // MARK: - Performance Card

    private func performanceCard(stats: PerformanceStatistics) -> some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Performance Statistics")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                HStack(spacing: AXSpacing.xl) {
                    StatItem(label: "Total Queries", value: "\(stats.totalQueries)")
                    StatItem(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                    StatItem(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                    StatItem(label: "Cache Hit Ratio", value: String(format: "%.1f%%", stats.indexUsage * 100))
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Configuration Tab

    private var configurationTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Config file path
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Configuration File")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Edit") {
                                Task {
                                    await viewModel.loadConfiguration()
                                    viewModel.configEditContent = viewModel.configuration?.rawContent ?? ""
                                    viewModel.showConfigEditor = true
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        Text(viewModel.configFilePath)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    .padding(AXSpacing.lg)
                }

                // Version Management
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Version Management")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Switch Version") {
                                viewModel.showVersionSwitcher = true
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        InfoRow(label: "Current Version", value: viewModel.formattedVersion)

                        Button("Install New Version") {
                            viewModel.showInstallVersion = true
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .disabled(viewModel.isOperationInProgress)
                    }
                    .padding(AXSpacing.lg)
                }

                // Redis Security Section
                if viewModel.databaseType == .redis {
                    AXGlassCard {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Text("Security")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "lock.shield")
                                    .foregroundColor(.axAccentBlue)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text("Redis Password (requirepass)")
                                    .font(AXTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextSecondary)
                                
                                HStack(spacing: AXSpacing.sm) {
                                    SecureField("Enter password", text: $viewModel.redisPassword)
                                        .textFieldStyle(.plain)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(AXSpacing.md)
                                        .background(Color.axBackground)
                                        .cornerRadius(AXCornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(Color.axBorder, lineWidth: 1)
                                        )
                                    
                                    Button {
                                        Task {
                                            await viewModel.updateRedisPassword(newPassword: viewModel.redisPassword)
                                        }
                                    } label: {
                                        Text("Save")
                                            .font(AXTypography.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.axBackground)
                                            .padding(.horizontal, AXSpacing.lg)
                                            .padding(.vertical, AXSpacing.md)
                                            .background(Color.axAccentBlue)
                                            .cornerRadius(AXCornerRadius.md)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.isPerformingServiceAction || viewModel.redisPassword.isEmpty)
                                }
                                
                                Text("Setting a password enables the 'requirepass' directive. A restart is required.")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                        .padding(AXSpacing.lg)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Logs Tab

    private var logsTab: some View {
        VStack(spacing: 0) {
            // Log type selector
            HStack(spacing: AXSpacing.md) {
                ForEach(DatabaseEngineDetailViewModel.LogType.allCases, id: \.self) { logType in
                    Button(logType.rawValue) {
                        viewModel.selectedLogType = logType
                        Task {
                            switch logType {
                            case .error:
                                await viewModel.loadErrorLog()
                            case .slowQuery:
                                await viewModel.loadSlowQueryLog()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(viewModel.selectedLogType == logType ? .axTextPrimary : .axTextSecondary)
                }

                Spacer()

                Button("Refresh") {
                    Task {
                        switch viewModel.selectedLogType {
                        case .error:
                            await viewModel.loadErrorLog()
                        case .slowQuery:
                            await viewModel.loadSlowQueryLog()
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.axAccentBlue)
                .disabled(viewModel.isOperationInProgress)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            // Log content
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    let logContent: AevonXCore.LogContent? = {
                        switch viewModel.selectedLogType {
                        case .error: return viewModel.errorLog
                        case .slowQuery: return viewModel.slowQueryLog
                        }
                    }()

                    if let log = logContent, !log.lines.isEmpty {
                        ForEach(Array(log.lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                                .padding(.vertical, AXSpacing.xs)
                        }
                    } else {
                        Text("No logs loaded. Click 'Error Log' or 'Slow Query Log' to view.")
                            .foregroundColor(.axTextMuted)
                            .padding()
                    }
                }
                .padding(AXSpacing.lg)
            }
            .background(Color.axBackground)
        }
        .onAppear {
            Task { await viewModel.loadErrorLog() }
        }
    }

    // MARK: - Optimization Tab

    private var optimizationTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Performance Optimization")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Text("AI-powered optimization recommendations will appear here.")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)

                        Button("Analyze Performance") {
                            Task { await viewModel.analyzePerformance() }
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                        .disabled(viewModel.isOperationInProgress)
                    }
                    .padding(AXSpacing.lg)
                }

                // Optimization presets
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Quick Presets")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        VStack(spacing: AXSpacing.md) {
                            PresetButton(title: "Web Application", description: "Optimized for web workloads") {
                                Task { await viewModel.applyOptimizationPreset("Web Application") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetButton(title: "Data Warehouse", description: "Optimized for analytics") {
                                Task { await viewModel.applyOptimizationPreset("Data Warehouse") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetButton(title: "Development", description: "Balanced for development") {
                                Task { await viewModel.applyOptimizationPreset("Development") }
                            }
                            .disabled(viewModel.isOperationInProgress)
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Not Installed View

    private var notInstalledView: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()

            Image(systemName: viewModel.databaseType.iconName)
                .font(.system(size: 64))
                .foregroundColor(viewModel.databaseType.brandColor.opacity(0.5))

            Text("\(viewModel.databaseType.displayName) is not installed")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)

            Text("Install \(viewModel.databaseType.displayName) to manage it from this dashboard.")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)

            Button("Install \(viewModel.databaseType.displayName)") {
                viewModel.showInstallVersion = true
            }
            .font(AXTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.axBackground)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axAccentBlue)
            .cornerRadius(AXCornerRadius.md)
            .frame(width: 200)

            Spacer()
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundColor(.axTextMuted)
                .padding(.top)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.axError)
            Text(message)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }

    // MARK: - Helpers

    private func formatUptime(_ seconds: Double) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Version Picker Sheet

struct VersionPickerSheet: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Install \(viewModel.databaseType.displayName)")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)

            Divider()

            if viewModel.isFetchingVersions {
                VStack(spacing: AXSpacing.md) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Fetching available versions...")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                    Spacer()
                }
            } else if viewModel.availableVersions.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Spacer()
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.axTextMuted)
                    Text("No versions available")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)

                    Button("Retry") {
                        Task { await viewModel.fetchAvailableVersions() }
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axAccentBlue)

                    Spacer()
                }
                .padding(AXSpacing.xl)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.availableVersions) { version in
                            VersionRow(version: version, isCurrentVersion: version.version == viewModel.engineInfo?.version) {
                                viewModel.showInstallConfirmation(version: version)
                                dismiss()
                            }
                        }
                    }
                    .padding(AXSpacing.xl)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color.axBackground)
        .onAppear {
            Task { await viewModel.fetchAvailableVersions() }
        }
    }
}

// MARK: - Version Row

struct VersionRow: View {
    let version: AevonX.DatabaseVersion
    let isCurrentVersion: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(version.version)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    if version.isLTS {
                        Text("LTS")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axAccentBlue.opacity(0.15))
                            .cornerRadius(AXCornerRadius.xs)
                    }

                    if version.isRecommended {
                        Text("Recommended")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axAccentGreen)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axAccentGreen.opacity(0.15))
                            .cornerRadius(AXCornerRadius.xs)
                    }

                    if isCurrentVersion {
                        Text("Installed")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axTextMuted.opacity(0.15))
                            .cornerRadius(AXCornerRadius.xs)
                    }
                }

                if let date = version.releaseDate {
                    Text("Released \(date, style: .date)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            if !isCurrentVersion {
                Button("Install") {
                    onInstall()
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isCurrentVersion ? Color.axSurfaceHover : Color.axSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isCurrentVersion ? Color.axAccentBlue.opacity(0.3) : Color.axBorder, lineWidth: 1)
        )
    }
}

// MARK: - Config Editor Sheet

struct ConfigEditorSheet: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Configuration")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                HStack(spacing: AXSpacing.md) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundColor(.axTextSecondary)

                    Button(action: {
                        Task {
                            await viewModel.saveConfiguration(content: viewModel.configEditContent)
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)

            Divider()

            // File path info
            HStack {
                Text(viewModel.configFilePath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)

            // Editor
            TextEditor(text: $viewModel.configEditContent)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(AXSpacing.md)
                .background(Color.axBackground)
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color.axBackground)
        .onAppear {
            Task {
                await viewModel.loadConfiguration()
                viewModel.configEditContent = viewModel.configuration?.rawContent ?? "# No configuration loaded"
            }
        }
    }
}

// MARK: - Supporting Views

struct ServiceControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(AXTypography.caption2)
            }
            .foregroundColor(isEnabled ? color : .axTextMuted)
            .frame(width: 70, height: 50)
            .background(isEnabled ? color.opacity(0.1) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isEnabled ? color.opacity(0.3) : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)

            Spacer()

            Text(value)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        AXGlassCard {
            VStack(spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(value)
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Text(title)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AXSpacing.lg)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: AXSpacing.xxs) {
            Text(value)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
    }
}

struct PresetButton: View {
    let title: String
    let description: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(title)
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)

                    Text(description)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DatabaseEngineDetailView(databaseType: .mysql, serverId: "test-server")
        .frame(width: 900, height: 700)
}
