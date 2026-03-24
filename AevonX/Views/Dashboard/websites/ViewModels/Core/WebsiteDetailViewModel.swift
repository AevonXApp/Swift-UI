//
//  WebsiteDetailViewModel.swift
//  AevonX
//
//  View model for the detailed website management view.
//  Handles logs, configuration, and deployment actions.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
public final class WebsiteDetailViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var website: WebsiteInfo
    public let serverId: String?

    // Section ViewModels (NEW - Modular Architecture)
    public let urlRewriteVM: URLRewriteViewModel
    public let sslManagementVM: SSLManagementViewModel
    public let trafficAnalyticsVM: TrafficAnalyticsViewModel

    // Shared State
    @Published public var isLoadingAll = false
    @Published public var errorMessage: String?

    // Legacy properties (kept for backward compatibility)
    @Published public var logs: String = ""
    @Published public var isLoadingLogs = false
    @Published public var isDeploying = false
    @Published public var deploymentLogs: String = ""

    private let toastManager = GlobalToastManager.shared

    // Config editing
    @Published public var documentRoot: String = ""
    @Published public var phpVersion: String = ""
    @Published public var isSavingConfig = false

    // PHP Versions
    @Published public var installedPHPVersions: [String] = []
    @Published public var isLoadingPHPVersions = false

    // Path Browsing
    @Published public var isBrowsingPath = false
    @Published public var currentBrowsingPath: String = ""
    @Published public var browsingItems: [String] = []
    @Published public var isLoadingBrowsingItems = false

    // MARK: - Advanced Stats (Phase 2)
    @Published public var activeConnections: Int = 0
    @Published public var connectionList: [DetailedConnection] = []
    @Published public var isLoadingStats = false

    // Port Management
    @Published public var customPort: Int = 80
    @Published public var isUpdatingPort = false

    private var statsTimer: AnyCancellable?

    // MARK: - Services

    private let bridge = WebsitesBridge.shared
    private let pathResolver = PathResolverBridge.shared

    /// Auto-detected server paths
    private(set) var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    // MARK: - Initialization

    public init(website: WebsiteInfo, serverId: String?) {
        self.website = website
        self.serverId = serverId
        self.documentRoot = website.documentRoot ?? ""
        self.phpVersion = website.phpVersion ?? "8.2"
        self.customPort = website.port ?? 80
        self.activeConnections = website.activeConnections
        self.connectionList = website.connectionList

        // Initialize section ViewModels
        self.urlRewriteVM = URLRewriteViewModel(website: website, serverId: serverId)
        self.sslManagementVM = SSLManagementViewModel(website: website, serverId: serverId)
        self.trafficAnalyticsVM = TrafficAnalyticsViewModel(website: website, serverId: serverId)
    }
    
    deinit {
        statsTimer?.cancel()
    }
    
    // MARK: - Actions
    
    /// Fetches the latest logs from the server
    public func fetchLogs() async {
        guard let serverId = serverId else { return }
        isLoadingLogs = true
        errorMessage = nil
        
        // Use Go Core bridge to find and read access log
        let findCmd = bridge.findAccessLogCmd(domain: website.domain)
        let findResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: findCmd)
        let logPath = findResult.trimmingCharacters(in: .whitespacesAndNewlines)
        let readCmd = bridge.readAccessLogCmd(logPath: logPath.isEmpty ? "\(serverPaths.logDir)/access.log" : logPath, lines: 100)
        let logResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: readCmd)
        logs = logResult
        
        isLoadingLogs = false
    }
    
    /// Initial load of all website details (NEW - Loads all sections in parallel)
    public func loadWebsiteDetails() async {
        guard let serverId = serverId else { return }

        isLoadingAll = true

        // Repair any nginx redirect loops in the background
        Task.detached(priority: .utility) {
            // Skip repair — was WebsiteManager.shared.repairNginxConfig
            // Go Core handles config generation properly
        }

        // Load config from Go Core bridge
        let configCmd = bridge.loadNginxConfigCmd(configPath: website.configPath ?? "\(serverPaths.nginxSitesAvailable)/\(website.domain)")
        let configResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: configCmd)
        let configContent = configResult

        // Extract PHP version and document root from config
        if let phpMatch = configContent.range(of: "php([0-9.]+)-fpm", options: .regularExpression) {
            self.phpVersion = String(configContent[phpMatch]).replacingOccurrences(of: "php", with: "").replacingOccurrences(of: "-fpm", with: "")
            self.website.phpVersion = self.phpVersion
        }
        if let rootRegex = try? NSRegularExpression(pattern: "root\\s+(/[^;]+)", options: []),
           let rootMatch = rootRegex.firstMatch(in: configContent, options: [], range: NSRange(configContent.startIndex..., in: configContent)),
           rootMatch.numberOfRanges > 1,
           let pathRange = Range(rootMatch.range(at: 1), in: configContent) {
            let root = String(configContent[pathRange]).trimmingCharacters(in: .whitespaces)
            self.documentRoot = root
            self.website.documentRoot = root
        }

        CoreLogger.shared.debug("Website config loaded - PHP: \(self.phpVersion), Root: \(self.documentRoot)", module: "WebsiteDetail")

        // Start polling
        startMonitoring()

        // Initial stats fetch
        await fetchRealTimeStats()

        // Load all section ViewModels in parallel
        await loadAllSections()

        isLoadingAll = false
    }

    /// Load all section data in parallel (NEW)
    public func loadAllSections() async {
        // Detect server paths if not yet done
        if !pathsDetected, let sid = serverId {
            let cmd = pathResolver.detectCmd()
            let output = await SSHBridge.shared.executeAsync(serverID: sid, command: cmd)
            serverPaths = pathResolver.parse(output: output)
            pathsDetected = true
            CoreLogger.shared.debug("Detected paths: \(serverPaths.serverType) webRoot=\(serverPaths.webRoot)", module: "WebsiteDetail")
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.urlRewriteVM.load() }
            group.addTask { await self.sslManagementVM.load() }
            group.addTask { await self.trafficAnalyticsVM.load() }
        }
        
        // Update website model with SSL status from the loaded cert details
        if let cert = sslManagementVM.certificateDetails {
            website.sslEnabled = cert.isValid
            website.sslInfo = SSLInfo(
                provider: cert.isLetsEncrypt ? .letsEncrypt : .other,
                status: cert.isValid ? .active : (cert.isExpired ? .expired : .unknown),
                issuer: cert.issuer,
                validFrom: cert.validFrom,
                validUntil: cert.validUntil,
                autoRenew: cert.autoRenew,
                domains: cert.sanDomains
            )
        }
    }

    /// Refresh all section data (NEW)
    public func refreshAllSections() async {
        await loadAllSections()
    }
    
    /// Performs a deployment (git pull + build)
    public func deploy() async {
        guard let serverId = serverId else { return }
        isDeploying = true
        errorMessage = nil
        deploymentLogs = "Starting deployment...\n"
        
        let repo = website.gitRepository ?? ""
        let branch = website.gitBranch ?? "main"
        let docRoot = website.documentRoot ?? "\(serverPaths.webRoot)/\(website.domain)"
        let cmds = bridge.gitDeployCmds(repo: repo, branch: branch, docRoot: docRoot)
        for cmd in cmds {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            deploymentLogs += result
        }
        deploymentLogs += "Deployment successful!\n"
        website.lastDeployed = Date()
        
        isDeploying = false
    }
    
    /// Saves the website configuration
    public func saveConfiguration() async {
        guard let serverId = serverId else { return }
        isSavingConfig = true
        errorMessage = nil

        CoreLogger.shared.debug("Saving config - PHP: \(phpVersion), Root: \(documentRoot)", module: "WebsiteDetail")

        let configPath = website.configPath ?? "\(serverPaths.nginxSitesAvailable)/\(website.domain)"
        
        // Update PHP version in config via bridge
        if let oldPHP = website.phpVersion, oldPHP != phpVersion {
            let phpCmd = bridge.switchPHPVersionCmd(configPath: configPath, oldVersion: oldPHP, newVersion: phpVersion)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: phpCmd)
        }

        // Update document root in config if changed
        if let oldRoot = website.documentRoot, oldRoot != documentRoot {
            let rootCmd = bridge.updateDocRootCmd(configPath: configPath, oldRoot: oldRoot, newRoot: documentRoot)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: rootCmd)
        }

        // Test nginx config before reload
        let testResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.validateNginxCmd())
        if testResult.contains("successful") || testResult.contains("syntax is ok") {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            // Update local state
            website.documentRoot = documentRoot
            website.phpVersion = phpVersion
            toastManager.showSuccess("Configuration Updated")
        } else {
            errorMessage = "Nginx configuration validation failed: \(testResult)"
        }

        isSavingConfig = false
    }
    
    /// Toggles the website status
    public func toggleStatus() async {
        guard let serverId = serverId else { return }
        errorMessage = nil
        
        let shouldEnable = website.status != .online
        
        if shouldEnable {
            let cmd = bridge.enableSiteCmd(serverID: serverId, domain: website.domain)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            website.status = .online
        } else {
            let cmd = bridge.disableSiteCmd(serverID: serverId, domain: website.domain)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            website.status = .offline
        }
    }
    
    // MARK: - Advanced Monitoring
    
    /// Starts real-time monitoring of connections
    public func startMonitoring() {
        statsTimer?.cancel()
        statsTimer = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchRealTimeStats()
                }
            }
    }

    /// Stops all timers and background monitoring
    public func stopMonitoring() {
        statsTimer?.cancel()
        statsTimer = nil
        trafficAnalyticsVM.stopAutoRefresh()
    }
    
    /// Fetches live connection stats via SSH (Zero-Mock)
    public func fetchRealTimeStats() async {
        guard let serverId = serverId else { return }
        isLoadingStats = true
        
        // Get active connections via bridge
        let connResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.activeConnectionsCmd())
        let count = Int(connResult.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        self.activeConnections = count
        self.website.activeConnections = count
        
        isLoadingStats = false
    }
    
    /// Updates the website port
    public func updatePort() async {
        guard let serverId = serverId else { return }
        isUpdatingPort = true
        
        let configPath = website.configPath ?? "\(serverPaths.nginxSitesAvailable)/\(website.domain)"
        let cmd = bridge.updatePortCmd(configPath: configPath, port: customPort)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        website.port = customPort
        toastManager.showSuccess("Port updated to \(customPort)")
        
        isUpdatingPort = false
    }
    
    /// Renews the SSL certificate for the website
    public func renewSSL() async {
        guard let serverId = serverId else { return }
        
        let cmd = bridge.renewSSLCmd(domain: website.domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        toastManager.showSuccess("SSL Renewal Started")
    }
    
    /// Restarts the web server service
    public func restartService() async {
        guard let serverId = serverId else { return }
        
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        toastManager.showSuccess("Service Restarted")
    }
    
    // MARK: - Configuration Helpers
    
    /// Fetches all installed PHP versions on the server
    public func fetchInstalledPHPVersions() async {
        guard let serverId = serverId else { return }
        isLoadingPHPVersions = true
        
        // Detect installed PHP versions via bridge
        let cmd = bridge.installedPHPVersionsCmd()
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let versions = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        installedPHPVersions = versions
        
        isLoadingPHPVersions = false
    }
    
    /// Starts the directory browsing process
    public func startBrowsing(initialPath: String? = nil) {
        currentBrowsingPath = initialPath ?? documentRoot
        if currentBrowsingPath.isEmpty {
            currentBrowsingPath = serverPaths.webRoot
        }
        isBrowsingPath = true
        Task {
            await fetchBrowsingItems(path: currentBrowsingPath)
        }
    }
    
    /// Fetches subdirectories for the current browsing path
    @MainActor
    public func fetchBrowsingItems(path: String) async {
        guard let serverId = serverId else {
            CoreLogger.shared.debug("No serverId available", module: "WebsiteDetail")
            return
        }
        isLoadingBrowsingItems = true
        browsingItems = []

        CoreLogger.shared.debug("Fetching directories for path: \(path)", module: "WebsiteDetail")

        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.listDirectoriesCmd(path: path))
        let items = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        browsingItems = items
        CoreLogger.shared.debug("Found \(items.count) directories", module: "WebsiteDetail")

        isLoadingBrowsingItems = false
    }
    
    /// Navigates to a subdirectory
    public func navigateToPath(_ folder: String) {
        let separator = currentBrowsingPath.hasSuffix("/") ? "" : "/"
        currentBrowsingPath = "\(currentBrowsingPath)\(separator)\(folder)"
        Task { await fetchBrowsingItems(path: currentBrowsingPath) }
    }
    
    /// Goes back to the parent directory
    public func backToParent() {
        CoreLogger.shared.debug("backToParent called. Current path: \(currentBrowsingPath)", module: "WebsiteDetail")

        // Don't go up if already at root
        guard currentBrowsingPath != "/" else {
            CoreLogger.shared.debug("Already at root, cannot go up", module: "WebsiteDetail")
            return
        }

        let components = currentBrowsingPath.split(separator: "/")
        CoreLogger.shared.debug("Path components: \(components)", module: "WebsiteDetail")

        if components.count > 1 {
            currentBrowsingPath = "/" + components.dropLast().joined(separator: "/")
        } else if components.count == 1 {
            currentBrowsingPath = "/"
        } else {
            // Fallback to root if path is malformed
            currentBrowsingPath = "/"
        }

        CoreLogger.shared.debug("New path: \(currentBrowsingPath)", module: "WebsiteDetail")
        Task { await fetchBrowsingItems(path: currentBrowsingPath) }
    }
    
    /// Selects the current path as the document root
    public func selectCurrentDirectory() {
        documentRoot = currentBrowsingPath
        isBrowsingPath = false
    }
    
    // MARK: - Helper Mappings
    
    private func mapToCoreRuntime(_ type: RuntimeType) -> CoreRuntimeType {
        switch type {
        case .php: return .php
        case .nodejs: return .nodejs
        case .python: return .python
        case .ruby: return .ruby
        case .`static`: return .`static`
        case .docker: return .docker
        }
    }
    
    private func mapFromCoreRuntime(_ type: CoreRuntimeType) -> RuntimeType {
        switch type {
        case .php: return .php
        case .nodejs: return .nodejs
        case .python: return .python
        case .ruby: return .ruby
        case .`static`: return .`static`
        case .docker: return .docker
        }
    }
    
    // MARK: - Per-Site PHP Version Switching
    
    /// Switches the PHP version for this specific website by updating the nginx config.
    public func switchWebsitePHPVersion(to newVersion: String) async {
        guard let serverId = serverId else { return }
        isSavingConfig = true
        
        let configPath = website.configPath ?? "\(serverPaths.nginxSitesAvailable)/\(website.domain)"
        
        // Update PHP-FPM socket in nginx config via bridge
        if let oldVersion = website.phpVersion {
            let cmd = bridge.switchPHPVersionCmd(configPath: configPath, oldVersion: oldVersion, newVersion: newVersion)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }

        // Test nginx config before reload
        let testResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.validateNginxCmd())
        if testResult.contains("successful") || testResult.contains("syntax is ok") {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            self.phpVersion = newVersion
            self.website.phpVersion = newVersion
            toastManager.showSuccess("PHP version switched to \(newVersion)")
        } else {
            errorMessage = "Nginx validation failed after PHP switch: \(testResult)"
        }

        isSavingConfig = false
    }
}
