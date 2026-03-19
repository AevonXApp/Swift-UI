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
import AevonXCoreBridge

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
    case confirmInstall(version: DatabaseVersion)
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
    @Published public var metrics: DatabaseMetrics?
    
    /// Performance statistics (from Core layer)
    @Published public var performanceStats: PerformanceStatistics?
    
    /// Error log content (from Core layer)
    @Published public var errorLog: LogContent?
    
    /// Slow query log content (from Core layer)
    @Published public var slowQueryLog: LogContent?
    
    /// Configuration content (from Core layer)
    @Published public var configuration: DatabaseConfiguration?
    
    /// Available versions for this engine (using UI layer type)
    @Published public var availableVersions: [DatabaseVersion] = []
    
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
    @Published public var selectedVersion: DatabaseVersion?
    
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
    public enum HealthStatus: String {
        case unknown, healthy, warning, critical
    }

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
        // Invalidate any existing timer first to prevent stacking (P2-6)
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        guard autoRefreshEnabled else { return }
        
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
        let info = await DatabaseEngineService.shared.checkDatabaseInstallation(type: databaseType, serverId: serverId)
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
            serverOSInfo = try await DatabaseResourceService.shared.getServerOSInfo(serverId: serverId)
            serverResources = try await DatabaseResourceService.shared.getServerResources(serverId: serverId)
        } catch {
            print("[DatabaseEngineDetailViewModel] Could not load server info: \(error.localizedDescription)")
        }
    }
    
    /// Check boot status
    func checkBootStatus(serverId: String) async {
        guard let serviceName = databaseType.serviceNames.first else { return }
        let result = await SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "systemctl is-enabled \(serviceName) 2>/dev/null || echo disabled"
        )
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        isBootEnabled = (trimmed == "enabled")
    }

    /// Load metrics
    func loadMetrics(serverId: String) async {
        do {
            metrics = try await DatabaseMetricsService.shared.getMetrics(type: databaseType, serverId: serverId)
        } catch {
            print("[DatabaseEngineDetailViewModel] Could not load metrics: \(error.localizedDescription)")
        }
    }
    
    /// Load performance statistics
    func loadPerformanceStats(serverId: String) async {
        do {
            performanceStats = try await DatabaseMetricsService.shared.getPerformanceStats(type: databaseType, serverId: serverId)
        } catch {
            print("[DatabaseEngineDetailViewModel] Could not load performance stats: \(error.localizedDescription)")
        }
    }
    
    /// Load error log
    public func loadErrorLog(lines: Int = 100, offset: Int = 0) async {
        guard let serverId = serverId else { return }
        
        do {
            errorLog = try await DatabaseLogService.shared.readErrorLog(
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
            slowQueryLog = try await DatabaseLogService.shared.readSlowQueryLog(
                type: databaseType,
                lines: lines,
                offset: offset,
                serverId: serverId
            )
        } catch {
            errorMessage = "Failed to load slow query log: \(error.localizedDescription)"
        }
    }
    
    // Configuration methods moved to DatabaseEngineDetailViewModel+Config.swift

    // Version methods (fetchAvailableVersions, installVersion, updateToLatestVersion) moved to +Config extension


    func resolveLatestVersion(serverId: String) async throws -> String {
        if availableVersions.isEmpty {
            await fetchAvailableVersions()
        }
        if let selected = availableVersions.first(where: { !$0.version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return selected.version
        }

        let fetched = try await DatabaseEngineService.shared.getAvailableVersions(type: databaseType, serverId: serverId)
        if let selected = fetched.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return selected
        }

        return "latest"
    }
    
    // MARK: - Operation Helper
    
    /// Shared operation runner that handles isPerformingServiceAction, operationResult, and activeAlert.
    /// Preserves all features: progress, success/failure alerts, and loadData after success.
    func performOperation(
        progressMessage: String,
        successMessage: String,
        successAlert: String,
        failurePrefix: String,
        reloadAfterSuccess: Bool = true,
        action: () async throws -> Void
    ) async {
        guard serverId != nil else { return }
        
        isPerformingServiceAction = true
        operationResult = .inProgress(message: progressMessage, progress: nil)
        
        do {
            try await action()
            operationResult = .success(message: successMessage)
            activeAlert = .operationSuccess(message: successAlert)
            if reloadAfterSuccess { await loadData() }
        } catch {
            operationResult = .failure(message: "\(failurePrefix): \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "\(failurePrefix) \(databaseType.displayName): \(error.localizedDescription)")
        }
        
        isPerformingServiceAction = false
    }
    
    // Service control, confirmations, health, optimization, uninstall,
    // and user management moved to:
    //   DatabaseEngineDetailViewModel+Service.swift
    //   DatabaseEngineDetailViewModel+Config.swift


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
    
    /// Connection usage percentage
    public var connectionUsagePercent: Double {
        guard let metrics = metrics, metrics.maxConnections > 0 else { return 0 }
        return Double(metrics.connections) / Double(metrics.maxConnections)
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
    
    /// Whether this database engine supports user management features
    public var supportsUserManagement: Bool {
        switch databaseType {
        case .mysql, .mariadb, .postgresql, .mongodb, .cassandra, .cockroachdb:
            return true
        default:
            return false
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
