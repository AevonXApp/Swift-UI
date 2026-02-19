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

    // NOTE: We use specialized core services for all website operations
    // This ensures proper architecture separation (UI -> Core -> SSH)
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

    /// Loads all websites from the server via Core layer
    private func loadAllWebsites(serverId: String) async {
        do {
            // Call Core layer to get websites
            let coreWebsites = try await WebsiteListService.shared.listWebsites(serverId: serverId)

            // Convert Core models to UI models
            let uiWebsites = coreWebsites.map { coreWebsite in
                WebsiteInfo(
                    id: coreWebsite.id,
                    name: coreWebsite.name,
                    domain: coreWebsite.domain,
                    status: WebsiteStatus(rawValue: coreWebsite.status.rawValue) ?? .unknown,
                    sslEnabled: coreWebsite.sslEnabled,
                    sslInfo: coreWebsite.sslInfo.map { coreSSL in
                        SSLInfo(
                            provider: SSLProvider(rawValue: coreSSL.provider.rawValue) ?? .other,
                            status: SSLStatus(rawValue: coreSSL.status.rawValue) ?? .unknown,
                            issuer: coreSSL.issuer,
                            validFrom: coreSSL.validFrom,
                            validUntil: coreSSL.validUntil,
                            autoRenew: coreSSL.autoRenew,
                            domains: coreSSL.domains,
                            certificateType: CertificateType(rawValue: coreSSL.certificateType.rawValue) ?? .single
                        )
                    },
                    phpVersion: coreWebsite.phpVersion,
                    runtime: RuntimeType(rawValue: coreWebsite.runtime.rawValue) ?? .php,
                    lastDeployed: coreWebsite.lastDeployed,
                    deploymentStatus: DeploymentStatus(rawValue: coreWebsite.deploymentStatus.rawValue) ?? .none,
                    gitBranch: coreWebsite.gitBranch,
                    gitCommit: coreWebsite.gitCommit,
                    gitRepository: coreWebsite.gitRepository,
                    diskUsage: coreWebsite.diskUsage,
                    bandwidth: coreWebsite.bandwidth,
                    monthlyVisitors: coreWebsite.monthlyVisitors,
                    dailyRequests: coreWebsite.dailyRequests,
                    host: coreWebsite.host,
                    port: coreWebsite.port,
                    documentRoot: coreWebsite.documentRoot,
                    configPath: coreWebsite.configPath,
                    isReachable: coreWebsite.isReachable,
                    responseTime: coreWebsite.responseTime,
                    uptime: coreWebsite.uptime,
                    healthIssues: coreWebsite.healthIssues.map { coreIssue in
                        WebsiteHealthIssue(
                            id: coreIssue.id,
                            severity: HealthSeverity(rawValue: coreIssue.severity.rawValue) ?? .info,
                            title: coreIssue.title,
                            description: coreIssue.description,
                            recommendation: coreIssue.recommendation,
                            detectedAt: coreIssue.detectedAt,
                            resolvedAt: coreIssue.resolvedAt,
                            isResolved: coreIssue.isResolved
                        )
                    },
                    createdAt: coreWebsite.createdAt,
                    lastCheckedAt: coreWebsite.lastCheckedAt,
                    environment: EnvironmentType(rawValue: coreWebsite.environment.rawValue) ?? .production,
                    customHeaders: coreWebsite.customHeaders,
                    redirects: coreWebsite.redirects?.map { coreRedirect in
                        RedirectRule(
                            id: coreRedirect.id,
                            source: coreRedirect.source,
                            destination: coreRedirect.destination,
                            statusCode: coreRedirect.statusCode,
                            isRegex: coreRedirect.isRegex
                        )
                    }
                )
            }

            allWebsites = uiWebsites
            filterWebsites()

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

        try await WebsiteLifecycleService.shared.createWebsite(
            name: name,
            domain: domain,
            phpVersion: phpVersion,
            runtime: CoreRuntimeType(rawValue: runtime.rawValue) ?? .php,
            enableSSL: enableSSL,
            documentRoot: documentRoot,
            serverId: serverId
        )

        // Reload data
        await loadData()
    }

    /// Deletes a website via Core layer
    public func deleteWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        try await WebsiteLifecycleService.shared.deleteWebsite(
            websiteId: website.domain,
            serverId: serverId
        )

        // Reload data
        await loadData()
    }

    /// Starts a website via Core layer
    public func startWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        try await WebsiteLifecycleService.shared.startWebsite(
            websiteId: website.domain,
            serverId: serverId
        )

        await loadData()
    }

    /// Stops a website via Core layer
    public func stopWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        try await WebsiteLifecycleService.shared.stopWebsite(
            websiteId: website.domain,
            serverId: serverId
        )

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

        try await WebsiteLifecycleService.shared.restartWebsite(
            websiteId: website.domain,
            serverId: serverId
        )

        await loadData()
    }

    /// Deploys a website via Core layer
    public func deployWebsite(_ website: WebsiteInfo) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        try await WebsiteDeploymentService.shared.deployWebsite(
            websiteId: website.domain,
            serverId: serverId
        )

        await loadData()
    }

    /// Enables SSL for a website via Core layer
    public func enableSSL(_ website: WebsiteInfo, provider: SSLProvider = .letsEncrypt) async throws {
        guard let serverId = serverId else {
            throw WebsiteOperationError.serverNotConfigured
        }

        try await WebsiteSSLService.shared.enableSSL(
            websiteId: website.domain,
            provider: CoreSSLProvider(rawValue: provider.rawValue) ?? .letsEncrypt,
            serverId: serverId
        )

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
