//
//  ServerConnectionViewModel.swift
//  AevonX
//
//  Main ViewModel for server connection with SSH integration
//  UI Layer - Never holds secrets, delegates to Core
//

import SwiftUI
import AevonXCore
import Combine

// MARK: - Connection Stage

/// Stages of the connection process for UI display
enum ConnectionUIStage: String, CaseIterable {
    case idle = "Ready to Connect"
    case requestingCAT = "Requesting Authorization"
    case decryptingCAT = "Encrypting Authorization"
    case validatingCAT = "Validating Authorization"
    case authenticating = "Authenticating"
    case decrypting = "Decrypting Credentials"
    case verifyingHostKey = "Verifying Host Key"
    case establishingSSH = "Establishing SSH Connection"
    case connected = "Connected"
    case disconnecting = "Disconnecting"
    case disconnected = "Disconnected"
    case failed = "Connection Failed"
}

// MARK: - Dashboard Tab

/// Tabs available in the server dashboard
enum DashboardTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case websites = "Websites"
    case databases = "Databases"
    case applications = "Applications"
    case docker = "Docker"
    case terminal = "Terminal"
    case files = "Files"
    case plugins = "Plugins"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.line.uptrend.xyaxis"
        case .websites: return "globe"
        case .databases: return "cylinder.split.1x2"
        case .applications: return "square.stack.3d.up"
        case .docker: return "shippingbox"
        case .terminal: return "terminal"
        case .files: return "folder"
        case .plugins: return "puzzlepiece.fill"
        case .settings: return "gearshape"
        }
    }
}

/// A dynamically injected sidebar tab from the Hook & Plugin System
struct PluginSidebarTab: Identifiable, Equatable {
    let id: String        // plugin.id
    let name: String      // plugin.name
    let icon: String      // plugin.icon ?? "puzzlepiece"
    let pluginId: String  // same as id, for lookup in HookRegistry
}

/// Navigation destinations for the dashboard detail area
enum DashboardDestination: Hashable {
    case pluginConfig(Plugin)
}

// MARK: - Server Connection ViewModel

/// Main ViewModel for server connection management
/// 
/// This ViewModel follows the security architecture:
/// - Never holds SSH credentials or secrets
/// - Never executes raw commands
/// - Only uses predefined CommandTemplates
/// - Delegates all SSH operations to Core layer
@MainActor
public class ServerConnectionViewModel: ObservableObject {
    
    // MARK: - Published Properties - Connection State
    
    /// Whether currently connected to the server
    @Published private(set) var isConnected: Bool = false
    
    /// Whether a connection attempt is in progress
    @Published private(set) var isConnecting: Bool = false
    
    /// Current connection error, if any
    @Published private(set) var connectionError: String?
    
    /// Current connection stage for progress display
    @Published private(set) var connectionStage: ConnectionUIStage = .idle
    
    /// Connection progress (0.0 to 1.0)
    @Published private(set) var connectionProgress: Double = 0.0
    
    // MARK: - Published Properties - System Stats
    
    /// Current CPU usage percentage (0-100)
    @Published private(set) var cpuUsage: Double = 0.0
    
    /// CPU usage history for sparklines
    @Published private(set) var cpuUsageHistory: [Double] = []
    
    /// Current memory usage percentage (0-100)
    @Published private(set) var memoryUsage: Double = 0.0
    
    /// Memory usage history for sparklines
    @Published private(set) var memoryUsageHistory: [Double] = []
    
    /// Current disk usage percentage (0-100)
    @Published private(set) var diskUsage: Double = 0.0
    
    /// Disk usage history for sparklines
    @Published private(set) var diskUsageHistory: [Double] = []
    
    /// Server uptime string
    @Published private(set) var uptime: String = "N/A"
    
    /// Load average (1, 5, 15 minute)
    @Published private(set) var loadAverage: String = "N/A"
    
    /// CPU temperature (if available)
    @Published private(set) var cpuTemperature: Double?
    
    /// Temperature history for sparklines
    @Published private(set) var temperatureHistory: [Double] = []
    
    // MARK: - Published Properties - Database Info
    
    /// View modes for the database list
    public enum DatabaseViewMode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case table = "Table"
        public var id: String { rawValue }
    }
    
    /// Current view mode for databases
    @Published var databaseViewMode: DatabaseViewMode = .grid
    
    /// Array of databases on the server
    @Published private(set) var databases: [DatabaseInfo] = []
    
    // MARK: - Published Properties - UI State
    
    /// Currently selected dashboard tab
    @Published var selectedTab: DashboardTab = .overview

    /// Currently selected plugin-injected sidebar tab (nil = no plugin tab selected)
    @Published var selectedPluginTab: HookPluginDefinition? = nil

    /// Navigation path for the detail area (legacy, kept for compatibility)
    @Published var navigationPath = NavigationPath()

    /// Active plugin configuration being shown (replaces NavigationStack navigation)
    @Published var activeConfigPlugin: Plugin? = nil
    
    /// Whether to show connection error alert
    @Published var showConnectionError: Bool = false
    
    /// Whether databases are being loaded
    @Published private(set) var isLoadingDatabases: Bool = false
    
    /// Error from database loading, if any
    @Published private(set) var databaseError: String?
    
    /// Whether a server reboot confirmation is showing
    @Published var isRestartConfirming: Bool = false
    
    /// Whether a server shutdown confirmation is showing
    @Published var isShutdownConfirming: Bool = false
    
    // MARK: - Published Properties - Terminal Sessions
    
    /// Managed terminal sessions for this server
    @Published var terminalSessions: [TerminalViewModel] = []
    
    /// Currently active terminal index
    @Published var activeTerminalIndex: Int = 0
    
    // MARK: - Published Properties - Inventory
    
    /// Number of websites (from SSH data)
    @Published private(set) var websiteCount: Int = 0

    /// Number of applications/services (from SSH data)
    @Published private(set) var applicationCount: Int = 0

    /// Array of websites on the server
    @Published private(set) var websites: [CoreWebsiteInfo] = []

    /// Whether websites are being loaded
    @Published private(set) var isLoadingWebsites: Bool = false
    
    // MARK: - Private Properties
    
    /// The server to connect to
    private let server: Server
    
    /// Server ID from Core
    private let serverId: String
    
    /// SSH connection service from Core
    private let sshService = SSHService.shared

    // Note: ConnectionPoolManager is not available in the current AevonXCore
    // Connection pool events are handled directly by the SSHConnectionService
    
    /// Stats polling task
    private var statsPollingTask: Task<Void, Never>?
    
    /// Polling interval - uses Core configuration
    private var pollingInterval: TimeInterval {
        InternalConfiguration.statsPollingInterval
    }
    
    /// Maximum history points to keep
    private let maxHistoryPoints = 20
    
    /// Whether the app is currently in foreground
    private var isInForeground: Bool = true
    
    /// Server list ViewModel for integration
    weak var serverListViewModel: ServerListViewModel?
    
    // MARK: - Initialization
    
    init(server: Server, serverId: String, serverListViewModel: ServerListViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        self.serverListViewModel = serverListViewModel
        
        // Initialize empty history arrays
        self.cpuUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.memoryUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.diskUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.temperatureHistory = Array(repeating: 0.0, count: maxHistoryPoints)
    }
    
    deinit {
        statsPollingTask?.cancel()
    }
    
    // MARK: - Connection Management
    
    /// Establishes SSH connection to the server
    /// 
    /// Flow:
    /// 1. Request CAT from backend
    /// 2. Validate CAT and establish SSH via Core
    /// 3. Start stats polling
    func connect() async {
        guard !isConnecting && !isConnected else {
            CoreLogger.shared.warning("Connection already in progress or established", module: "ServerConnection")
            return
        }
        
        isConnecting = true
        connectionError = nil
        connectionStage = .requestingCAT
        connectionProgress = 0.1
        
        do {
            // Step 1: Request signed CAT from backend (backend is blind issuer)
            let signedCATToken = try await requestCATFromBackend()

            // Step 2: Encrypt CAT locally with device-bound key
            // Key = HKDF(device_secret + server_id + recovery_key)
            connectionStage = .decryptingCAT
            connectionProgress = 0.2
            let encryptedCAT = try await CATEncryption.shared.encrypt(
                signedToken: signedCATToken,
                serverId: serverId
            )

            // Step 3: Get encrypted server payload from Core
            connectionStage = .validatingCAT
            connectionProgress = 0.4
            guard let serverPayload = try await getServerPayload() else {
                throw ConnectionError.serverPayloadNotFound
            }

            // Step 4: Establish connection via Core SSH service
            connectionStage = .establishingSSH
            connectionProgress = 0.6
            _ = try await sshService.connect(
                to: serverPayload,
                host: server.host,
                port: server.port,
                serverId: serverId,
                encryptedCAT: encryptedCAT
            )
            
            // Connection successful
            isConnected = true
            isConnecting = false
            connectionStage = .connected
            connectionProgress = 1.0
            
            CoreLogger.shared.info("Connected to server: \(server.name)", module: "ServerConnection")
            
            // Start stats polling
            startStatsPolling()
            
            // Load initial data
            await loadDatabases()
            await loadWebsites()
            await refreshStats()
            
            // Create initial terminal session if none exist
            if terminalSessions.isEmpty {
                createTerminalSession()
            }
            
        } catch let error as SSHConnectionError {
            isConnecting = false
            isConnected = false
            connectionStage = .failed
            connectionError = error.localizedDescription
            showConnectionError = true
            CoreLogger.shared.error("SSH connection failed: \(error.localizedDescription)", module: "ServerConnection")
        } catch {
            isConnecting = false
            isConnected = false
            connectionStage = .failed
            connectionError = error.localizedDescription
            showConnectionError = true
            CoreLogger.shared.error("Connection failed: \(error.localizedDescription)", module: "ServerConnection")
        }
    }
    
    /// Disconnects from the server cleanly
    func disconnect() async {
        guard isConnected || isConnecting else { return }
        
        connectionStage = .disconnecting
        
        // Stop stats polling
        stopStatsPolling()
        
        // Disconnect via Core SSH service
        await sshService.disconnect(serverId: serverId)
        
        isConnected = false
        isConnecting = false
        connectionStage = .disconnected
        connectionProgress = 0.0
        
        // Clear stats
        resetStats()
        
        // Disconnect all terminal sessions
        for session in terminalSessions {
            session.disconnect()
        }
        terminalSessions = []
        activeTerminalIndex = 0
        
        CoreLogger.shared.info("Disconnected from server: \(server.name)", module: "ServerConnection")
    }
    
    // MARK: - Terminal Sessions Management
    
    /// Creates a new terminal session
    func createTerminalSession() {
        let newSession = TerminalViewModel(serverId: serverId)
        terminalSessions.append(newSession)
        
        // Switch to the new session
        activeTerminalIndex = terminalSessions.count - 1
        
        // Auto-connect if server is already connected
        if isConnected {
            Task {
                await newSession.connect(server: server)
            }
        }
    }
    
    /// Closes a specific terminal session
    func closeTerminalSession(at index: Int) {
        guard terminalSessions.indices.contains(index) else { return }
        
        let session = terminalSessions.remove(at: index)
        session.disconnect()
        
        // Adjust active index
        if activeTerminalIndex >= terminalSessions.count {
            activeTerminalIndex = max(0, terminalSessions.count - 1)
        }
        
        // Create a new one if all closed
        if terminalSessions.isEmpty {
            createTerminalSession()
        }
    }
    
    /// Called when app enters foreground
    func appWillEnterForeground() {
        isInForeground = true
        if isConnected {
            // Check if connection is still alive after waking from sleep
            Task {
                await checkConnectionHealthAndReconnect()
            }
        }
    }
    
    /// Check if SSH connection is still healthy, reconnect if not
    private func checkConnectionHealthAndReconnect() async {
        guard isConnected else { return }
        
        do {
            // Test connection with a simple command
            _ = try await executeCommand(.overview(.uptime))
            // Connection still alive, resume polling
            startStatsPolling()
            CoreLogger.shared.info("Connection health check passed after foreground", module: "ServerConnection")
        } catch {
            // Connection lost during sleep, attempt reconnect
            CoreLogger.shared.warning("Connection lost after sleep, attempting reconnect: \(error.localizedDescription)", module: "ServerConnection")
            
            // Reset connection state
            isConnected = false
            connectionStage = .disconnected
            connectionError = nil
            
            // Auto-reconnect
            await connect()
        }
    }
    
    /// Called when app enters background
    func appDidEnterBackground() {
        isInForeground = false
        stopStatsPolling()
    }
    
    // MARK: - Stats Management
    
    /// Refreshes system stats from server via SSH
    func refreshStats() async {
        guard isConnected else { return }
        
        do {
            // Fetch CPU usage using predefined command template
            let cpuResult = try await executeCommand(.overview(.cpuUsage))
            if let cpuValue = parsePercentage(cpuResult.stdout) {
                updateHistory(&cpuUsageHistory, with: cpuValue)
                cpuUsage = cpuValue
            }
            
            // Fetch memory usage
            let memResult = try await executeCommand(.overview(.memoryUsage))
            if let memValue = parsePercentage(memResult.stdout) {
                updateHistory(&memoryUsageHistory, with: memValue)
                memoryUsage = memValue
            }
            
            // Fetch disk usage
            let diskResult = try await executeCommand(.overview(.diskUsage))
            if let diskValue = parsePercentage(diskResult.stdout) {
                updateHistory(&diskUsageHistory, with: diskValue)
                diskUsage = diskValue
            }
            
            // Fetch uptime
            let uptimeResult = try await executeCommand(.overview(.uptime))
            uptime = parseUptime(uptimeResult.stdout)
            
            // Fetch load average
            let loadResult = try await executeCommand(.overview(.loadAverage))
            loadAverage = loadResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to fetch temperature (may not be available on all systems)
            if let tempResult = try? await executeCommand(.overview(.cpuTemperature)),
               let temp = parseTemperature(tempResult.stdout) {
                updateHistory(&temperatureHistory, with: temp)
                cpuTemperature = temp
            }
            
        } catch {
            CoreLogger.shared.warning("Failed to refresh stats: \(error.localizedDescription)", module: "ServerConnection")
        }
    }
    
    // MARK: - Quick Actions

    /// Restart server services (nginx, mysql, etc)
    func restartServices() async {
        guard isConnected else { return }

        CoreLogger.shared.info("Restarting services...", module: "ServerConnection")

        do {
            // Restart nginx
            _ = try await executeCommand(.services(.restartNginx))

            // Restart MySQL if available
            _ = try? await executeCommand(.services(.restartMySQL))

            // Restart PHP-FPM if available
            _ = try? await executeCommand(.services(.restartPHPFPM))

            CoreLogger.shared.info("Services restarted successfully", module: "ServerConnection")

            // Refresh stats after restart
            await refreshStats()
        } catch {
            CoreLogger.shared.error("Failed to restart services: \(error.localizedDescription)", module: "ServerConnection")
        }
    }
    
    /// Reboots the entire server host
    func rebootServer() async {
        guard isConnected else { return }
        
        CoreLogger.shared.warning("Initiating server reboot...", module: "ServerConnection")
        
        do {
            // Call Core SystemControlService
            try await SystemControlService.shared.reboot(serverId: serverId)
            
            // Note: Connection will be lost as server reboots
            // Handled by disconnect logic or health check
            await disconnect()
        } catch {
            CoreLogger.shared.error("Failed to reboot server: \(error.localizedDescription)", module: "ServerConnection")
            connectionError = "Reboot failed: \(error.localizedDescription)"
            showConnectionError = true
        }
    }
    
    /// Shuts down the entire server host
    func shutdownServer() async {
        guard isConnected else { return }
        
        CoreLogger.shared.warning("Initiating server shutdown...", module: "ServerConnection")
        
        do {
            // Call Core SystemControlService
            try await SystemControlService.shared.shutdown(serverId: serverId)
            
            // Note: Connection will be lost as server shuts down
            await disconnect()
        } catch {
            CoreLogger.shared.error("Failed to shutdown server: \(error.localizedDescription)", module: "ServerConnection")
            connectionError = "Shutdown failed: \(error.localizedDescription)"
            showConnectionError = true
        }
    }

    // MARK: - Website Management

    /// Loads website information from server via SSH
    func loadWebsites() async {
        guard isConnected else { return }

        isLoadingWebsites = true

        do {
            // Fetch websites using WebsiteListService
            let loadedWebsites = try await WebsiteListService.shared.listWebsites(serverId: serverId)
            websites = loadedWebsites
            websiteCount = loadedWebsites.count

            CoreLogger.shared.info("Loaded \(websiteCount) websites", module: "ServerConnection")
        } catch {
            CoreLogger.shared.error("Failed to load websites: \(error.localizedDescription)", module: "ServerConnection")
            // Don't fail silently - show 0 websites if error
            websites = []
            websiteCount = 0
        }

        isLoadingWebsites = false
    }

    // MARK: - Database Management

    /// Loads database information from server via SSH
    func loadDatabases() async {
        guard isConnected else { return }
        
        isLoadingDatabases = true
        databaseError = nil
        
        var loadedDatabases: [DatabaseInfo] = []
            
            // Try to fetch MySQL databases
            if let mysqlResult = try? await executeCommand(.databases(.listMySQL)) {
                let mysqlDBs = parseMySQLDatabases(mysqlResult.stdout)
                loadedDatabases.append(contentsOf: mysqlDBs)
            }
            
            // Try to fetch PostgreSQL databases
            if let pgResult = try? await executeCommand(.databases(.listPostgreSQL)) {
                let pgDBs = parsePostgreSQLDatabases(pgResult.stdout)
                loadedDatabases.append(contentsOf: pgDBs)
            }
            
            // Try to fetch Redis info
            if let redisResult = try? await executeCommand(.databases(.listRedis)) {
                if let redisDB = parseRedisInfo(redisResult.stdout) {
                    loadedDatabases.append(redisDB)
                }
            }
            
            databases = loadedDatabases
            
            
            // Update counts
            await updateInventoryCounts()
            
        // Removed unreachable catch block
        // catch {
        //    databaseError = error.localizedDescription
        //    CoreLogger.shared.error("Failed to load databases: \(error.localizedDescription)", module: "ServerConnection")
        // }
        
        isLoadingDatabases = false
    }
    
    // MARK: - Private Methods
    
    /// Requests CAT token from backend
    private func requestCATFromBackend() async throws -> String {
        // Get device fingerprint for CAT binding
        guard let deviceFingerprint = await DeviceIdentifier.shared.getDeviceID() else {
            CoreLogger.shared.error("Failed to get device fingerprint for CAT request", module: "ServerConnection")
            throw ConnectionError.deviceIdentificationFailed
        }
        
        CoreLogger.shared.info("Requesting CAT for server: \(serverId)", module: "ServerConnection")
        
        do {
            let catResponse = try await ServerAPIService.shared.requestCAT(
                serverId: serverId,
                deviceFingerprint: deviceFingerprint
            )
            
            CoreLogger.shared.info("CAT received, expires in \(catResponse.expiresIn)s", module: "ServerConnection")
            return catResponse.token
        } catch {
            CoreLogger.shared.error("CAT request failed: \(error.localizedDescription)", module: "ServerConnection")
            throw error
        }
    }
    
    /// Gets encrypted server payload from Core
    private func getServerPayload() async throws -> EncryptedServerPayload? {
        print("[ServerConnection] getServerPayload called for serverId: \(serverId)")
        
        // Try to get from serverListViewModel first
        if let serverListVM = serverListViewModel {
            print("[ServerConnection] Found serverListViewModel, searching for server...")
            if let accessibleServer = serverListVM.servers.first(where: { $0.id == serverId }) {
                print("[ServerConnection] Found server in list, building payload...")
                let payload = EncryptedServerPayload(
                    encryptedData: accessibleServer.server.encryptedPayload,
                    nonce: accessibleServer.server.payloadNonce,
                    authTag: accessibleServer.server.payloadAuthTag,
                    metadata: accessibleServer.server.encryptionMetadata
                )
                print("[ServerConnection] Payload built successfully")
                return payload
            } else {
                print("[ServerConnection] Server not found in serverListViewModel.servers, trying fetch from API...")
            }
        } else {
            print("[ServerConnection] serverListViewModel is nil, trying fetch from API...")
        }
        
        // Fallback: Fetch from API directly
        do {
            print("[ServerConnection] Fetching server from API...")
            let serverResponse = try await ServerAPIService.shared.fetchServer(id: serverId)
            let payload = EncryptedServerPayload(
                encryptedData: serverResponse.encryptedPayload,
                nonce: serverResponse.payloadNonce,
                authTag: serverResponse.payloadAuthTag,
                metadata: serverResponse.encryptionMetadata
            )
            print("[ServerConnection] Payload fetched from API successfully")
            return payload
        } catch {
            print("[ServerConnection] ERROR: Failed to fetch server from API: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets current user ID
    private func getCurrentUserId() async -> String {
        // In production, get from AuthService
        return "current-user-id"
    }
    
    /// Updates connection stage from Core stage
    private func updateConnectionStage(_ stage: ConnectionStage, percent: Double) {
        connectionProgress = percent

        switch stage {
        case .requestingCAT:
            connectionStage = .requestingCAT
        case .decryptingCAT:
            connectionStage = .decrypting
        case .validatingCAT:
            connectionStage = .authenticating
        case .authenticating:
            connectionStage = .authenticating
        case .decrypting:
            connectionStage = .decrypting
        case .verifyingHostKey:
            connectionStage = .verifyingHostKey
        case .establishingSSH:
            connectionStage = .establishingSSH
        case .testing:
            // Testing stage maps to establishingSSH in UI
            connectionStage = .establishingSSH
        case .complete:
            connectionStage = .connected
        case .failed:
            connectionStage = .failed
        }
    }
    
    /// Starts stats polling timer
    private func startStatsPolling() {
        stopStatsPolling()
        
        statsPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isInForeground else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                
                await self.refreshStats()
                
                try? await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
            }
        }
    }
    
    /// Stops stats polling
    private func stopStatsPolling() {
        statsPollingTask?.cancel()
        statsPollingTask = nil
    }
    
    // Note: Connection pool monitoring is not available in current AevonXCore
    // Connection state is managed directly through SSHConnectionService
    
    /// Executes a predefined command via SSH wrapper
    private func executeCommand(_ command: CommandTemplate) async throws -> SSHCommandResult {
        let commandString = command.build()
        return try await sshService.execute(commandString, serverId: serverId)
    }
    
    /// Updates history array with new value
    private func updateHistory(_ history: inout [Double], with value: Double) {
        history.append(value)
        if history.count > maxHistoryPoints {
            history.removeFirst()
        }
    }
    
    /// Resets all stats to default values
    private func resetStats() {
        cpuUsage = 0.0
        memoryUsage = 0.0
        diskUsage = 0.0
        cpuTemperature = nil
        uptime = "N/A"
        loadAverage = "N/A"
        databases = []
        websites = []
        websiteCount = 0
        applicationCount = 0
    }
    
    /// Updates inventory counts from SSH data
    private func updateInventoryCounts() async {
        // Website count is already updated by loadWebsites()
        // Just ensure it's in sync
        websiteCount = websites.count

        // Count applications/services
        if let serviceResult = try? await executeCommand(.overview(.serviceCount)) {
            applicationCount = parseCount(serviceResult.stdout) ?? 0
        }
    }
    
    // MARK: - Parsing Helpers
    
    private func parsePercentage(_ output: String) -> Double? {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%", with: "")
        return Double(cleaned)
    }
    
    private func parseUptime(_ output: String) -> String {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
        // Parse uptime format and convert to readable string
        return cleaned
    }
    
    private func parseTemperature(_ output: String) -> Double? {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "°C", with: "")
            .replacingOccurrences(of: "C", with: "")
        return Double(cleaned)
    }
    
    private func parseCount(_ output: String) -> Int? {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(cleaned)
    }
    
    private func parseMySQLDatabases(_ output: String) -> [DatabaseInfo] {
        // Parse MySQL SHOW DATABASES output
        var databases: [DatabaseInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  trimmed != "Database",
                  !trimmed.hasPrefix("+"),
                  !trimmed.hasPrefix("|") else { continue }
            
            // Skip system databases
            let systemDBs = ["information_schema", "mysql", "performance_schema", "sys"]
            guard !systemDBs.contains(trimmed) else { continue }
            
            databases.append(DatabaseInfo(
                name: trimmed,
                type: .mysql,
                status: .online
            ))
        }
        
        return databases
    }
    
    private func parsePostgreSQLDatabases(_ output: String) -> [DatabaseInfo] {
        // Parse PostgreSQL \l output
        var databases: [DatabaseInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("Name"),
                  !trimmed.hasPrefix("-"),
                  !trimmed.hasPrefix("(") else { continue }
            
            // Extract database name (first column)
            let components = trimmed.components(separatedBy: "|")
            guard let name = components.first?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty,
                  name != "postgres",
                  name != "template0",
                  name != "template1" else { continue }
            
            databases.append(DatabaseInfo(
                name: name,
                type: .postgresql,
                status: .online
            ))
        }
        
        return databases
    }
    
    private func parseRedisInfo(_ output: String) -> DatabaseInfo? {
        // Parse Redis INFO output
        guard output.contains("redis_version") else { return nil }
        
        var version: String?
        var usedMemory: Double = 0
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("redis_version:") {
                version = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
            }
            if line.hasPrefix("used_memory:") {
                if let bytesStr = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces),
                   let bytes = Double(bytesStr) {
                    usedMemory = bytes / (1024 * 1024) // Convert to MB
                }
            }
        }
        
        return DatabaseInfo(
            name: "Redis Server",
            type: .redis,
            version: version,
            status: .online,
            size: usedMemory
        )
    }
}

// MARK: - Connection Errors

enum ConnectionError: Error, LocalizedError {
    case serverPayloadNotFound
    case deviceIdentificationFailed
    
    var errorDescription: String? {
        switch self {
        case .serverPayloadNotFound:
            return "Server configuration not found"
        case .deviceIdentificationFailed:
            return "Failed to identify device"
        }
    }
}
