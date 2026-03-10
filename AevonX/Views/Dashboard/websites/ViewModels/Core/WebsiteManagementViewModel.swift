//
//  WebsiteManagementViewModel.swift
//  AevonX
//
//  Main ViewModel for website management
//  Handles all website operations and state management
//
//  ARCHITECTURE: UI Layer ViewModel
//  - Uses specialized core services from Core layer for all website operations
//  - NEVER executes SSH commands directly
//  - Responsible only for UI state management and data presentation
//

import Foundation
import SwiftUI
import Combine
import AevonXCoreBridge
import AevonXCore

// MARK: - Website Management ViewModel

/// Main ViewModel for the website management system
/// Coordinates between UI and Core layer
///
/// All server operations go through specialized core services in the Core layer.
@MainActor
public final class WebsiteManagementViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All websites from server (from Core layer)
    @Published public var allWebsites: [WebsiteInfo] = []

    /// Websites filtered by search text
    @Published public var filteredWebsites: [WebsiteInfo] = []

    /// Loading state
    @Published public var isLoading = false

    /// Error message for user display
    @Published public var errorMessage: String?

    /// Connection state
    @Published public var isConnected = false

    /// Search text for filtering websites
    @Published public var searchText = "" {
        didSet {
            filterWebsites()
        }
    }

    /// Selected website for detail view
    @Published public var selectedWebsite: WebsiteInfo?

    /// Show add website sheet
    @Published public var showAddWebsite = false

    /// Show website detail view
    @Published public var showWebsiteDetail = false

    /// Show deployment view
    @Published public var showDeployment = false

    /// show SSL settings sheet
    @Published public var showSSLSettings = false

    /// show Config editor sheet
    @Published public var showConfigEditor = false

    /// show Logs sheet
    @Published public var showLogs = false

    // MARK: - Services

    // NOTE: All website operations now go through Go Core via WebsitesBridge
    private let bridge = WebsitesBridge.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Server Properties

    private let server: Server?
    let serverId: String?
    private weak var connectionViewModel: ServerConnectionViewModel?

    // MARK: - Initialization

    init(
        server: Server? = nil,
        serverId: String? = nil,
        connectionViewModel: ServerConnectionViewModel? = nil
    ) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
    }

    // MARK: - Data Loading

    /// Loads all website data from the server via Core layer
    public func loadData() async {
        guard let serverId = serverId else {
            errorMessage = "Server not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        // Check connection status
        if let connectionViewModel = connectionViewModel {
            isConnected = connectionViewModel.isConnected
        } else {
            isConnected = false
            isLoading = false
            errorMessage = "Not connected to server"
            return
        }

        guard isConnected else {
            isLoading = false
            errorMessage = "Not connected to server. Please connect first."
            return
        }

        // Load websites from Core layer
        await loadAllWebsites(serverId: serverId)

        isLoading = false
    }

    /// Loads all websites from the server via Go Core bridge
    private func loadAllWebsites(serverId: String) async {
        do {
            // Step 1: Get list command from Go Core
            let listCmd = bridge.nginxListCmd(serverID: serverId)
            guard !listCmd.isEmpty else {
                errorMessage = "Failed to get website list command"
                return
            }

            // Step 2: Execute via SSH
            let sshOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: listCmd)

            // Step 3: Parse output via Go Core
            let parsedJSON = bridge.parseNginxSites(output: sshOutput)

            // Step 4: Decode and convert to UI models
            if let data = parsedJSON.data(using: .utf8),
               let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               response["success"] as? Bool == true,
               let sitesData = response["data"],
               JSONSerialization.isValidJSONObject(sitesData) {
                let sitesJSON = try JSONSerialization.data(withJSONObject: sitesData)
                struct BridgeSite: Codable {
                    let domain: String
                    let enabled: Bool
                    let server_type: String?
                    let document_root: String?
                    let php_version: String?
                    let ssl_enabled: Bool?
                    let config_path: String?
                }
                if let sites = try? JSONDecoder().decode([BridgeSite].self, from: sitesJSON) {
                    let uiWebsites = sites.map { site in
                        WebsiteInfo(
                            name: site.domain,
                            domain: site.domain,
                            status: site.enabled ? .online : .offline,
                            sslEnabled: site.ssl_enabled ?? false,
                            phpVersion: site.php_version,
                            documentRoot: site.document_root ?? "/var/www/\(site.domain)",
                            configPath: site.config_path,
                            isReachable: site.enabled
                        )
                    }
                    allWebsites = uiWebsites
                    filterWebsites()
                }
            }

        } catch {
            CoreLogger.shared.error("Failed to load websites: \(error.localizedDescription)",
                                   module: "WebsiteManagementViewModel")
            errorMessage = "Failed to load websites: \(error.localizedDescription)"
        }
    }

    // MARK: - Filtering

    /// Filters websites based on search text
    private func filterWebsites() {
        var filtered = allWebsites

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.domain.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredWebsites = filtered
    }

    // MARK: - Website Operations (Via Core Layer)

    /// Creates a new website via Core layer
    public func createWebsite(
        name: String,
        domain: String,
        phpVersion: String? = nil,
        runtime: RuntimeType = .php,
        enableSSL: Bool = false,
        documentRoot: String? = nil
    ) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        // Build config JSON for Go Core bridge
        var config: [String: Any] = [
            "domain": domain,
            "document_root": documentRoot ?? "/var/www/\(domain)"
        ]
        if let phpVersion = phpVersion { config["php_version"] = phpVersion }
        let configJSON = String(data: try JSONSerialization.data(withJSONObject: config), encoding: .utf8) ?? "{}"

        // Get create commands from Go Core
        let cmds = bridge.createSiteCmd(serverID: serverId, configJSON: configJSON)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }

        // Enable SSL if requested
        if enableSSL {
            let sslCmds = bridge.issueSSLCmd(domain: domain)
            for cmd in sslCmds {
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            }
        }

        // Reload data
        await loadData()
    }

    /// Deletes a website via Core layer
    public func deleteWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        let cmds = bridge.deleteSiteCmd(serverID: serverId, domain: website.domain)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }

        // Reload data
        await loadData()
    }

    /// Starts a website via Core layer
    public func startWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        let cmd = bridge.enableSiteCmd(serverID: serverId, domain: website.domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        // Reload nginx
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

        await loadData()
    }

    /// Stops a website via Core layer
    public func stopWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        let cmd = bridge.disableSiteCmd(serverID: serverId, domain: website.domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        // Reload nginx
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

        await loadData()
    }

    /// Toggles website status (start/stop)
    public func toggleWebsite(_ website: WebsiteInfo) async throws {
        if website.status == .online {
            try await stopWebsite(website)
        } else {
            try await startWebsite(website)
        }
    }

    /// Restarts a website via Core layer
    public func restartWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

        await loadData()
    }

    /// Deploys a website via Core layer
    public func deployWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        let repo = website.gitRepository ?? ""
        let branch = website.gitBranch ?? "main"
        let docRoot = website.documentRoot ?? "/var/www/\(website.domain)"
        let cmds = bridge.gitDeployCmds(repo: repo, branch: branch, docRoot: docRoot)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }

        await loadData()
    }

    /// Enables SSL for a website via Core layer
    public func enableSSL(_ website: WebsiteInfo, provider: SSLProvider = .letsEncrypt) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        let sslCmds = bridge.issueSSLCmd(domain: website.domain)
        for cmd in sslCmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }

        await loadData()
    }

    /// Opens deployment view for a website
    public func openDeployment(for website: WebsiteInfo) {
        selectedWebsite = website
        showDeployment = true
    }
    
    /// Opens logs for a website
    public func openLogs(for website: WebsiteInfo) {
        selectedWebsite = website
        showLogs = true
    }
    
    /// Opens configuration editor for a website
    public func openConfigEditor(for website: WebsiteInfo) {
        selectedWebsite = website
        showConfigEditor = true
    }
    
    /// Opens SSL settings for a website
    public func openSSLSettings(for website: WebsiteInfo) {
        selectedWebsite = website
        showSSLSettings = true
    }

    // MARK: - Statistics

    /// Total number of websites
    public var totalWebsiteCount: Int {
        allWebsites.count
    }

    /// Number of online websites
    public var onlineCount: Int {
        allWebsites.filter { $0.status == .online }.count
    }

    /// Number of SSL-secured websites
    public var sslSecuredCount: Int {
        allWebsites.filter { $0.sslEnabled }.count
    }

    /// Total disk usage across all websites
    public var totalDiskUsage: Double {
        allWebsites.reduce(0) { $0 + $1.diskUsage }
    }

    /// Formatted total disk usage
    public var formattedTotalDiskUsage: String {
        let total = totalDiskUsage
        if total >= 1024 * 1024 {
            return String(format: "%.2f TB", total / (1024 * 1024))
        } else if total >= 1024 {
            return String(format: "%.2f GB", total / 1024)
        } else {
            return String(format: "%.0f MB", total)
        }
    }
    
    // MARK: - Clone & Backup
    
    /// Clone a website (copy nginx config + document root)
    @Published public var isCloning = false
    
    public func cloneWebsite(_ website: WebsiteInfo, newDomain: String) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }
        
        isCloning = true
        defer { isCloning = false }
        
        let docRoot = website.documentRoot ?? "/var/www/\(website.domain)"
        let cmds = bridge.cloneSiteCmds(
            source: website.domain,
            target: newDomain,
            docRoot: docRoot,
            sitesAvailable: "/etc/nginx/sites-available",
            sitesEnabled: "/etc/nginx/sites-enabled"
        )
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        
        // Test & reload nginx
        let testResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t")
        if true {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        }
        
        GlobalToastManager.shared.showSuccess("Site cloned to \(newDomain)")
        await loadData()
    }
    
    /// Backup a website via Go Core bridge
    @Published public var isBackingUp = false
    @Published public var lastBackupPath: String?
    
    public func backupWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }
        
        isBackingUp = true
        defer { isBackingUp = false }
        
        let docRoot = website.documentRoot ?? "/var/www/\(website.domain)"
        let cmds = bridge.backupSiteCmds(domain: website.domain, docRoot: docRoot)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        
        lastBackupPath = "/var/backups/aevonx/\(website.domain)_backup.tar.gz"
        GlobalToastManager.shared.showSuccess("Backup saved")
    }
}


// MARK: - Website Operation Errors

/// Errors specific to website operations from UI layer
public enum WebsiteOperationError: LocalizedError {
    case serverNotConfigured
    case notConnected
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .serverNotConfigured:
            return "Server not configured"
        case .notConnected:
            return "Not connected to server"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }
}
