//
//  WebsiteDetailViewModel.swift
//  AevonX
//
//  View model for the detailed website management view.
//  Handles logs, configuration, and deployment actions.
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
public final class WebsiteDetailViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var website: WebsiteInfo
    public let serverId: String?

    // Section ViewModels (NEW - Modular Architecture)
    public let urlRewriteVM: URLRewriteViewModel
    public let sslManagementVM: SSLManagementViewModel
    public let trafficAnalyticsVM: TrafficAnalyticsViewModel
    public let logManagementVM: LogManagementViewModel

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

    private let websiteManager = WebsiteConfigService.shared
    private let lifecycleService = WebsiteLifecycleService.shared
    private let logService = WebsiteLogService.shared
    private let deploymentService = WebsiteDeploymentService.shared
    private let sslService = WebsiteSSLService.shared

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
        self.logManagementVM = LogManagementViewModel(website: website, serverId: serverId)
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
        
        do {
            logs = try await logService.getWebsiteLogs(websiteId: website.domain, serverId: serverId)
        } catch {
            errorMessage = "Failed to fetch logs: \(error.localizedDescription)"
            toastManager.showError(errorMessage!)
        }
        
        isLoadingLogs = false
    }
    
    /// Initial load of all website details (NEW - Loads all sections in parallel)
    public func loadWebsiteDetails() async {
        guard let serverId = serverId else { return }

        isLoadingAll = true

        do {
            let updatedCore = try await websiteManager.getWebsiteConfiguration(websiteId: website.domain, serverId: serverId)

            print("📥 Loading website details...")
            print("   Received PHP Version: \(updatedCore.phpVersion ?? "nil")")
            print("   Received Document Root: \(updatedCore.documentRoot ?? "nil")")

            // Sync UI model
            self.website.aliases = updatedCore.aliases
            self.website.port = updatedCore.port
            self.website.activeConnections = updatedCore.activeConnections
            self.website.phpVersion = updatedCore.phpVersion
            self.website.documentRoot = updatedCore.documentRoot
            self.customPort = updatedCore.port ?? 80
            self.phpVersion = updatedCore.phpVersion ?? "8.2"
            self.documentRoot = updatedCore.documentRoot ?? ""

            print("✅ Website details loaded")
            print("   Local phpVersion: \(self.phpVersion)")
            print("   Local documentRoot: \(self.documentRoot)")

            // Start polling
            startMonitoring()

            // Initial stats fetch
            await fetchRealTimeStats()

            // Load all section ViewModels in parallel
            await loadAllSections()
        } catch {
            print("Failed to load website details: \(error)")
        }

        isLoadingAll = false
    }

    /// Load all section data in parallel (NEW)
    public func loadAllSections() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.urlRewriteVM.load() }
            group.addTask { await self.sslManagementVM.load() }
            group.addTask { await self.trafficAnalyticsVM.load() }
            group.addTask { await self.logManagementVM.load() }
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
        
        do {
            try await deploymentService.deployWebsite(websiteId: website.domain, serverId: serverId)
            deploymentLogs += "Deployment successful!\n"
            // Update last deployed time locally for feedback
            website.lastDeployed = Date()
        } catch {
            errorMessage = "Deployment failed: \(error.localizedDescription)"
            deploymentLogs += "ERROR: \(error.localizedDescription)\n"
            toastManager.showError(errorMessage!)
        }
        
        isDeploying = false
    }
    
    /// Saves the website configuration
    public func saveConfiguration() async {
        guard let serverId = serverId else { return }
        isSavingConfig = true
        errorMessage = nil

        print("💾 Saving configuration...")
        print("   PHP Version: \(phpVersion)")
        print("   Document Root: \(documentRoot)")

        do {
            // Update the core model
            let updatedCoreInfo = CoreWebsiteInfo(
                id: website.id,
                name: website.name,
                domain: website.domain,
                status: website.status == .online ? .online : .offline,
                sslEnabled: website.sslEnabled,
                phpVersion: phpVersion,
                runtime: mapToCoreRuntime(website.runtime),
                documentRoot: documentRoot,
                configPath: website.configPath
            )

            try await websiteManager.updateWebsiteConfiguration(
                websiteId: website.domain,
                configuration: updatedCoreInfo,
                serverId: serverId
            )

            // Update local state
            website.documentRoot = documentRoot
            website.phpVersion = phpVersion

            print("✅ Configuration saved successfully")
            print("   Local website.phpVersion: \(website.phpVersion ?? "nil")")

            toastManager.showSuccess("Configuration Updated")
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
            print("❌ Failed to save: \(error.localizedDescription)")
            toastManager.showError(errorMessage!)
        }

        isSavingConfig = false
    }
    
    /// Toggles the website status
    public func toggleStatus() async {
        guard let serverId = serverId else { return }
        errorMessage = nil
        
        let shouldEnable = website.status != .online
        
        do {
            if shouldEnable {
                try await lifecycleService.startWebsite(websiteId: website.domain, serverId: serverId)
                website.status = .online
            } else {
                try await lifecycleService.stopWebsite(websiteId: website.domain, serverId: serverId)
                website.status = .offline
            }
        } catch {
            let msg = "Failed to toggle status: \(error.localizedDescription)"
            errorMessage = msg
            toastManager.showError(msg)
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
    
    /// Fetches live connection stats via SSH (Zero-Mock)
    public func fetchRealTimeStats() async {
        guard let serverId = serverId else { return }
        isLoadingStats = true
        
        do {
            let count = try await websiteManager.getConnectionCount(websiteId: website.domain, serverId: serverId)
            let details = try await websiteManager.getDetailedConnections(websiteId: website.domain, serverId: serverId)
            
            self.activeConnections = count
            self.connectionList = details.map { 
                DetailedConnection(ip: $0.ip, count: $0.count, location: $0.location)
            }
            
            // Update local website object for consistency
            self.website.activeConnections = count
            self.website.connectionList = self.connectionList
            
        } catch {
            print("Failed to fetch real-time stats: \(error)")
        }
        
        isLoadingStats = false
    }
    
    /// Updates the website port
    public func updatePort() async {
        guard let serverId = serverId else { return }
        isUpdatingPort = true
        
        do {
            try await websiteManager.updatePort(websiteId: website.domain, newPort: customPort, serverId: serverId)
            website.port = customPort
            toastManager.showSuccess("Port updated to \(customPort)")
        } catch {
            toastManager.showError("Failed to update port: \(error.localizedDescription)")
        }
        
        isUpdatingPort = false
    }
    
    /// Renews the SSL certificate for the website
    public func renewSSL() async {
        guard let serverId = serverId else { return }
        
        do {
            try await sslService.renewSSL(websiteId: website.domain, serverId: serverId)
            toastManager.showSuccess("SSL Renewal Started")
        } catch {
            toastManager.showError("SSL Renewal Failed: \(error.localizedDescription)")
        }
    }
    
    /// Restarts the web server service
    public func restartService() async {
        guard let serverId = serverId else { return }
        
        do {
            try await lifecycleService.restartWebsite(websiteId: website.domain, serverId: serverId)
            toastManager.showSuccess("Service Restarted")
        } catch {
            toastManager.showError("Restart Failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Configuration Helpers
    
    /// Fetches all installed PHP versions on the server
    public func fetchInstalledPHPVersions() async {
        guard let serverId = serverId else { return }
        isLoadingPHPVersions = true
        
        do {
            installedPHPVersions = try await websiteManager.getInstalledPHPVersions(serverId: serverId)
        } catch {
            print("Failed to fetch PHP versions: \(error)")
        }
        
        isLoadingPHPVersions = false
    }
    
    /// Starts the directory browsing process
    public func startBrowsing(initialPath: String? = nil) {
        currentBrowsingPath = initialPath ?? documentRoot
        if currentBrowsingPath.isEmpty {
            currentBrowsingPath = "/var/www"
        }
        isBrowsingPath = true
        Task { await fetchBrowsingItems(path: currentBrowsingPath) }
    }
    
    /// Fetches subdirectories for the current browsing path
    public func fetchBrowsingItems(path: String) async {
        guard let serverId = serverId else {
            print("⚠️ No serverId available")
            return
        }
        isLoadingBrowsingItems = true

        print("📁 Fetching directories for path: \(path)")

        do {
            browsingItems = try await websiteManager.listDirectories(path: path, serverId: serverId)
            print("✅ Found \(browsingItems.count) directories")
        } catch {
            errorMessage = "Failed to browse: \(error.localizedDescription)"
            print("❌ Error fetching directories: \(error.localizedDescription)")
        }

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
        print("⬆️ backToParent called. Current path: \(currentBrowsingPath)")

        // Don't go up if already at root
        guard currentBrowsingPath != "/" else {
            print("⚠️ Already at root, cannot go up")
            return
        }

        let components = currentBrowsingPath.split(separator: "/")
        print("📊 Path components: \(components)")

        if components.count > 1 {
            currentBrowsingPath = "/" + components.dropLast().joined(separator: "/")
        } else if components.count == 1 {
            currentBrowsingPath = "/"
        } else {
            // Fallback to root if path is malformed
            currentBrowsingPath = "/"
        }

        print("✅ New path: \(currentBrowsingPath)")
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
}
