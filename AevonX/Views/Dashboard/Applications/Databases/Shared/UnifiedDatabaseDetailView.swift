//
//  UnifiedDatabaseDetailView.swift
//  AevonX
//
//  Unified detail view for ALL database engines with FULL functionality
//  Integrates DatabaseEngineDetailViewModel functionality directly
//

import SwiftUI
import AevonXCore

struct UnifiedDatabaseDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let application: ApplicationInstance
    let databaseType: DatabaseType
    let serverId: String
    let onBack: (() -> Void)?

    // ViewModel integration
    @StateObject private var viewModel: DatabaseEngineDetailViewModel

    @State private var selectedSection: DatabaseSection = .overview
    @State private var showConfigEditor = false
    @State private var editedConfig: String = ""
    
    private var availableSections: [DatabaseSection] {
        DatabaseSection.allCases.filter { section in
            if section == .access {
                return viewModel.supportsUserManagement
            }
            return true
        }
    }

    init(application: ApplicationInstance, databaseType: DatabaseType, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.databaseType = databaseType
        self.serverId = serverId
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: DatabaseEngineDetailViewModel(databaseType: databaseType, serverId: serverId))
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                    .frame(width: 260)

                Divider()

                // Content
                contentView
            }

            // Operation overlay
            if viewModel.operationResult.isInProgress {
                operationOverlay
            }

            if showConfigEditor {
                modalOverlay {
                    configEditorSheet
                }
            }

            if viewModel.showInstallVersion {
                modalOverlay {
                    versionPickerSheet
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .alert(item: $viewModel.activeAlert) { alertType in
            alertContent(for: alertType)
        }
        .overlay(alignment: .top) {
            resultToast
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Button(action: { handleBack() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                        Text("Applications")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(databaseType.brandColor.opacity(0.15))

                        Image(systemName: databaseType.iconName)
                            .font(.system(size: 24))
                            .foregroundColor(databaseType.brandColor)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(application.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.axTextPrimary)

                        if let version = viewModel.engineInfo?.version {
                            Text(version)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.axTextMuted)
                                .monospaced()
                        }
                    }
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)

            Divider()

            // Navigation
            ScrollView {
                VStack(spacing: AXSpacing.xs) {
                    ForEach(availableSections, id: \.rawValue) { section in
                        sidebarButton(for: section)
                    }
                }
                .padding(AXSpacing.md)
            }

            Spacer()

            // Service Controls
            serviceControls
        }
        .background(Color.axSurface.opacity(0.4))
    }

    private func sidebarButton(for section: DatabaseSection) -> some View {
        Button(action: {
            selectedSection = section
        }) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                    .foregroundColor(selectedSection == section ? .axAccentBlue : .axTextMuted)
                    .frame(width: 20)

                Text(section.displayName)
                    .font(AXTypography.subheadline)
                    .fontWeight(selectedSection == section ? .semibold : .medium)
                    .foregroundColor(selectedSection == section ? .axTextPrimary : .axTextSecondary)

                Spacer()

                if selectedSection == section {
                    Circle()
                        .fill(Color.axAccentBlue)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(selectedSection == section ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var serviceControls: some View {
        VStack(spacing: AXSpacing.md) {
            Divider()

            // Status indicator
            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(viewModel.statusColor)
                    .frame(width: 6, height: 6)

                Text(viewModel.isRunning ? "Running" : "Stopped")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextSecondary)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.sm)

            // Control buttons
            HStack(spacing: AXSpacing.sm) {
                serviceButton(
                    icon: "play.fill",
                    color: .axSuccess,
                    enabled: !viewModel.isRunning
                ) {
                    viewModel.showStartConfirmation()
                }

                serviceButton(
                    icon: "stop.fill",
                    color: .axError,
                    enabled: viewModel.isRunning
                ) {
                    viewModel.showStopConfirmation()
                }

                serviceButton(
                    icon: "arrow.clockwise",
                    color: .axAccentBlue,
                    enabled: viewModel.isRunning
                ) {
                    viewModel.showRestartConfirmation()
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
    }

    private func serviceButton(icon: String, color: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(enabled ? color : .axTextMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(enabled ? color.opacity(0.1) : Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
        .disabled(!enabled || viewModel.isOperationInProgress)
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                contentForSelectedSection
            }
            .padding(AXSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }

    @ViewBuilder
    private var contentForSelectedSection: some View {
        switch selectedSection {
        case .overview:
            overviewContent
        case .configuration:
            configurationContent
        case .logs:
            logsContent
        case .versions:
            versionsContent
        case .optimization:
            optimizationContent
        case .access:
            accessContent
        }
    }

    // MARK: - Overview Tab

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header with refresh button
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
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isOperationInProgress)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                // Engine Info Card
                engineInfoCard

                // Metrics Grid
                if let metrics = viewModel.metrics {
                    metricsGrid(metrics: metrics)
                }

                // Performance Stats
                if let stats = viewModel.performanceStats {
                    performanceCard(stats: stats)
                }

                // Danger Zone
                dangerZoneCard
            }
        }
    }

    private var engineInfoCard: some View {
        cardView(title: "Engine Information") {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                infoRow(label: "Type", value: databaseType.displayName)
                infoRow(label: "Version", value: viewModel.formattedVersion)
                infoRow(label: "Install Path", value: viewModel.formattedInstallPath)
                infoRow(label: "Status", value: viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                infoRow(label: "Service", value: viewModel.isRunning ? "Running" : "Stopped")
                infoRow(label: "Boot", value: viewModel.isBootEnabled ? "Enabled" : "Disabled")
                infoRow(label: "Config File", value: viewModel.configFilePath)
            }
        }
    }

    private func metricsGrid(metrics: AevonXCore.DatabaseMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            metricCard(
                title: "Uptime",
                value: viewModel.formattedUptime,
                icon: "clock",
                color: databaseType.brandColor
            )

            metricCard(
                title: "Connections",
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                icon: "link",
                color: .axAccentGreen
            )

            metricCard(
                title: "Memory",
                value: viewModel.formattedMemoryUsage,
                icon: "memorychip",
                color: .axWarning
            )
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
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
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func performanceCard(stats: AevonXCore.PerformanceStatistics) -> some View {
        cardView(title: "Performance Statistics") {
            HStack(spacing: AXSpacing.xl) {
                statColumn(label: "Total Queries", value: "\(stats.totalQueries)")
                statColumn(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                statColumn(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                statColumn(label: "Cache Hit", value: String(format: "%.1f%%", stats.indexUsage * 100))
            }
        }
    }

    private func statColumn(label: String, value: String) -> some View {
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

    private var dangerZoneCard: some View {
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
                Text("Uninstalling the engine will remove all binaries and may result in data loss if backups are not maintained.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)

                Button(role: .destructive) {
                    viewModel.showUninstallConfirmation()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Uninstall \(databaseType.displayName)")
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
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axError.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, AXSpacing.xl)
    }

    // MARK: - Configuration Tab

    private var configurationContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header
            Text("Configuration")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            // Config File Path
            cardView(title: "Configuration File") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Text(viewModel.configFilePath)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.axTextMuted)

                        Spacer()

                        Button("Edit") {
                            Task {
                                await viewModel.loadConfiguration()
                                editedConfig = viewModel.configuration?.rawContent ?? ""
                                showConfigEditor = true
                            }
                        }
                        .font(AXTypography.subheadline)
                        .foregroundColor(databaseType.brandColor)
                        .disabled(viewModel.isOperationInProgress)
                    }
                }
            }

            // Version Management
            cardView(title: "Version Management") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    infoRow(label: "Current Version", value: viewModel.formattedVersion)

                    Button("Install New Version") {
                        Task {
                            selectedSection = .versions
                            await viewModel.fetchAvailableVersions()
                        }
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .disabled(viewModel.isOperationInProgress)
                }
            }

            // Redis Security Section
            if databaseType == .redis {
                redisSecurityCard
            }
        }
    }

    private var redisSecurityCard: some View {
        cardView(title: "Security") {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(databaseType.brandColor)

                    Text("Redis Password (requirepass)")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)

                    Spacer()
                }

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
                            .background(databaseType.brandColor)
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
    }

    // MARK: - Logs Tab

    private var logsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Logs")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            // Advanced Logs Viewer
            AXAdvancedLogsView(
                source: logSourceForDatabaseType(databaseType),
                serverId: serverId
            )
            .frame(minHeight: 600)
        }
    }

    private func logSourceForDatabaseType(_ type: DatabaseType) -> AXLogSource {
        switch type {
        case .mysql: return .mysqlService
        case .postgresql: return .postgresqlService
        case .redis: return .redisService
        case .mongodb: return .mongodbService
        case .mariadb: return .mariadbService
        case .cockroachdb: return .cockroachdbService
        case .cassandra: return .cassandraService
        case .elasticsearch: return .elasticsearchService
        default: return .genericService(name: type.displayName, path: "N/A")
        }
    }

    // MARK: - Versions Tab

    private var versionsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Version Management")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            cardView(title: "Current Version") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    infoRow(label: "Installed Version", value: viewModel.formattedVersion)
                    infoRow(label: "Install Path", value: viewModel.formattedInstallPath)

                    Button("Check for Updates") {
                        Task {
                            await viewModel.fetchAvailableVersions()
                        }
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(databaseType.brandColor)
                    .cornerRadius(AXCornerRadius.md)
                    .disabled(viewModel.isFetchingVersions)
                }
            }

            cardView(title: "Available Versions") {
                Group {
                    if viewModel.isFetchingVersions {
                        HStack {
                            ProgressView()
                            Text("Checking available versions...")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                    } else if viewModel.availableVersions.isEmpty {
                        Text("No versions found. Click 'Check for Updates' to fetch from server repositories.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    } else {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(viewModel.availableVersions) { version in
                                versionRow(version: version)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Optimization Tab

    private var optimizationContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Performance Optimization")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            // Performance Analysis
            cardView(title: "Performance Analysis") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    if let stats = viewModel.performanceStats {
                        infoRow(label: "Total Queries", value: "\(stats.totalQueries)")
                        infoRow(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                        infoRow(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                        infoRow(label: "Cache Hit Rate", value: String(format: "%.1f%%", stats.indexUsage * 100))
                    }

                    Button("Analyze Performance") {
                        Task {
                            await viewModel.analyzePerformance()
                        }
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(databaseType.brandColor)
                    .cornerRadius(AXCornerRadius.md)
                    .disabled(viewModel.isAnalyzingPerformance)
                }
            }

            // Optimization Presets
            cardView(title: "Optimization Presets") {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    ForEach(["Web Application", "Data Warehouse", "Development"], id: \.self) { preset in
                        Button(preset) {
                            Task {
                                await viewModel.applyOptimizationPreset(preset)
                            }
                        }
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axSurface.opacity(0.5))
                        .cornerRadius(AXCornerRadius.sm)
                        .disabled(viewModel.isOperationInProgress)
                    }
                }
            }
        }
    }

    // MARK: - Access Tab

    private var accessContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("User Access Control")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            cardView(title: "Database Users") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    if !viewModel.supportsUserManagement {
                        Text("\(databaseType.displayName) does not support user management in this panel.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    } else if viewModel.isLoadingUsers {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.userLoadError {
                        Text(error)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                    } else if viewModel.databaseUsers.isEmpty {
                        Text("No users found")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    } else {
                        ForEach(viewModel.databaseUsers, id: \.username) { user in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.axAccentBlue)
                                Text(user.username)
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                            }
                            .padding(.vertical, AXSpacing.xs)
                        }
                    }

                    Button("Refresh Users") {
                        Task {
                            await viewModel.loadUsers()
                        }
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(databaseType.brandColor)
                    .cornerRadius(AXCornerRadius.md)
                    .disabled(viewModel.isLoadingUsers || !viewModel.supportsUserManagement)
                }
            }
        }
        .task {
            // Auto-load users when tab is opened
            if viewModel.supportsUserManagement {
                await viewModel.loadUsers()
            }
        }
    }

    // MARK: - Helper Views

    private func cardView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(title)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            Divider()

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)

            Spacer()

            Text(value)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
        }
    }

    private func errorView(message: String) -> some View {
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

    // MARK: - Alert Content

    private func alertContent(for alertType: AlertType) -> Alert {
        switch alertType {
        case .confirmStart:
            return Alert(
                title: Text("Start \(databaseType.displayName)?"),
                message: Text("The database service will be started and begin accepting connections."),
                primaryButton: .default(Text("Start")) {
                    Task { await viewModel.startService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmStop:
            return Alert(
                title: Text("Stop \(databaseType.displayName)?"),
                message: Text("All active connections will be terminated. Running queries will be interrupted."),
                primaryButton: .destructive(Text("Stop")) {
                    Task { await viewModel.stopService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmRestart:
            return Alert(
                title: Text("Restart \(databaseType.displayName)?"),
                message: Text("The service will be briefly interrupted. All active connections will be dropped."),
                primaryButton: .destructive(Text("Restart")) {
                    Task { await viewModel.restartService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmInstall(let version):
            return Alert(
                title: Text("Install \(databaseType.displayName) \(version.version)?"),
                message: Text("This will download and install version \(version.version) on the server."),
                primaryButton: .default(Text("Install")) {
                    Task { await viewModel.installVersion(version) }
                },
                secondaryButton: .cancel()
            )
        case .confirmUpdate:
            return Alert(
                title: Text("Update \(databaseType.displayName)?"),
                message: Text("The database engine will be updated to the latest version."),
                primaryButton: .default(Text("Update")) {
                    Task { await viewModel.updateToLatestVersion() }
                },
                secondaryButton: .cancel()
            )
        case .confirmUninstall:
            return Alert(
                title: Text("Uninstall \(databaseType.displayName)?"),
                message: Text("This will completely remove the database engine. This action cannot be undone."),
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
                    .tint(databaseType.brandColor)

                Text(viewModel.operationResult.message ?? "Working...")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if let progress = viewModel.operationResult.progress {
                    VStack(spacing: AXSpacing.xs) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(databaseType.brandColor)
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
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    viewModel.dismissAlert()
                }
            }
        }
    }

    // MARK: - Config Editor Sheet

    private var configEditorSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Configuration")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button("Cancel") {
                    showConfigEditor = false
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)

            Divider()

            // Editor
            TextEditor(text: $editedConfig)
                .font(.system(.body, design: .monospaced))
                .padding()

            Divider()

            // Footer
            HStack {
                Button("Reset") {
                    editedConfig = viewModel.configuration?.rawContent ?? ""
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    Task {
                        await viewModel.saveConfiguration(content: editedConfig)
                        showConfigEditor = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isPerformingServiceAction)
            }
            .padding()
            .background(Color.axSurface)
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - Version Picker Sheet

    private var versionPickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Install Version")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button("Cancel") {
                    viewModel.showInstallVersion = false
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)

            Divider()

            // Version List
            if viewModel.isFetchingVersions {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.availableVersions.isEmpty {
                VStack(spacing: AXSpacing.lg) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextMuted)
                    Text("No versions available")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.availableVersions) { version in
                            versionRow(version: version)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 500, height: 600)
    }

    private func modalOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    showConfigEditor = false
                    viewModel.showInstallVersion = false
                }

            content()
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
        }
    }

    private func versionRow(version: AevonX.DatabaseVersion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(version.version)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    if version.isRecommended {
                        Text("Recommended")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axSuccess)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.axSuccess.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if version.isLTS {
                        Text("LTS")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                if let date = version.releaseDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            Button("Install") {
                viewModel.showInstallConfirmation(version: version)
                viewModel.showInstallVersion = false
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isOperationInProgress)
        }
        .padding()
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    UnifiedDatabaseDetailView(
        application: ApplicationInstance(
            name: "MySQL",
            type: .mysql,
            version: "8.0.35",
            isRunning: true
        ),
        databaseType: .mysql,
        serverId: "test"
    )
    .frame(width: 1200, height: 800)
}
