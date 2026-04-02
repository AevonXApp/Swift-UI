//
//  AddWebsiteViewModel.swift
//  AevonX
//
//  ViewModel for adding new websites
//  Handles validation, runtime detection, and creation via Core layer
//

import Foundation
import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Add Website ViewModel

@MainActor
public final class AddWebsiteViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public var domain = ""
    @Published public var runtime: RuntimeType = .php
    @Published public var selectedVersion = ""
    @Published public var enableSSL = true
    @Published public var documentRoot = ""
    @Published public var userEditedDocumentRoot = false
    @Published public var selectedEngine = "nginx"

    // Server capabilities
    @Published public var isLoadingCapabilities = true
    @Published public var availableRuntimes: [RuntimeType] = [.static]
    @Published public var phpVersions: [String] = []
    @Published public var nodeVersions: [String] = []
    @Published public var pythonVersions: [String] = []
    @Published public var detectedWebRoot = ServerPaths.defaults.webRoot
    @Published public var detectedWebServerType = "nginx"
    @Published public var installedEngines: Set<String> = ["nginx"]

    // Directory browser
    @Published public var isShowingDirectoryBrowser = false
    @Published public var browserCurrentPath = "/"
    @Published public var browserDirectories: [String] = []
    @Published public var isLoadingDirectories = false
    @Published public var newFolderName = ""

    // State
    @Published public var isCreating = false
    @Published public var errorMessage: String?
    @Published public var validationErrors: [String: String] = [:]

    // MARK: - Properties

    private let serverId: String?
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults

    // MARK: - Initialization

    public init(serverId: String?) {
        self.serverId = serverId
    }

    // MARK: - Server Capabilities

    /// Fetches installed runtimes and versions from the server.
    /// Runs runtime detection and path resolution in parallel, then shows form immediately.
    /// Version loading happens after form is visible (deferred).
    public func loadServerCapabilities() async {
        guard let serverId = serverId else {
            isLoadingCapabilities = false
            return
        }

        isLoadingCapabilities = true

        // Run runtime detection and path resolution in parallel
        async let runtimeResult = SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.detectRuntimesCmd())
        async let pathResult: String = {
            let cmd = PathResolverBridge.shared.detectCmd()
            return await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }()

        let (runtimeOutput, pathOutput) = await (runtimeResult, pathResult)

        // Parse runtimes
        var runtimes: [RuntimeType] = [.static]
        for line in runtimeOutput.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t == "php:YES" { runtimes.append(.php) }
            else if t == "node:YES" { runtimes.append(.nodejs) }
            else if t == "python:YES" { runtimes.append(.python) }
        }
        availableRuntimes = runtimes

        // Set default runtime
        if availableRuntimes.contains(.php) {
            runtime = .php
        } else if let first = availableRuntimes.first {
            runtime = first
        }

        // Parse paths
        let detectedPaths = PathResolverBridge.shared.parse(output: pathOutput)
        serverPaths = detectedPaths
        detectedWebRoot = detectedPaths.webRoot
        detectedWebServerType = detectedPaths.webServerType
        installedEngines = detectedPaths.installedEngines
        if installedEngines.count == 1, let only = installedEngines.first {
            selectedEngine = only
        }

        // Show form immediately — version loading happens in background
        isLoadingCapabilities = false

        // Load versions (deferred, doesn't block form display)
        await loadVersionsForRuntime(runtime)
    }

    /// Loads version list for the given runtime type.
    private func loadVersionsForRuntime(_ runtime: RuntimeType) async {
        guard let serverId = serverId else { return }

        switch runtime {
        case .php:
            // Use core-go ApplicationBridge for reliable PHP version detection
            let json = await ApplicationBridge.shared.getVersions(serverID: serverId, appID: "php-fpm")
            if let data = json.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let versions = parsed["data"] as? [[String: Any]] {
                phpVersions = versions.compactMap { $0["version"] as? String }
            } else {
                phpVersions = []
            }
            selectedVersion = phpVersions.first ?? ""
        case .nodejs:
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.getNodeVersionCmd())
            let ver = result.trimmingCharacters(in: .whitespacesAndNewlines)
            nodeVersions = ver.isEmpty ? [] : [ver]
            selectedVersion = nodeVersions.first ?? ""
        case .python:
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.getPythonVersionCmd())
            let ver = result.trimmingCharacters(in: .whitespacesAndNewlines)
            pythonVersions = ver.isEmpty ? [] : [ver]
            selectedVersion = pythonVersions.first ?? ""
        default:
            selectedVersion = ""
        }
    }

    /// Returns the version list for the currently selected runtime.
    public var currentVersions: [String] {
        switch runtime {
        case .php: return phpVersions
        case .nodejs: return nodeVersions
        case .python: return pythonVersions
        default: return []
        }
    }

    /// Whether the current runtime supports version selection.
    public var runtimeHasVersions: Bool {
        switch runtime {
        case .php, .nodejs, .python: return true
        default: return false
        }
    }

    // MARK: - Domain & Path Handling

    /// Called from View's .onChange(of: domain). Sanitizes and auto-fills doc root.
    public func onDomainInput() {
        let sanitized = domain.filter { char in
            char.isASCII && (char.isLetter || char.isNumber || char == "." || char == "-")
        }.lowercased()

        if sanitized != domain {
            domain = sanitized
            return // onChange will fire again with clean value
        }

        validationErrors.removeValue(forKey: "domain")

        if !userEditedDocumentRoot {
            documentRoot = domain.isEmpty ? "" : "\(detectedWebRoot)/\(domain)"
        }
    }

    /// Called from View's .onChange(of: runtime)
    public func onRuntimeInput() {
        Task {
            await loadVersionsForRuntime(runtime)
        }
    }

    // MARK: - Directory Browser

    public func loadDirectories(at path: String) async {
        guard let serverId = serverId else { return }
        isLoadingDirectories = true
        browserCurrentPath = path

        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.listDirectoriesCmd(path: path))
        browserDirectories = result.components(separatedBy: "\n").filter { !$0.isEmpty }

        isLoadingDirectories = false
    }

    public func createNewFolder() async {
        guard let serverId = serverId, !newFolderName.isEmpty else { return }

        let sanitizedName = newFolderName.filter { $0.isASCII && !$0.isWhitespace }
        guard !sanitizedName.isEmpty else { return }

        let fullPath = "\(browserCurrentPath)/\(sanitizedName)"

        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.createDirectoryCmd(path: fullPath))
        newFolderName = ""
        await loadDirectories(at: browserCurrentPath)
    }

    public func selectDirectory(_ path: String) {
        documentRoot = path
        userEditedDocumentRoot = true
        isShowingDirectoryBrowser = false
    }

    // MARK: - Validation

    /// Validates all form fields.
    public func validate() -> Bool {
        validationErrors.removeAll()

        // Validate domain
        if domain.isEmpty {
            validationErrors["domain"] = "Domain is required"
        } else if !isValidDomain(domain) {
            validationErrors["domain"] = "Invalid domain format (e.g. example.com)"
        }

        // Validate document root
        if !documentRoot.isEmpty && !isValidPath(documentRoot) {
            validationErrors["documentRoot"] = "Invalid path (English characters only, no spaces)"
        }

        return validationErrors.isEmpty
    }

    /// Validates domain format: only English chars, digits, dots, hyphens.
    private func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = "^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        return predicate.evaluate(with: domain)
    }

    /// Validates path: ASCII only, no spaces, must start with /.
    private func isValidPath(_ path: String) -> Bool {
        guard path.hasPrefix("/") else { return false }
        return path.allSatisfy { $0.isASCII && !$0.isWhitespace }
    }

    // MARK: - Website Creation

    /// Creates website via Core layer.
    public func createWebsite() async throws {
        guard validate() else {
            throw AddWebsiteError.validationFailed
        }

        guard let serverId = serverId else {
            throw AddWebsiteError.serverNotConfigured
        }

        isCreating = true
        errorMessage = nil

        do {
            let phpVersion: String? = runtime == .php ? selectedVersion : nil
            
            // Build config JSON for Go Core bridge
            // Keys must match Go SiteConfig json tags: "root" (not "document_root"), "template", "php_version"
            let sitesAvailable = selectedEngine == "apache" ? serverPaths.apacheSitesAvailable : serverPaths.nginxSitesAvailable
            let sitesEnabled = selectedEngine == "apache" ? serverPaths.apacheSitesEnabled : serverPaths.nginxSitesEnabled
            var config: [String: Any] = [
                "domain": domain,
                "root": documentRoot.isEmpty ? "\(detectedWebRoot)/\(domain)" : documentRoot,
                "template": runtime == .php ? "php" : (runtime == .nodejs ? "nodejs" : "static"),
                "sites_available": sitesAvailable,
                "sites_enabled": sitesEnabled,
                "web_ownership": serverPaths.webOwnership
            ]
            if let phpVersion = phpVersion { config["php_version"] = phpVersion }
            let configJSON = String(data: try JSONSerialization.data(withJSONObject: config), encoding: .utf8) ?? "{}"

            // Get create commands from Go Core
            let cmds = bridge.createSiteCmd(engine: selectedEngine, serverID: serverId, configJSON: configJSON)
            for cmd in cmds {
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                // Strip known success markers before checking for errors
                let cleaned = result
                    .replacingOccurrences(of: "AEVONX_ERRORPAGES_DEPLOYED", with: "")
                    .replacingOccurrences(of: "AEVONX_ERRORPAGE_EOF", with: "")
                if cleaned.localizedCaseInsensitiveContains("error") || cleaned.localizedCaseInsensitiveContains("failed") || cleaned.localizedCaseInsensitiveContains("permission denied") {
                    CoreLogger.shared.error("Website creation command failed: \(result)", module: "AddWebsiteViewModel")
                    throw AddWebsiteError.creationFailed(result)
                }
            }

            // Enable SSL in background — don't block website creation
            if enableSSL {
                let sslDomain = domain
                let sslServerId = serverId
                let sslBridge = bridge
                let sslEngine = selectedEngine
                Task { @MainActor in
                    await Self.issueSSLInBackground(domain: sslDomain, serverId: sslServerId, bridge: sslBridge, engine: sslEngine)
                }
            }

            CoreLogger.shared.info("Website '\(domain)' created successfully",
                                  module: "AddWebsiteViewModel")

        } catch {
            CoreLogger.shared.error("Failed to create website: \(error.localizedDescription)",
                                   module: "AddWebsiteViewModel")
            errorMessage = error.localizedDescription
            isCreating = false
            throw error
        }

        isCreating = false
    }

    // MARK: - Background SSL

    /// Issues SSL in background with progress toasts. Shared by AddWebsite and ManagementVM.
    static func issueSSLInBackground(domain: String, serverId: String, bridge: WebsitesBridge, engine: String = "nginx") async {
        let toastID = GlobalToastManager.shared.showProgress("SSL: Setting up for \(domain)...")

        let sslCmds = bridge.issueSSLCmd(engine: engine, domain: domain)
        for cmd in sslCmds {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)

            // Parse AEVON_SSL_* markers for progress
            if result.contains("AEVON_SSL_INSTALLING") {
                GlobalToastManager.shared.updateProgress(id: toastID, message: "SSL: Installing certbot...")
            }
            if result.contains("AEVON_SSL_INSTALLED") {
                GlobalToastManager.shared.updateProgress(id: toastID, message: "SSL: Certbot ready, issuing certificate...")
            }
            if result.contains("AEVON_SSL_ISSUING") {
                GlobalToastManager.shared.updateProgress(id: toastID, message: "SSL: Issuing certificate for \(domain)...")
            }

            if result.contains("AEVON_SSL_SUCCESS") {
                GlobalToastManager.shared.dismiss(id: toastID)
                GlobalToastManager.shared.showSuccess("SSL enabled for \(domain)")
                CoreLogger.shared.info("SSL enabled for '\(domain)' (background)", module: "SSL")
                return
            }

            if result.contains("AEVON_SSL_INSTALL_FAILED") {
                GlobalToastManager.shared.dismiss(id: toastID)
                GlobalToastManager.shared.showError("SSL: certbot could not be installed on server")
                CoreLogger.shared.warning("certbot installation failed for '\(domain)'", module: "SSL")
                return
            }

            if result.contains("AEVON_SSL_FAILED") {
                GlobalToastManager.shared.dismiss(id: toastID)
                GlobalToastManager.shared.showError("SSL certificate failed for \(domain)")
                CoreLogger.shared.warning("SSL issuance failed for '\(domain)'", module: "SSL")
                return
            }
        }

        // Fallback — no markers found (unexpected)
        GlobalToastManager.shared.dismiss(id: toastID)
        GlobalToastManager.shared.showInfo("SSL setup completed for \(domain)")
    }
}

// MARK: - Add Website Error

public enum AddWebsiteError: LocalizedError {
    case validationFailed
    case serverNotConfigured
    case creationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .validationFailed:
            return "Please fix validation errors"
        case .serverNotConfigured:
            return "Server not configured"
        case .creationFailed(let reason):
            return "Failed to create website: \(reason)"
        }
    }
}
