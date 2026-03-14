//
//  ServerConnectionViewModel.swift
//  AevonX
//
//  Main ViewModel for server connection with SSH integration
//  UI Layer - Never holds secrets, delegates to Core
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge
import Combine

// MARK: - Reconnection Tier

/// Visual tier for reconnection UI
enum ReconnectionTier {
    /// Reconnecting silently, no UI shown (0-2s)
    case silent
    /// Floating banner at top (2-8s)
    case banner
    /// Full semi-transparent overlay (8s+)
    case overlay
}

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
    case security = "Security"
    case cron = "Cron"
    case ftp = "FTP"
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
        case .security: return "shield.lefthalf.filled"
        case .cron: return "clock.badge.checkmark"
        case .ftp: return "externaldrive.connected.to.line.below"
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
    
    // MARK: - Published Properties - Reconnection State
    
    /// Whether a reconnection is in progress
    @Published private(set) var isReconnecting: Bool = false
    
    /// Current reconnection attempt number
    @Published private(set) var reconnectionAttempt: Int = 0
    
    /// Maximum reconnection attempts
    @Published private(set) var reconnectionMaxAttempts: Int = InternalConfiguration.reconnectionMaxAttempts
    
    /// Human-readable reason for disconnection
    @Published private(set) var reconnectionReason: String?
    
    /// Seconds until next retry
    @Published private(set) var reconnectionNextRetryIn: TimeInterval = 0
    
    /// Current UI tier (silent/banner/overlay)
    @Published private(set) var reconnectionTier: ReconnectionTier = .silent
    
    /// Whether reconnection has permanently failed
    @Published private(set) var reconnectionFailed: Bool = false
    
    /// Final error message when reconnection fails
    @Published private(set) var reconnectionFinalError: String?
    
    // MARK: - Child ViewModels (Single Responsibility)
    
    /// Stats management (CPU, memory, disk, uptime, polling)
    @Published private(set) var stats: ServerStatsViewModel
    
    /// Database discovery and listing
    @Published private(set) var databasesVM: ServerDatabasesViewModel
    
    /// Website listing
    @Published private(set) var websitesVM: ServerWebsitesViewModel
    
    /// Server actions (restart, reboot, shutdown)
    @Published private(set) var actions: ServerActionsViewModel
    
    // MARK: - Backward-Compatible Computed Accessors
    // These allow existing views to continue using viewModel.cpuUsage etc.
    
    var cpuUsage: Double { stats.cpuUsage }
    var cpuUsageHistory: [Double] { stats.cpuUsageHistory }
    var memoryUsage: Double { stats.memoryUsage }
    var memoryUsageHistory: [Double] { stats.memoryUsageHistory }
    var diskUsage: Double { stats.diskUsage }
    var diskUsageHistory: [Double] { stats.diskUsageHistory }
    var uptime: String { stats.uptime }
    var loadAverage: String { stats.loadAverage }
    var cpuTemperature: Double? { stats.cpuTemperature }
    var temperatureHistory: [Double] { stats.temperatureHistory }
    
    var databases: [DatabaseInfo] { databasesVM.databases }
    var isLoadingDatabases: Bool { databasesVM.isLoading }
    var databaseError: String? { databasesVM.error }
    var databaseViewMode: ServerDatabasesViewModel.DatabaseViewMode {
        get { databasesVM.viewMode }
        set { databasesVM.viewMode = newValue }
    }
    
    var websites: [CoreWebsiteInfo] { websitesVM.websites }
    var websiteCount: Int { websitesVM.count > 0 ? websitesVM.count : websiteInventoryCount }
    var databaseCount: Int { databasesVM.databases.count > 0 ? databasesVM.databases.count : databaseInventoryCount }
    var isLoadingWebsites: Bool { websitesVM.isLoading }
    
    var isRestartConfirming: Bool {
        get { actions.isRestartConfirming }
        set { actions.isRestartConfirming = newValue }
    }
    var isShutdownConfirming: Bool {
        get { actions.isShutdownConfirming }
        set { actions.isShutdownConfirming = newValue }
    }
    
    // MARK: - Published Properties - UI State
    
    /// Currently selected dashboard tab
    @Published var selectedTab: DashboardTab = .overview

    /// Currently selected plugin-injected sidebar tab (nil = no plugin tab selected)
    @Published var selectedPluginTab: AevonXCoreBridge.HookPluginDefinition? = nil

    /// Navigation path for the detail area (legacy, kept for compatibility)
    @Published var navigationPath = NavigationPath()

    /// Active plugin configuration being shown (replaces NavigationStack navigation)
    @Published var activeConfigPlugin: Plugin? = nil

    /// Quick Install ViewModel — persists across tab navigation so bubble stays visible
    @Published var quickInstallVM: QuickInstallViewModel? = nil

    /// Whether the server appears fresh (no services detected yet)
    var isFreshServer: Bool {
        quickInstallVM?.serverScan?.isEmpty ?? true
    }
    
    /// Whether to show connection error alert
    @Published var showConnectionError: Bool = false
    
    /// Lightweight inventory counts (from quick SSH queries, used before full data loads)
    @Published private(set) var applicationCount: Int = 0
    @Published private(set) var websiteInventoryCount: Int = 0
    @Published private(set) var databaseInventoryCount: Int = 0
    
    // MARK: - Published Properties - Terminal Sessions
    
    /// Managed terminal sessions for this server
    @Published var terminalSessions: [TerminalViewModel] = []
    
    /// Currently active terminal index
    @Published var activeTerminalIndex: Int = 0
    
    // MARK: - File Manager (persisted across tab switches)
    
    /// Lazy-initialized file manager ViewModel — persists when user switches tabs
    private var _fileManagerViewModel: FileManagerViewModel?
    var fileManagerViewModel: FileManagerViewModel {
        if let existing = _fileManagerViewModel {
            return existing
        }
        let vm = FileManagerViewModel(serverId: serverId)
        _fileManagerViewModel = vm
        return vm
    }
    
    // MARK: - Private Properties
    
    /// The server to connect to
    private let server: Server
    
    /// Server ID from Core
    private let serverId: String
    
    /// SSH service backed by Go Core — used by strategies and detectors
    private let sshService: any SSHServiceProtocol = SSHBridge.shared
    
    /// Server profile (detected capabilities: OS, init system, package manager)
    @Published private(set) var serverProfile: AevonXCoreBridge.ServerProfile?
    
    /// Service management strategy (based on detected init system)
    private(set) var serviceStrategy: (any ServiceManagementStrategy)?
    
    /// Package management strategy (based on detected package manager)
    private(set) var packageStrategy: (any PackageManagementStrategy)?

    // Note: ConnectionPoolManager is not available in the current AevonXCore
    // Connection pool events are handled directly by the SSHConnectionService
    
    /// Combine subscriptions for child VM changes
    private var childCancellables = Set<AnyCancellable>()
    
    /// Whether the app is currently in foreground
    private var isInForeground: Bool = true
    
    /// Task for listening to health monitor events
    private var healthMonitorTask: Task<Void, Never>?
    
    /// Task for tracking reconnection tier escalation
    private var tierEscalationTask: Task<Void, Never>?
    
    /// Timestamp when reconnection started (for tier calculation)
    private var reconnectionStartTime: Date?
    
    /// Server list ViewModel for integration
    weak var serverListViewModel: ServerListViewModel?
    
    // MARK: - Initialization
    
    init(server: Server, serverId: String) {
        self.server = server
        self.serverId = serverId
        
        // Initialize child ViewModels
        self.stats = ServerStatsViewModel(serverId: serverId)
        self.databasesVM = ServerDatabasesViewModel(serverId: serverId)
        self.websitesVM = ServerWebsitesViewModel(serverId: serverId)
        self.actions = ServerActionsViewModel(serverId: serverId)
        
        // Wire callbacks for actions VM
        self.actions.onDisconnectNeeded = { [weak self] in
            await self?.disconnect()
        }
        self.actions.onError = { [weak self] msg in
            self?.connectionError = msg
            self?.showConnectionError = true
        }
        self.actions.onRefreshStats = { [weak self] in
            await self?.stats.refreshStats()
        }
        
        // Forward child VM objectWillChange to parent
        stats.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)
        databasesVM.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)
        websitesVM.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)
        actions.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)
        
        // Observe app lifecycle for polling control
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: NSApplication.willBecomeActiveNotification,
            object: nil
        )
        
        // Subscribe to connection health events
        setupHealthMonitoring()
    }
    
    deinit {
        // Child VMs handle their own cleanup in their own deinit
        healthMonitorTask?.cancel()
        tierEscalationTask?.cancel()
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
            AevonXCoreBridge.CoreLogger.shared.warning("Connection already in progress or established", module: "ServerConnection")
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
            let _ = try await CATEncryption.shared.encrypt(
                signedToken: signedCATToken,
                serverId: serverId
            )

            // Step 3: Get encrypted server payload from Core
            connectionStage = .validatingCAT
            connectionProgress = 0.4
            guard let serverPayload = try await getServerPayload() else {
                throw ConnectionError.serverPayloadNotFound
            }

            // Step 4: Decrypt credentials using local encryption
            connectionStage = .decrypting
            connectionProgress = 0.5
            let serverData = try await ServerEncryptionService.shared.decryptServer(
                EncryptedServerData.self,
                from: serverPayload
            )
            
            // Step 5: Establish SSH connection via Go Core
            connectionStage = .establishingSSH
            connectionProgress = 0.7
            let connectResult = await SSHBridge.shared.connectAsync(
                serverID: serverId,
                host: server.host,
                port: Int32(server.port),
                username: serverData.connectionDetails.username,
                password: serverData.authentication.password ?? "",
                privateKey: serverData.authentication.privateKey ?? "",
                passphrase: serverData.authentication.keyPassphrase ?? ""
            )
            
            // Check connection result
            guard let resultData = connectResult.data(using: .utf8),
                  let resultJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any],
                  resultJSON["success"] as? Bool == true else {
                let errorMsg = parseGoError(connectResult)
                throw ConnectionError.sshConnectionFailed(errorMsg)
            }
            
            // Connection successful
            isConnected = true
            isConnecting = false
            connectionStage = .connected
            connectionProgress = 1.0
            
            AevonXCoreBridge.CoreLogger.shared.info("Connected to server: \(server.name)", module: "ServerConnection")
            
            // Start health monitoring for this server
            await ConnectionHealthMonitor.shared.startMonitoring(serverId: serverId)
            
            // Detect server capabilities (OS, init system, package manager)
            Task {
                do {
                    let detector = CapabilityDetector(sshService: sshService)
                    let coreProfile = try await detector.detect(serverId: serverId)
                    let profile = try JSONDecoder().decode(AevonXCoreBridge.ServerProfile.self, from: JSONEncoder().encode(coreProfile))
                    await MainActor.run {
                        self.serverProfile = profile
                        self.serviceStrategy = ServiceStrategyFactory.strategy(for: coreProfile, sshService: sshService)
                        self.packageStrategy = PackageStrategyFactory.strategy(for: coreProfile, sshService: sshService)
                    }
                    AevonXCoreBridge.CoreLogger.shared.info(
                        "Server profile: \(profile.distro.rawValue), init=\(profile.initSystem.rawValue), pkg=\(profile.packageManager.rawValue)",
                        module: "ServerConnection"
                    )

                    // ── Auto Quick Install Check ─────────────────────────
                    // Scan FIRST, then assign to self only if fresh (prevents flash-and-disappear)
                    await MainActor.run {
                        guard self.quickInstallVM == nil else { return }
                        let qi = QuickInstallViewModel(serverId: self.serverId, profile: profile)
                        // Do NOT assign to self yet — wait for scan result
                        Task { @MainActor in
                            await qi.scanServer()
                            AevonXCoreBridge.CoreLogger.shared.info(
                                "QuickInstall scan — installed: \(qi.serverScan?.keys.sorted().joined(separator: ", ") ?? "nil"), isFresh: \(qi.serverScan?.isEmpty ?? true)",
                                module: "QuickInstall"
                            )
                            if qi.serverScan?.isEmpty == true {
                                // Assign and show only after scan confirms fresh
                                self.quickInstallVM = qi
                                qi.isVisible = true
                                qi.isMinimized = false
                            }
                            // Non-fresh: qi is discarded without ever being shown
                        }
                    }
                } catch {
                    AevonXCoreBridge.CoreLogger.shared.warning("Failed to detect server capabilities: \(error.localizedDescription)", module: "ServerConnection")
                }
            }
            
            // Start stats polling
            startStatsPolling()
            
            // Load overview stats + inventory counts on connect — full data loads on demand per tab
            await refreshStats()
            await updateInventoryCounts()
            
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
            AevonXCoreBridge.CoreLogger.shared.error("SSH connection failed: \(error.localizedDescription)", module: "ServerConnection")
        } catch {
            isConnecting = false
            isConnected = false
            connectionStage = .failed
            connectionError = error.localizedDescription
            showConnectionError = true
            AevonXCoreBridge.CoreLogger.shared.error("Connection failed: \(error.localizedDescription)", module: "ServerConnection")
        }
    }
    
    /// Disconnects from the server cleanly
    func disconnect() async {
        guard isConnected || isConnecting else { return }
        
        connectionStage = .disconnecting
        
        // Stop stats polling
        stopStatsPolling()
        
        // Stop health monitoring
        await ConnectionHealthMonitor.shared.stopMonitoring(serverId: serverId)
        
        // Disconnect via Go Core SSH
        SSHBridge.shared.disconnect(serverID: serverId)
        
        isConnected = false
        isConnecting = false
        isReconnecting = false
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
        
        AevonXCoreBridge.CoreLogger.shared.info("Disconnected from server: \(server.name)", module: "ServerConnection")
    }
    
    // MARK: - Terminal Sessions Management
    
    /// Creates a new terminal session
    func createTerminalSession() {
        let newSession = TerminalViewModel(serverId: serverId)

        terminalSessions.append(newSession)

        // Switch to the new session
        activeTerminalIndex = terminalSessions.count - 1

        // Auto-connect if server is already connected
        // TerminalViewModel now connects directly via PTYBridge (real PTY session)
        if isConnected {
            Task {
                await newSession.connect(serverName: server.name, serverHost: server.host)
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
    @objc func appWillEnterForeground() {
        isInForeground = true
        
        // M11: Cleanup expired cache entries to free memory
        Task { await CacheManager.shared.cleanup() }
        
        if isConnected {
            // Resume polling immediately
            startStatsPolling()
            
            // Verify the SSH session is still alive with a quick test command.
            // If it survived sleep, no reconnection is needed.
            // Verify SSH via Go Core — quick echo test
            Task {
                let testJSON = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: "echo 1")
                if let td = testJSON.data(using: .utf8),
                   let tr = try? JSONSerialization.jsonObject(with: td) as? [String: Any],
                   tr["success"] as? Bool == true {
                    AevonXCoreBridge.CoreLogger.shared.info("SSH session survived sleep — no reconnection needed", module: "ServerConnection")
                    return
                }
                
                AevonXCoreBridge.CoreLogger.shared.warning("SSH session died during sleep", module: "ServerConnection")
                
                // Connection is dead — trigger reconnection
                await ConnectionHealthMonitor.shared.deviceDidWake()
            }
        }
    }
    
    /// Called when app enters background
    func appDidEnterBackground() {
        isInForeground = false
        stats.appDidEnterBackground()
        stats.stopPolling()
        
        // M11: Persist long-lived cache entries to disk for efficiency on resume
        Task {
            await CacheManager.shared.persistToDisk()
        }
    }
    
    // MARK: - Delegated Methods (to Child ViewModels)
    
    /// Refreshes system stats — delegates to ServerStatsViewModel
    func refreshStats() async {
        await stats.refreshStats()
    }
    
    /// Restart server services — delegates to ServerActionsViewModel
    func restartServices() async {
        actions.isConnected = isConnected
        await actions.restartServices()
    }
    
    /// Reboots the server — delegates to ServerActionsViewModel
    func rebootServer() async {
        actions.isConnected = isConnected
        await actions.rebootServer()
    }
    
    /// Shuts down the server — delegates to ServerActionsViewModel
    func shutdownServer() async {
        actions.isConnected = isConnected
        await actions.shutdownServer()
    }

    /// Loads websites — delegates to ServerWebsitesViewModel
    func loadWebsites() async {
        await websitesVM.loadWebsites()
    }

    /// Loads databases — delegates to ServerDatabasesViewModel
    func loadDatabases() async {
        await databasesVM.loadDatabases()
        await updateInventoryCounts()
    }
    
    // MARK: - Private Methods
    
    /// Requests CAT token from backend via Go HTTP
    private func requestCATFromBackend() async throws -> String {
        guard let deviceFingerprint = await DeviceIdentifier.shared.getDeviceID() else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to get device fingerprint for CAT request", module: "ServerConnection")
            throw ConnectionError.deviceIdentificationFailed
        }
        
        guard let token = await AuthService.shared.getToken() else {
            throw ConnectionError.authenticationRequired
        }
        
        let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
        AevonXCoreBridge.CoreLogger.shared.info("Requesting CAT for server: \(serverId) via Go", module: "ServerConnection")
        
        let resultJSON = await APIBridge.shared.requestCATAsync(
            baseURL: baseURL, token: token,
            serverID: serverId, fingerprint: deviceFingerprint
        )
        
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let responseData = result["data"] as? [String: Any],
              let catToken = responseData["token"] as? String else {
            // Extract error message
            if let data = resultJSON.data(using: .utf8),
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = result["error"] as? [String: Any],
               let message = error["message"] as? String {
                AevonXCoreBridge.CoreLogger.shared.error("CAT request failed: \(message)", module: "ServerConnection")
                throw NSError(domain: "ServerConnection", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "ServerConnection", code: -1, userInfo: [NSLocalizedDescriptionKey: "CAT request failed"])
        }
        
        AevonXCoreBridge.CoreLogger.shared.info("CAT received via Go", module: "ServerConnection")
        return catToken
    }
    
    /// Gets encrypted server payload from Core or Go HTTP fallback
    private func getServerPayload() async throws -> EncryptedServerPayload? {
        print("[ServerConnection] getServerPayload called for serverId: \(serverId)")
        
        // Try to get from serverListViewModel first (already in memory)
        if let serverListVM = serverListViewModel {
            if let accessibleServer = serverListVM.servers.first(where: { $0.id == serverId }) {
                let payload = EncryptedServerPayload(
                    encryptedData: accessibleServer.server.encryptedPayload,
                    nonce: accessibleServer.server.payloadNonce,
                    authTag: accessibleServer.server.payloadAuthTag,
                    metadata: accessibleServer.server.encryptionMetadata
                )
                return payload
            }
        }
        
        // Fallback: Fetch from API via Go HTTP
        guard let token = await AuthService.shared.getToken() else { return nil }
        let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let resultJSON = await APIBridge.shared.fetchServerAsync(baseURL: baseURL, token: token, serverID: serverId)
        
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let responseData = result["data"] as? [String: Any],
              let encryptedPayload = responseData["encrypted_payload"] as? String,
              let nonce = responseData["payload_nonce"] as? String,
              let authTag = responseData["payload_auth_tag"] as? String,
              let metadataDict = responseData["encryption_metadata"] as? [String: Any],
              let metadataJSON = try? JSONSerialization.data(withJSONObject: metadataDict),
              let metadata = try? JSONDecoder().decode(EncryptionMetadata.self, from: metadataJSON) else {
            print("[ServerConnection] ERROR: Failed to fetch server from Go API")
            return nil
        }
        
        return EncryptedServerPayload(
            encryptedData: encryptedPayload,
            nonce: nonce,
            authTag: authTag,
            metadata: metadata
        )
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
    
    /// Starts stats polling via child VM
    private func startStatsPolling() {
        stats.startPolling()
    }
    
    /// Stops stats polling via child VM
    private func stopStatsPolling() {
        stats.stopPolling()
    }
    
    /// Executes a predefined command via Go SSH Bridge
    private func executeCommand(_ command: CommandTemplate) async throws -> AevonXCore.SSHCommandResult {
        let commandString = command.build()
        let resultJSON = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: commandString)
        
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let cmdData = result["data"] as? [String: Any] else {
            throw SSHServiceError.commandFailed("Go SSH command failed")
        }
        
        return AevonXCore.SSHCommandResult(
            stdout: cmdData["stdout"] as? String ?? "",
            stderr: cmdData["stderr"] as? String ?? "",
            exitCode: Int32(cmdData["exit_code"] as? Int ?? -1)
        )
    }
    
    // MARK: - Health Monitoring
    
    /// Sets up the ConnectionHealthMonitor event subscription and reconnection handler
    private func setupHealthMonitoring() {
        // Provide the reconnection handler to Core.
        // This closure performs the full CAT → encrypt → SSH connect flow.
        // Core never holds credentials — it only calls this handler when reconnection is needed.
        Task {
            await ConnectionHealthMonitor.shared.setReconnectionHandler { [weak self] serverId in
                guard let self = self else { return false }
                
                do {
                    // Reset error state on MainActor
                    await MainActor.run {
                        self.connectionError = nil
                    }
                    
                    // Step 1: Request CAT
                    let signedCATToken = try await self.requestCATFromBackend()
                    
                    // Step 2: Encrypt CAT
                    let _ = try await CATEncryption.shared.encrypt(
                        signedToken: signedCATToken,
                        serverId: serverId
                    )
                    
                    // Step 3: Get server payload
                    guard let serverPayload = try await self.getServerPayload() else {
                        return false
                    }
                    
                    // Step 4: Decrypt and connect via Go SSH
                    let serverData = try await ServerEncryptionService.shared.decryptServer(
                        EncryptedServerData.self,
                        from: serverPayload
                    )
                    let connectResult = await SSHBridge.shared.connectAsync(
                        serverID: serverId,
                        host: self.server.host,
                        port: Int32(self.server.port),
                        username: serverData.connectionDetails.username,
                        password: serverData.authentication.password ?? "",
                        privateKey: serverData.authentication.privateKey ?? "",
                        passphrase: serverData.authentication.keyPassphrase ?? ""
                    )
                    guard let rd = connectResult.data(using: .utf8),
                          let rj = try? JSONSerialization.jsonObject(with: rd) as? [String: Any],
                          rj["success"] as? Bool == true else {
                        return false
                    }
                    
                    // Success — update UI state
                    await MainActor.run {
                        self.isConnected = true
                        self.isConnecting = false
                        self.isReconnecting = false
                        self.connectionStage = .connected
                        self.connectionProgress = 1.0
                        self.reconnectionTier = .silent
                        self.reconnectionFailed = false
                        self.reconnectionFinalError = nil
                        self.reconnectionStartTime = nil
                        self.startStatsPolling()
                    }
                    
                    AevonXCoreBridge.CoreLogger.shared.info("Reconnection succeeded for server: \(serverId)", module: "ServerConnection")
                    return true
                    
                } catch {
                    AevonXCoreBridge.CoreLogger.shared.warning("Reconnection attempt failed: \(error.localizedDescription)", module: "ServerConnection")
                    return false
                }
            }
        }
        
        // Subscribe to health events
        healthMonitorTask = Task { [weak self] in
            for await event in await ConnectionHealthMonitor.shared.eventStream() {
                guard let self = self else { break }
                await MainActor.run {
                    self.handleHealthEvent(event)
                }
            }
        }
    }
    
    /// Processes a health event from ConnectionHealthMonitor
    private func handleHealthEvent(_ event: ConnectionHealthEvent) {
        switch event {
        case .connectionLost(let sid, let reason):
            guard sid == serverId else { return }
            
            isConnected = false
            isReconnecting = true
            reconnectionReason = reason.rawValue
            reconnectionAttempt = 0
            reconnectionFailed = false
            reconnectionFinalError = nil
            reconnectionTier = .silent
            reconnectionStartTime = Date()
            
            // Stop polling while disconnected
            stopStatsPolling()
            
            // Start tier escalation timer
            startTierEscalation()
            
        case .reconnecting(let sid, let attempt, let max, let nextRetry):
            guard sid == serverId else { return }
            
            reconnectionAttempt = attempt
            reconnectionMaxAttempts = max
            reconnectionNextRetryIn = nextRetry
            
        case .reconnected(let sid):
            guard sid == serverId else { return }
            
            isReconnecting = false
            reconnectionAttempt = 0
            reconnectionReason = nil
            reconnectionTier = .silent
            reconnectionFailed = false
            reconnectionFinalError = nil
            reconnectionStartTime = nil
            tierEscalationTask?.cancel()
            
            // Resume polling
            startStatsPolling()
            
            // Refresh stats after reconnection
            Task {
                await refreshStats()
                await updateInventoryCounts()
            }
            
        case .reconnectionFailed(let sid, let error):
            guard sid == serverId else { return }
            
            isReconnecting = false
            reconnectionFailed = true
            reconnectionFinalError = error
            reconnectionTier = .overlay // Always show overlay on final failure
            tierEscalationTask?.cancel()
            
        case .networkStatusChanged:
            // Informational — no special handling needed
            break
        }
    }
    
    /// Starts a timer that escalates the reconnection UI tier based on elapsed time
    private func startTierEscalation() {
        tierEscalationTask?.cancel()
        
        tierEscalationTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Wait for silent threshold, then show banner
            try? await Task.sleep(nanoseconds: UInt64(InternalConfiguration.reconnectionSilentThreshold * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                if self.isReconnecting {
                    self.reconnectionTier = .banner
                }
            }
            
            // Wait for overlay threshold, then show full overlay
            let overlayDelay = InternalConfiguration.reconnectionOverlayThreshold - InternalConfiguration.reconnectionSilentThreshold
            try? await Task.sleep(nanoseconds: UInt64(overlayDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                if self.isReconnecting {
                    self.reconnectionTier = .overlay
                }
            }
        }
    }
    
    /// Cancels reconnection and returns to disconnected state
    func cancelReconnection() {
        Task {
            await ConnectionHealthMonitor.shared.cancelReconnection(serverId: serverId)
        }
        
        isReconnecting = false
        reconnectionAttempt = 0
        reconnectionReason = nil
        reconnectionTier = .silent
        reconnectionFailed = false
        reconnectionFinalError = nil
        reconnectionStartTime = nil
        tierEscalationTask?.cancel()
        connectionStage = .disconnected
    }
    
    /// Manually retries reconnection after failure
    func retryReconnection() {
        reconnectionFailed = false
        reconnectionFinalError = nil
        
        Task {
            await ConnectionHealthMonitor.shared.attemptReconnection(
                serverId: serverId,
                reason: .unknown
            )
        }
    }
    
    /// Resets all stats to default values
    private func resetStats() {
        stats.reset()
        databasesVM.reset()
        websitesVM.reset()
        applicationCount = 0
    }
    
    /// Updates inventory counts from Go SSH data
    private func updateInventoryCounts() async {
        // Count applications/services (1 SSH command)
        if let serviceResult = try? await executeCommand(.overview(.serviceCount)) {
            applicationCount = parseCount(serviceResult.stdout) ?? 0
        }
        
        // Count websites — lightweight ls | wc -l via Go SSH
        let websiteStdout = await SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "ls -1 /etc/nginx/sites-enabled/ 2>/dev/null | grep -v default | wc -l"
        )
        websiteInventoryCount = parseCount(websiteStdout) ?? 0
        
        // Count databases — quick queries via Go SSH
        var dbCount = 0
        // MySQL databases
        let mysqlStdout = await SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "mysql -N -e 'SHOW DATABASES;' 2>/dev/null | grep -vcE '^(information_schema|performance_schema|mysql|sys)$' || echo '0'"
        )
        dbCount += parseCount(mysqlStdout) ?? 0
        // PostgreSQL databases
        let pgStdout = await SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "sudo -u postgres psql -t -c 'SELECT count(*) FROM pg_database WHERE NOT datistemplate;' 2>/dev/null || echo '0'"
        )
        dbCount += parseCount(pgStdout) ?? 0
        databaseInventoryCount = dbCount
    }
    
    private func parseCount(_ output: String) -> Int? {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(cleaned)
    }
}

// MARK: - Connection Errors

enum ConnectionError: Error, LocalizedError {
    case serverPayloadNotFound
    case deviceIdentificationFailed
    case authenticationRequired
    case sshConnectionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .serverPayloadNotFound:
            return "Server configuration not found"
        case .deviceIdentificationFailed:
            return "Failed to identify device"
        case .authenticationRequired:
            return "Authentication required. Please log in."
        case .sshConnectionFailed(let detail):
            return "SSH connection failed: \(detail)"
        }
    }
}

// MARK: - Go Response Parsing Helper

extension ServerConnectionViewModel {
    /// Extracts error message from a Go Core JSON error response.
    func parseGoError(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = result["error"] as? String else {
            return "Unknown error"
        }
        return error
    }
}
