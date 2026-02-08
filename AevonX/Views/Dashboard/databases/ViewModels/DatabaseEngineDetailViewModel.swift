//
//  DatabaseEngineDetailViewModel.swift
//  AevonX
//
//  ViewModel for detailed database engine management
//  Handles all engine-specific operations and state with full Core integration
//

import Foundation
import SwiftUI
import Combine
import AevonXCore

// MARK: - Operation Result

/// Represents the result of an operation
public enum OperationResult: Equatable {
    case idle
    case inProgress(message: String, progress: Double?)
    case success(message: String)
    case failure(message: String)
    
    public var isInProgress: Bool {
        if case .inProgress = self { return true }
        return false
    }
    
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
    
    public var message: String? {
        switch self {
        case .idle: return nil
        case .inProgress(let msg, _): return msg
        case .success(let msg): return msg
        case .failure(let msg): return msg
        }
    }
    
    public var progress: Double? {
        if case .inProgress(_, let progress) = self { return progress }
        return nil
    }
}

// MARK: - Alert Type

/// Types of alerts that can be shown
public enum AlertType: Identifiable {
    case confirmRestart
    case confirmStop
    case confirmStart
    case confirmInstall(version: AevonX.DatabaseVersion)
    case confirmUpdate
    case confirmUninstall
    case operationSuccess(message: String)
    case operationFailure(message: String)
    
    public var id: String {
        switch self {
        case .confirmRestart: return "confirmRestart"
        case .confirmStop: return "confirmStop"
        case .confirmStart: return "confirmStart"
        case .confirmInstall(let v): return "confirmInstall-\(v.version)"
        case .confirmUpdate: return "confirmUpdate"
        case .confirmUninstall: return "confirmUninstall"
        case .operationSuccess(let msg): return "success-\(msg)"
        case .operationFailure(let msg): return "failure-\(msg)"
        }
    }
}

// MARK: - Database Engine Detail ViewModel

@MainActor
public final class DatabaseEngineDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The database type being managed
    public let databaseType: DatabaseType
    
    /// Engine information
    @Published public var engineInfo: DatabaseEngineInfo?
    
    /// Loading state
    @Published public var isLoading = false
    
    /// Error message
    @Published public var errorMessage: String?
    
    /// Current metrics (from Core layer)
    @Published public var metrics: AevonXCore.DatabaseMetrics?
    
    /// Performance statistics (from Core layer)
    @Published public var performanceStats: AevonXCore.PerformanceStatistics?
    
    /// Error log content (from Core layer)
    @Published public var errorLog: AevonXCore.LogContent?
    
    /// Slow query log content (from Core layer)
    @Published public var slowQueryLog: AevonXCore.LogContent?
    
    /// Configuration content (from Core layer)
    @Published public var configuration: AevonXCore.DatabaseConfiguration?
    
    /// Available versions for this engine (using UI layer type)
    @Published public var availableVersions: [AevonX.DatabaseVersion] = []
    
    /// Server resources (CPU, Memory, Disk)
    @Published public var serverResources: ServerResources?
    
    /// Server OS information
    @Published public var serverOSInfo: ServerOSInfo?
    
    /// Current operation result
    @Published public var operationResult: OperationResult = .idle
    
    /// Active alert
    @Published public var activeAlert: AlertType?
    
    /// Show version picker sheet
    @Published public var showVersionPicker = false
    
    /// Show configuration editor sheet
    @Published public var showConfigEditor = false
    
    /// Selected version for installation
    @Published public var selectedVersion: AevonX.DatabaseVersion?
    
    /// Installation progress (0.0 - 1.0)
    @Published public var installationProgress: Double = 0.0
    
    /// Is fetching versions
    @Published public var isFetchingVersions = false
    
    /// Is performing service action
    @Published public var isPerformingServiceAction = false
    
    /// Auto-refresh timer
    @Published public var autoRefreshEnabled = true
    
    /// Last refresh timestamp
    @Published public var lastRefreshedAt: Date?
    
    /// Health status
    @Published public var healthStatus: HealthStatus = .unknown
    
    /// Active section for navigation (state-driven, not stack-driven)
    public enum Section: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case configuration = "Configuration"
        case logs = "Logs"
        case optimization = "Optimization"
        case versions = "Versions"
        case access = "Access"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .overview: return "chart.bar"
            case .configuration: return "gearshape"
            case .logs: return "doc.text"
            case .optimization: return "gauge"
            case .versions: return "arrow.clockwise"
            case .access: return "lock"
            }
        }
    }
    
    /// Current section (state-driven navigation)
    @Published public var currentSection: Section = .overview
    
    /// Active tab for legacy view (0 = Overview, 1 = Configuration, 2 = Logs, 3 = Optimization)
    @Published public var activeTab: Int = 0
    
    /// Show version switcher
    @Published public var showVersionSwitcher = false
    
    /// Show configuration editor
    @Published public var showConfigEditorLegacy = false
    
    /// Show install new version
    @Published public var showInstallVersion = false

    /// Log type selection
    public enum LogType: String, CaseIterable {
        case error = "Error Log"
        case slowQuery = "Slow Query Log"
    }

    /// Currently selected log type
    @Published public var selectedLogType: LogType = .error

    /// Whether service is enabled on boot
    @Published public var isBootEnabled: Bool = false

    /// Editable configuration content for config editor
    @Published public var configEditContent: String = ""

    /// Whether performance analysis is running
    @Published public var isAnalyzingPerformance = false

    /// Database users (from Core layer)
    @Published public var databaseUsers: [CoreDatabaseUserInfo] = []

    /// Is loading users
    @Published public var isLoadingUsers = false

    /// User loading error
    @Published public var userLoadError: String?

    /// Redis Password (for UI binding)
    @Published public var redisPassword: String = ""

    /// Server ID
    private let serverId: String?

    /// Public accessor for server ID
    public var currentServerId: String? { serverId }
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Auto-refresh timer
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init(databaseType: DatabaseType, serverId: String?) {
        self.databaseType = databaseType
        self.serverId = serverId
        
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        // Refresh every 30 seconds when enabled
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.autoRefreshEnabled else { return }
                await self.refreshStatus()
            }
        }
    }
    
    /// Refresh only status-related data (lightweight)
    public func refreshStatus() async {
        guard let serverId = serverId else { return }
        
        // Don't refresh if an operation is in progress
        guard !operationResult.isInProgress else { return }
        
        await loadEngineInfo(serverId: serverId)
        
        if engineInfo?.isInstalled == true && engineInfo?.status == .active {
            await loadMetrics(serverId: serverId)
        }
        
        lastRefreshedAt = Date()
    }
    
    // MARK: - Data Loading
    
    /// Load all engine data
    public func loadData() async {
        guard let serverId = serverId else {
            errorMessage = "Server not configured"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Load engine info
        await loadEngineInfo(serverId: serverId)
        
        // Load server info and boot status
        await loadServerInfo(serverId: serverId)
        await checkBootStatus(serverId: serverId)

        // Load metrics if engine is installed and running
        if engineInfo?.isInstalled == true && engineInfo?.status == .active {
            await loadMetrics(serverId: serverId)
            await loadPerformanceStats(serverId: serverId)
        }
        
        // Update health status
        updateHealthStatus()
        
        lastRefreshedAt = Date()
        isLoading = false
    }
    
    /// Load engine information
    private func loadEngineInfo(serverId: String) async {
        let info = await CoreDatabaseService.shared.checkDatabaseInstallation(type: databaseType, serverId: serverId)
        engineInfo = DatabaseEngineInfo(
            type: databaseType,
            displayName: databaseType.displayName,
            version: info.installedVersion,
            status: ServiceStatus(rawValue: info.serviceStatus.rawValue) ?? .unknown,
            installPath: info.installPath,
            isInstalled: info.isInstalled
        )
    }
    
    /// Load server information
    private func loadServerInfo(serverId: String) async {
        do {
            serverOSInfo = try await CoreDatabaseService.shared.getServerOSInfo(serverId: serverId)
            serverResources = try await CoreDatabaseService.shared.getServerResources(serverId: serverId)
        } catch {
            CoreLogger.shared.debug("Could not load server info: \(error.localizedDescription)", module: "DatabaseEngineDetailViewModel")
        }
    }
    
    /// Load metrics
    private func loadMetrics(serverId: String) async {
        do {
            metrics = try await CoreDatabaseService.shared.getMetrics(type: databaseType, serverId: serverId)
        } catch {
            CoreLogger.shared.debug("Could not load metrics: \(error.localizedDescription)", module: "DatabaseEngineDetailViewModel")
        }
    }
    
    /// Load performance statistics
    private func loadPerformanceStats(serverId: String) async {
        do {
            performanceStats = try await CoreDatabaseService.shared.getPerformanceStats(type: databaseType, serverId: serverId)
        } catch {
            CoreLogger.shared.debug("Could not load performance stats: \(error.localizedDescription)", module: "DatabaseEngineDetailViewModel")
        }
    }
    
    /// Load error log
    public func loadErrorLog(lines: Int = 100, offset: Int = 0) async {
        guard let serverId = serverId else { return }
        
        do {
            errorLog = try await CoreDatabaseService.shared.readErrorLog(
                type: databaseType,
                lines: lines,
                offset: offset,
                serverId: serverId
            )
        } catch {
            errorMessage = "Failed to load error log: \(error.localizedDescription)"
        }
    }
    
    /// Load slow query log
    public func loadSlowQueryLog(lines: Int = 100, offset: Int = 0) async {
        guard let serverId = serverId else { return }
        
        do {
            slowQueryLog = try await CoreDatabaseService.shared.readSlowQueryLog(
                type: databaseType,
                lines: lines,
                offset: offset,
                serverId: serverId
            )
        } catch {
            errorMessage = "Failed to load slow query log: \(error.localizedDescription)"
        }
    }
    
    /// Load configuration
    public func loadConfiguration() async {
        guard let serverId = serverId else { return }
        
        do {
            configuration = try await CoreDatabaseService.shared.getConfiguration(type: databaseType, serverId: serverId)
            
            if databaseType == .redis {
                loadRedisPassword()
            }
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
        }
    }
    
    /// Load Redis password from configuration
    public func loadRedisPassword() {
        guard databaseType == .redis, let config = configuration else { return }
        // Look for 'requirepass' in settings
        if let pass = config.settings["requirepass"] {
            redisPassword = pass
        } else {
            // Fallback: try to parse from raw content if not in settings map
            let pattern = #"^requirepass\s+(.+)$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                let nsString = (config.rawContent ?? "") as NSString
                let results = regex.matches(in: config.rawContent ?? "", options: [], range: NSRange(location: 0, length: nsString.length))
                if let match = results.first {
                    redisPassword = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    }
    
    /// Update Redis password
    public func updateRedisPassword(newPassword: String) async {
        guard let serverId = serverId, databaseType == .redis else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Updating Redis password...", progress: nil)
        
        do {
            // Reload config to ensure we have latest
            let currentConfig = try await CoreDatabaseService.shared.getConfiguration(type: databaseType, serverId: serverId)
            var newContent = currentConfig.rawContent ?? ""
            
            // Check if requirepass exists
            let pattern = #"^requirepass\s+(.+)$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                let nsString = newContent as NSString
                let results = regex.matches(in: newContent, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = results.first {
                    // Replace existing
                    let range = match.range
                    newContent = (newContent as NSString).replacingCharacters(in: range, with: "requirepass \(newPassword)")
                } else {
                    // Append if not found
                    newContent += "\nrequirepass \(newPassword)"
                }
            } else {
                 // Append if regex fails (shouldn't happen but safe fallback)
                 newContent += "\nrequirepass \(newPassword)"
            }
            
            // Create updated config object
            let updatedConfig = AevonXCore.DatabaseConfiguration(
                engineType: .redis,
                settings: currentConfig.settings, // Core will re-parse, so this is fine
                rawContent: newContent
            )
            
            // Save
            try await CoreDatabaseService.shared.updateConfiguration(updatedConfig, type: databaseType, serverId: serverId)
            
            // Update local state
            redisPassword = newPassword
            await loadConfiguration() // Reload to confirm
            
            operationResult = .success(message: "Password updated successfully!")
            activeAlert = .operationSuccess(message: "Redis password has been updated. You may need to restart the service for changes to take effect.")
            
        } catch {
            operationResult = .failure(message: "Failed to update password: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to update Redis password: \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }

    /// Save configuration from editor
    public func saveConfiguration() async {
        guard let serverId = serverId, let currentConfig = configuration else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Saving configuration...", progress: nil)
        
        do {
            let newConfig = AevonXCore.DatabaseConfiguration(
                engineType: databaseType,
                settings: currentConfig.settings,
                rawContent: configEditContent
            )
            
            try await CoreDatabaseService.shared.updateConfiguration(newConfig, type: databaseType, serverId: serverId)
            
            // Reload to confirm changes
            await loadConfiguration()
            
            operationResult = .success(message: "Configuration saved successfully!")
            activeAlert = .operationSuccess(message: "Configuration has been saved. You may need to restart the service for changes to take effect.")
            showConfigEditor = false
            
        } catch {
            operationResult = .failure(message: "Failed to save: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to save configuration: \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }

    // MARK: - Version Management
    
    /// Fetch available versions from Core
    public func fetchAvailableVersions() async {
        guard let serverId = serverId else { return }
        
        isFetchingVersions = true
        
        do {
            let coreVersions = try await CoreDatabaseService.shared.getAvailableVersions(type: databaseType, serverId: serverId)
            
            // Convert Core versions to UI versions
            availableVersions = coreVersions.map { coreVersion in
                AevonX.DatabaseVersion(
                    id: UUID(),
                    version: coreVersion.version,
                    releaseDate: coreVersion.releaseDate,
                    isLTS: coreVersion.isLTS,
                    isStable: coreVersion.isStable,
                    isRecommended: coreVersion.isRecommended,
                    changelog: coreVersion.changelog,
                    downloadSize: coreVersion.downloadSize,
                    installCommand: nil,
                    requirements: coreVersion.requirements
                )
            }
        } catch {
            errorMessage = "Failed to fetch available versions: \(error.localizedDescription)"
            availableVersions = []
        }
        
        isFetchingVersions = false
    }
    
    /// Install a specific version
    public func installVersion(_ version: AevonX.DatabaseVersion) async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Installing \(databaseType.displayName) \(version.version)...", progress: 0.0)
        installationProgress = 0.0
        
        do {
            // Start installation with progress tracking
            try await CoreDatabaseService.shared.installDatabase(
                type: databaseType,
                version: version.version,
                serverId: serverId,
                progressHandler: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.installationProgress = progress
                        self?.operationResult = .inProgress(
                            message: "Installing \(self?.databaseType.displayName ?? "database") \(version.version)...",
                            progress: progress
                        )
                    }
                }
            )
            
            operationResult = .success(message: "\(databaseType.displayName) \(version.version) installed successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) \(version.version) has been installed successfully.")
            
            // Reload data to reflect changes
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Installation failed: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to install \(databaseType.displayName) \(version.version): \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    /// Update to latest version
    public func updateToLatestVersion() async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Updating \(databaseType.displayName)...", progress: nil)
        
        do {
            try await CoreDatabaseService.shared.updateDatabase(
                type: databaseType,
                serverId: serverId,
                progressHandler: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.operationResult = .inProgress(
                            message: "Updating \(self?.databaseType.displayName ?? "database")...",
                            progress: progress
                        )
                    }
                }
            )
            
            operationResult = .success(message: "\(databaseType.displayName) updated successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) has been updated to the latest version.")
            
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Update failed: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to update \(databaseType.displayName): \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    // MARK: - Service Control
    
    /// Start the database service
    public func startService() async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Starting \(databaseType.displayName)...", progress: nil)
        
        do {
            try await CoreDatabaseService.shared.startService(type: databaseType, serverId: serverId)
            
            // Wait a moment for service to fully start
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            operationResult = .success(message: "\(databaseType.displayName) started successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) service has been started.")
            
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Failed to start: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to start \(databaseType.displayName): \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    /// Stop the database service
    public func stopService() async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Stopping \(databaseType.displayName)...", progress: nil)
        
        do {
            try await CoreDatabaseService.shared.stopService(type: databaseType, serverId: serverId)
            
            // Wait a moment for service to fully stop
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            operationResult = .success(message: "\(databaseType.displayName) stopped successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) service has been stopped.")
            
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Failed to stop: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to stop \(databaseType.displayName): \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    /// Restart the database service
    public func restartService() async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Restarting \(databaseType.displayName)...", progress: nil)
        
        do {
            try await CoreDatabaseService.shared.restartService(type: databaseType, serverId: serverId)
            
            // Wait a moment for service to fully restart
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            operationResult = .success(message: "\(databaseType.displayName) restarted successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) service has been restarted.")
            
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Failed to restart: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to restart \(databaseType.displayName): \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    /// Enable service on boot
    public func enableOnBoot() async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Enabling \(databaseType.displayName) on boot...", progress: nil)
        
        do {
            try await CoreDatabaseService.shared.enableService(type: databaseType, serverId: serverId)
            
            operationResult = .success(message: "\(databaseType.displayName) will start on boot!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) has been enabled to start on system boot.")
            
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Failed to enable: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to enable \(databaseType.displayName) on boot: \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    /// Disable service on boot
    public func disableOnBoot() async {
        guard let serverId = serverId else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Disabling \(databaseType.displayName) on boot...", progress: nil)
        
        do {
            try await CoreDatabaseService.shared.disableService(type: databaseType, serverId: serverId)
            
            operationResult = .success(message: "\(databaseType.displayName) will not start on boot!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) has been disabled from starting on system boot.")
            
            await loadData()
            
        } catch {
            operationResult = .failure(message: "Failed to disable: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to disable \(databaseType.displayName) on boot: \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    // MARK: - Confirmation Actions
    
    /// Show restart confirmation
    public func showRestartConfirmation() {
        activeAlert = .confirmRestart
    }
    
    /// Show stop confirmation
    public func showStopConfirmation() {
        activeAlert = .confirmStop
    }
    
    /// Show start confirmation
    public func showStartConfirmation() {
        activeAlert = .confirmStart
    }
    
    /// Show install confirmation
    public func showInstallConfirmation(version: AevonX.DatabaseVersion) {
        selectedVersion = version
        activeAlert = .confirmInstall(version: version)
    }
    
    /// Show update confirmation
    public func showUpdateConfirmation() {
        activeAlert = .confirmUpdate
    }
    
    /// Dismiss alert
    public func dismissAlert() {
        activeAlert = nil
        
        // Clear operation result after a delay if it was a success/failure
        if operationResult.isSuccess || operationResult.isFailure {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    self.operationResult = .idle
                }
            }
        }
    }
    
    // MARK: - Health Status
    
    public enum HealthStatus: String {
        case healthy = "Healthy"
        case warning = "Warning"
        case critical = "Critical"
        case unknown = "Unknown"
        
        public var color: Color {
            switch self {
            case .healthy: return .axSuccess
            case .warning: return .axWarning
            case .critical: return .axError
            case .unknown: return .axTextMuted
            }
        }
        
        public var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }
    
    private func updateHealthStatus() {
        guard let info = engineInfo else {
            healthStatus = .unknown
            return
        }
        
        if !info.isInstalled {
            healthStatus = .unknown
            return
        }
        
        switch info.status {
        case .active:
            // Check metrics for warnings
            if let metrics = metrics {
                let connectionRatio = Double(metrics.connections) / Double(max(metrics.maxConnections, 1))
                if connectionRatio > 0.9 {
                    healthStatus = .warning
                    return
                }
            }
            healthStatus = .healthy
        case .inactive:
            healthStatus = .warning
        case .failed:
            healthStatus = .critical
        default:
            healthStatus = .unknown
        }
    }
    
    // MARK: - Boot Status

    /// Check whether the service is enabled on boot
    private func checkBootStatus(serverId: String) async {
        do {
            let serviceName = databaseType.rawValue
            let result = try await CoreDatabaseService.shared.executeInstallationCommand(
                "systemctl is-enabled \(serviceName) 2>/dev/null || echo 'disabled'",
                serverId: serverId
            )
            isBootEnabled = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "enabled"
        } catch {
            isBootEnabled = false
        }
    }

    // MARK: - Configuration Management

    /// Save configuration content to the server
    public func saveConfiguration(content: String) async {
        guard let serverId = serverId else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Saving configuration...", progress: nil)

        do {
            let config = AevonXCore.DatabaseConfiguration(engineType: databaseType, settings: [:], rawContent: content)
            try await CoreDatabaseService.shared.updateConfiguration(config, type: databaseType, serverId: serverId)

            operationResult = .success(message: "Configuration saved successfully!")
            activeAlert = .operationSuccess(message: "Configuration has been saved. A restart may be required for changes to take effect.")
            await loadConfiguration()
        } catch {
            operationResult = .failure(message: "Save failed: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to save configuration: \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    // MARK: - Optimization

    /// Analyze performance by refreshing metrics and stats
    public func analyzePerformance() async {
        guard let serverId = serverId else { return }

        isAnalyzingPerformance = true
        operationResult = .inProgress(message: "Analyzing performance...", progress: nil)

        do {
            metrics = try await CoreDatabaseService.shared.getMetrics(type: databaseType, serverId: serverId)
            performanceStats = try await CoreDatabaseService.shared.getPerformanceStats(type: databaseType, serverId: serverId)

            updateHealthStatus()
            operationResult = .success(message: "Performance analysis complete!")
            activeAlert = .operationSuccess(message: "Performance analysis has been updated with the latest metrics.")
        } catch {
            operationResult = .failure(message: "Analysis failed: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to analyze performance: \(error.localizedDescription)")
        }

        isAnalyzingPerformance = false
    }

    /// Apply an optimization preset to the configuration
    public func applyOptimizationPreset(_ preset: String) async {
        guard let serverId = serverId else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Applying '\(preset)' preset...", progress: nil)

        do {
            let currentConfig = try await CoreDatabaseService.shared.getConfiguration(type: databaseType, serverId: serverId)
            let presetSettings = optimizationPresetSettings(for: preset)

            // Merge preset settings into current config
            var merged = currentConfig.settings
            for (key, value) in presetSettings { merged[key] = value }

            let updated = AevonXCore.DatabaseConfiguration(engineType: databaseType, settings: merged, rawContent: currentConfig.rawContent)
            try await CoreDatabaseService.shared.updateConfiguration(updated, type: databaseType, serverId: serverId)

            operationResult = .success(message: "'\(preset)' preset applied!")
            activeAlert = .operationSuccess(message: "The '\(preset)' optimization preset has been applied. Restart the service for changes to take effect.")
            await loadConfiguration()
        } catch {
            operationResult = .failure(message: "Failed to apply preset: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to apply '\(preset)' preset: \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    private func optimizationPresetSettings(for preset: String) -> [String: String] {
        switch preset {
        case "Web Application":
            return [
                "innodb_buffer_pool_size": "1G",
                "max_connections": "200",
                "query_cache_type": "1",
                "query_cache_size": "64M"
            ]
        case "Data Warehouse":
            return [
                "innodb_buffer_pool_size": "4G",
                "max_connections": "50",
                "read_buffer_size": "2M",
                "sort_buffer_size": "4M",
                "join_buffer_size": "4M"
            ]
        case "Development":
            return [
                "innodb_buffer_pool_size": "256M",
                "max_connections": "50",
                "general_log": "1"
            ]
        default:
            return [:]
        }
    }

    // MARK: - Uninstall

    /// Uninstall the database engine
    public func uninstallEngine() async {
        guard let serverId = serverId else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Uninstalling \(databaseType.displayName)...", progress: nil)

        do {
            // Service stopping is now handled by the adapter/manager if necessary,
            // but we can still be safe here if we want to show it in the UI
            try await CoreDatabaseService.shared.uninstallDatabaseEngine(type: databaseType, serverId: serverId)

            operationResult = .success(message: "\(databaseType.displayName) uninstalled successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) has been uninstalled from the server.")
            await loadData()
        } catch {
            operationResult = .failure(message: "Uninstall failed: \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "Failed to uninstall \(databaseType.displayName): \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    /// Show uninstall confirmation
    public func showUninstallConfirmation() {
        activeAlert = .confirmUninstall
    }

    // MARK: - User Management

    /// Load database users from the server
    public func loadUsers() async {
        guard let serverId = serverId else { return }

        isLoadingUsers = true
        userLoadError = nil

        do {
            databaseUsers = try await CoreDatabaseService.shared.listUsers(type: databaseType, serverId: serverId)
        } catch {
            userLoadError = "Could not load users: \(error.localizedDescription)"
            databaseUsers = []
        }

        isLoadingUsers = false
    }

    // MARK: - Computed Properties
    
    /// Whether the engine is installed
    public var isInstalled: Bool {
        engineInfo?.isInstalled ?? false
    }
    
    /// Whether the service is running
    public var isRunning: Bool {
        engineInfo?.status == .active
    }
    
    /// Formatted version string
    public var formattedVersion: String {
        engineInfo?.version ?? "Not installed"
    }
    
    /// Formatted install path
    public var formattedInstallPath: String {
        engineInfo?.installPath ?? "N/A"
    }
    
    /// Status color
    public var statusColor: Color {
        switch engineInfo?.status {
        case .active:
            return .axSuccess
        case .inactive:
            return .axWarning
        case .failed:
            return .axError
        default:
            return .axTextMuted
        }
    }
    
    /// Formatted uptime
    public var formattedUptime: String {
        guard let uptime = metrics?.uptime else { return "N/A" }
        return formatUptime(uptime)
    }
    
    /// Connection usage percentage
    public var connectionUsagePercent: Double {
        guard let metrics = metrics, metrics.maxConnections > 0 else { return 0 }
        return Double(metrics.connections) / Double(metrics.maxConnections)
    }
    
    /// Memory usage formatted
    public var formattedMemoryUsage: String {
        guard let metrics = metrics else { return "N/A" }
        if metrics.memoryUsage >= 1024 {
            return String(format: "%.2f GB", metrics.memoryUsage / 1024)
        }
        return String(format: "%.1f MB", metrics.memoryUsage)
    }
    
    /// Whether any operation is in progress
    public var isOperationInProgress: Bool {
        isLoading || isPerformingServiceAction || isFetchingVersions || operationResult.isInProgress
    }
    
    /// Configuration file path
    public var configFilePath: String {
        databaseType.defaultConfigPaths.first ?? "Unknown"
    }
    
    /// Data directory path
    public var dataDirectoryPath: String {
        databaseType.defaultDataDirectories.first ?? "Unknown"
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

// MARK: - Supporting Types (Type Aliases to Core Types)

/// Engine information for UI
public struct DatabaseEngineInfo: Identifiable {
    public let id = UUID()
    public let type: DatabaseType
    public let displayName: String
    public let version: String?
    public let status: ServiceStatus
    public let installPath: String?
    public let isInstalled: Bool
    
    public init(
        type: DatabaseType,
        displayName: String,
        version: String?,
        status: ServiceStatus,
        installPath: String?,
        isInstalled: Bool
    ) {
        self.type = type
        self.displayName = displayName
        self.version = version
        self.status = status
        self.installPath = installPath
        self.isInstalled = isInstalled
    }
}

// Use Core types directly - no duplicate definitions
// LogContent, DatabaseConfiguration, DatabaseVersion, DatabaseMetrics, PerformanceStatistics
// are all defined in AevonXCore and imported via `import AevonXCore`
