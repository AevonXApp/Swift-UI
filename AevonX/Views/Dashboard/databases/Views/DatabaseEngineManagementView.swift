//
//  DatabaseEngineManagementView.swift
//  AevonX
//
//  Full-page database engine management view
//  State-driven navigation, no push/pop stack
//

import SwiftUI
import AevonXCore

// MARK: - Database Engine Management View

public struct DatabaseEngineManagementView: View {
    @StateObject private var viewModel: DatabaseEngineDetailViewModel
    let onBack: () -> Void

    public init(databaseType: DatabaseType, serverId: String?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DatabaseEngineDetailViewModel(
            databaseType: databaseType,
            serverId: serverId
        ))
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Sidebar Navigation
                sidebar
                    .frame(width: 240)
                    .background(Color.axSurface)

                Divider()

                // Main Content Area
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.axBackground)
            }

            // Operation progress overlay
            if viewModel.operationResult.isInProgress {
                operationOverlay
            }
        }
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

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Header with back button
            sidebarHeader

            Divider()

            // Navigation Sections
            ScrollView {
                VStack(spacing: AXSpacing.xs) {
                    ForEach(DatabaseEngineDetailViewModel.Section.allCases) { section in
                        // Skip Access section for Redis as it doesn't support user management
                        if section != .access || viewModel.databaseType != .redis {
                            NavigationRow(
                                title: section.rawValue,
                                icon: section.icon,
                                isSelected: viewModel.currentSection == section
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.currentSection = section
                                }
                            }
                        }
                    }
                }
                .padding(AXSpacing.md)
            }

            Spacer()

            // Service Status Footer
            serviceStatusFooter
        }
    }

    // MARK: - Sidebar Header

    private var sidebarHeader: some View {
        VStack(spacing: AXSpacing.lg) {
            // Back Button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Back to Databases")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Engine Info
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
                        .font(AXTypography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Text(viewModel.formattedVersion)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()
            }
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Service Status Footer

    private var serviceStatusFooter: some View {
        VStack(spacing: AXSpacing.md) {
            Divider()

            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(viewModel.statusColor)
                    .frame(width: 8, height: 8)

                Text(viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                    .font(AXTypography.caption)
                    .foregroundColor(viewModel.statusColor)

                Spacer()
            }

            // Quick Service Controls — wired to confirmations
            HStack(spacing: AXSpacing.sm) {
                ServiceButton(
                    icon: "play.fill",
                    color: .axSuccess,
                    isEnabled: !viewModel.isRunning && !viewModel.isOperationInProgress
                ) {
                    viewModel.showStartConfirmation()
                }

                ServiceButton(
                    icon: "stop.fill",
                    color: .axError,
                    isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
                ) {
                    viewModel.showStopConfirmation()
                }

                ServiceButton(
                    icon: "arrow.clockwise",
                    color: .axWarning,
                    isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
                ) {
                    viewModel.showRestartConfirmation()
                }
            }
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.currentSection {
        case .overview:
            OverviewSection(viewModel: viewModel)
        case .configuration:
            ConfigurationSection(viewModel: viewModel)
        case .logs:
            LogsSection(viewModel: viewModel)
        case .optimization:
            OptimizationSection(viewModel: viewModel)
        case .versions:
            VersionsSection(viewModel: viewModel)
        case .access:
            AccessSection(viewModel: viewModel)
        }
    }
}

// MARK: - Navigation Row

private struct NavigationRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                    .frame(width: 24)

                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Service Button

private struct ServiceButton: View {
    let icon: String
    let color: Color
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isEnabled ? color : .axTextMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isEnabled ? color.opacity(0.1) : Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Overview Section

private struct OverviewSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Overview")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.loadData() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.axTextSecondary)
                            .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                            .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else {
                    // Engine Info Card
                    EngineInfoCard(viewModel: viewModel)

                    // Metrics Grid
                    if let metrics = viewModel.metrics {
                        MetricsGrid(metrics: metrics)
                    }

                    // Performance Stats
                    if let stats = viewModel.performanceStats {
                        PerformanceCard(stats: stats)
                    }

                    // Danger Zone
                    AXGlassCard {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Text("Danger Zone")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axError)
                                
                                Spacer()
                                
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.axError)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.md) {
                                Text("Uninstalling the engine will remove all binaries and may result in partial or total data loss if backups are not maintained.")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextSecondary)
                                
                                Button(role: .destructive) {
                                    viewModel.showUninstallConfirmation()
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Uninstall \(viewModel.databaseType.displayName)")
                                    }
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.axBackground)
                                    .padding(.horizontal, AXSpacing.xl)
                                    .padding(.vertical, AXSpacing.md)
                                    .background(Color.axError)
                                    .cornerRadius(AXCornerRadius.md)
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.isOperationInProgress)
                            }
                        }
                        .padding(AXSpacing.lg)
                    }
                    .padding(.top, AXSpacing.xl)
                }
            }
            .padding(AXSpacing.xl)
        }
    }
}

// MARK: - Configuration Section

private struct ConfigurationSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Configuration")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()
                }

                // Config File Path
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
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        Text(viewModel.configFilePath)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.axTextMuted)
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
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        DBEMInfoRow(label: "Current Version", value: viewModel.formattedVersion)

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
}

// MARK: - Logs Section

private struct LogsSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Logs")
                    .font(AXTypography.title)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                // Log Type Selector
                HStack(spacing: 0) {
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
                        .font(AXTypography.subheadline)
                        .fontWeight(viewModel.selectedLogType == logType ? .semibold : .regular)
                        .foregroundColor(viewModel.selectedLogType == logType ? .axAccentBlue : .axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(viewModel.selectedLogType == logType ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                        .cornerRadius(AXCornerRadius.md)
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)

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
                .font(AXTypography.subheadline)
                .foregroundColor(.axAccentBlue)
                .padding(.leading, AXSpacing.md)
                .disabled(viewModel.isOperationInProgress)
            }
            .padding(AXSpacing.xl)

            Divider()

            // Log Content
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
                        Text("No logs loaded. Click 'Refresh' to load logs.")
                            .foregroundColor(.axTextMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AXSpacing.xl)
                    }
                }
                .padding(AXSpacing.lg)
            }
        }
        .onAppear {
            Task { await viewModel.loadErrorLog() }
        }
    }
}

// MARK: - Optimization Section

private struct OptimizationSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Optimization")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()
                }

                // AI Analysis Card
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Performance Analysis")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Text("AI-powered optimization recommendations will appear here based on your database usage patterns.")
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

                // Quick Presets
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Quick Presets")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        VStack(spacing: AXSpacing.md) {
                            PresetRow(title: "Web Application", description: "Optimized for web workloads with high read/write ratio") {
                                Task { await viewModel.applyOptimizationPreset("Web Application") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetRow(title: "Data Warehouse", description: "Optimized for analytics and reporting workloads") {
                                Task { await viewModel.applyOptimizationPreset("Data Warehouse") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetRow(title: "Development", description: "Balanced configuration for development environments") {
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
}

// MARK: - Versions Section

private struct VersionsSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Versions")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.fetchAvailableVersions() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text("Refresh")
                                .font(AXTypography.subheadline)
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                // Current Version
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Current Version")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        HStack {
                            Text(viewModel.formattedVersion)
                                .font(AXTypography.title3)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Text(viewModel.isRunning ? "Active" : "Stopped")
                                .font(AXTypography.caption)
                                .foregroundColor(viewModel.isRunning ? .axSuccess : .axWarning)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxs)
                                .background((viewModel.isRunning ? Color.axSuccess : Color.axWarning).opacity(0.1))
                                .cornerRadius(AXCornerRadius.full)
                        }
                    }
                    .padding(AXSpacing.lg)
                }

                // Available Versions
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Available Versions")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Update to Latest") {
                                viewModel.showUpdateConfirmation()
                            }
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        if viewModel.isFetchingVersions {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(AXSpacing.xl)
                                Spacer()
                            }
                        } else if viewModel.availableVersions.isEmpty {
                            VStack(spacing: AXSpacing.md) {
                                Text("No versions fetched yet.")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextMuted)

                                Button("Fetch Available Versions") {
                                    Task { await viewModel.fetchAvailableVersions() }
                                }
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axAccentBlue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AXSpacing.lg)
                        } else {
                            ForEach(viewModel.availableVersions) { version in
                                HStack(spacing: AXSpacing.md) {
                                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                        HStack(spacing: AXSpacing.sm) {
                                            Text(version.version)
                                                .font(AXTypography.subheadline)
                                                .fontWeight(.semibold)
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

                                            if version.version == viewModel.engineInfo?.version {
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

                                    if version.version != viewModel.engineInfo?.version {
                                        Button("Install") {
                                            viewModel.showInstallConfirmation(version: version)
                                        }
                                        .font(AXTypography.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.xs)
                                        .background(Color.axAccentBlue.opacity(0.1))
                                        .cornerRadius(AXCornerRadius.md)
                                        .buttonStyle(.plain)
                                        .disabled(viewModel.isOperationInProgress)
                                    }
                                }
                                .padding(.vertical, AXSpacing.sm)

                                if version.id != viewModel.availableVersions.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            if viewModel.availableVersions.isEmpty {
                Task { await viewModel.fetchAvailableVersions() }
            }
        }
    }
}

// MARK: - Access Section

private struct AccessSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Access & Permissions")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.loadUsers() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text("Refresh")
                                .font(AXTypography.subheadline)
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                // Users Management
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Database Users")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()
                        }

                        Divider()

                        if viewModel.isLoadingUsers {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(AXSpacing.lg)
                                Spacer()
                            }
                        } else if let error = viewModel.userLoadError {
                            Text(error)
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axError)
                        } else if viewModel.databaseUsers.isEmpty {
                            Text("No users found or user listing not supported for this engine.")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextMuted)
                        } else {
                            ForEach(viewModel.databaseUsers) { user in
                                HStack(spacing: AXSpacing.md) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.axAccentBlue)

                                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                        Text(user.username)
                                            .font(AXTypography.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.axTextPrimary)

                                        Text("@\(user.host)")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextMuted)
                                    }

                                    Spacer()

                                    if user.isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.axWarning)
                                    }

                                    if user.sslRequired {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.axAccentGreen)
                                    }

                                    if !user.privileges.isEmpty {
                                        Text("\(user.privileges.count) privileges")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextMuted)
                                    }
                                }
                                .padding(.vertical, AXSpacing.sm)

                                if user.id != viewModel.databaseUsers.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            Task { await viewModel.loadUsers() }
        }
    }
}

// MARK: - Supporting Views

private struct EngineInfoCard: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Engine Information")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                DBEMInfoRow(label: "Type", value: viewModel.databaseType.displayName)
                DBEMInfoRow(label: "Version", value: viewModel.formattedVersion)
                DBEMInfoRow(label: "Install Path", value: viewModel.formattedInstallPath)
                DBEMInfoRow(label: "Status", value: viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                DBEMInfoRow(label: "Service", value: viewModel.isRunning ? "Running" : "Stopped")
                DBEMInfoRow(label: "Boot", value: viewModel.isBootEnabled ? "Enabled" : "Disabled")
                DBEMInfoRow(label: "Config File", value: viewModel.configFilePath)
            }
            .padding(AXSpacing.lg)
        }
    }
}

private struct MetricsGrid: View {
    let metrics: AevonXCore.DatabaseMetrics

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            DBEMMetricCard(
                title: "Uptime",
                value: formatUptime(metrics.uptime),
                icon: "clock",
                color: .axAccentBlue
            )

            DBEMMetricCard(
                title: "Connections",
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                icon: "link",
                color: .axAccentGreen
            )

            DBEMMetricCard(
                title: "Memory",
                value: String(format: "%.1f MB", metrics.memoryUsage),
                icon: "memorychip",
                color: .axWarning
            )
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
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

private struct PerformanceCard: View {
    let stats: AevonXCore.PerformanceStatistics

    var body: some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Performance Statistics")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                HStack(spacing: AXSpacing.xl) {
                    StatColumn(label: "Total Queries", value: "\(stats.totalQueries)")
                    StatColumn(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                    StatColumn(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                    StatColumn(label: "Cache Hit", value: String(format: "%.1f%%", stats.indexUsage * 100))
                }
            }
            .padding(AXSpacing.lg)
        }
    }
}

private struct DBEMMetricCard: View {
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

private struct StatColumn: View {
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

private struct DBEMInfoRow: View {
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

private struct PresetRow: View {
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

private struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.axError)

            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Preview

#Preview {
    DatabaseEngineManagementView(
        databaseType: .mysql,
        serverId: "test-server",
        onBack: {}
    )
    .frame(width: 1200, height: 800)
}
