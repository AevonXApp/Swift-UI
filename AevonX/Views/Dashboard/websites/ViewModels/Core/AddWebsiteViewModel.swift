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

    @Published public var domain = "" {
        didSet { onDomainChanged() }
    }
    @Published public var runtime: RuntimeType = .php {
        didSet { onRuntimeChanged() }
    }
    @Published public var selectedVersion = ""
    @Published public var enableSSL = true
    @Published public var documentRoot = ""
    @Published public var userEditedDocumentRoot = false

    // Server capabilities
    @Published public var isLoadingCapabilities = true
    @Published public var availableRuntimes: [RuntimeType] = [.static]
    @Published public var phpVersions: [String] = []
    @Published public var nodeVersions: [String] = []
    @Published public var pythonVersions: [String] = []
    @Published public var detectedWebRoot = ServerPaths.defaults.webRoot

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

    // MARK: - Initialization

    public init(serverId: String?) {
        self.serverId = serverId
    }

    // MARK: - Server Capabilities

    /// Fetches installed runtimes and versions from the server.
    public func loadServerCapabilities() async {
        guard let serverId = serverId else {
            isLoadingCapabilities = false
            return
        }

        isLoadingCapabilities = true

        do {
            // Detect installed runtimes via SSH
            var runtimes: [RuntimeType] = [.static]
            
            let phpCheck = await SSHBridge.shared.executeAsync(serverID: serverId, command: "which php 2>/dev/null && echo YES || echo NO")
            if phpCheck.contains("YES") { runtimes.append(.php) }
            
            let nodeCheck = await SSHBridge.shared.executeAsync(serverID: serverId, command: "which node 2>/dev/null && echo YES || echo NO")
            if nodeCheck.contains("YES") { runtimes.append(.nodejs) }
            
            let pyCheck = await SSHBridge.shared.executeAsync(serverID: serverId, command: "which python3 2>/dev/null && echo YES || echo NO")
            if pyCheck.contains("YES") { runtimes.append(.python) }
            
            availableRuntimes = runtimes

            // Set default runtime
            if availableRuntimes.contains(.php) {
                runtime = .php
            } else if let first = availableRuntimes.first {
                runtime = first
            }

            // Detect web root using PathResolver
            let pathCmd = PathResolverBridge.shared.detectCmd()
            let pathOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: pathCmd)
            let detectedPaths = PathResolverBridge.shared.parse(output: pathOutput)
            detectedWebRoot = detectedPaths.webRoot

            // Load versions for the selected runtime
            await loadVersionsForRuntime(runtime)

        } catch {
            CoreLogger.shared.error("Failed to load server capabilities: \(error.localizedDescription)", module: "AddWebsiteViewModel")
            availableRuntimes = RuntimeType.allCases
        }

        isLoadingCapabilities = false
    }

    /// Loads version list for the given runtime type.
    private func loadVersionsForRuntime(_ runtime: RuntimeType) async {
        guard let serverId = serverId else { return }

        do {
            switch runtime {
            case .php:
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "ls /etc/php/ 2>/dev/null | sort -V")
                phpVersions = result.components(separatedBy: "\n").filter { !$0.isEmpty }
                selectedVersion = phpVersions.first ?? ""
            case .nodejs:
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "node --version 2>/dev/null | tr -d 'v'")
                let ver = result.trimmingCharacters(in: .whitespacesAndNewlines)
                nodeVersions = ver.isEmpty ? [] : [ver]
                selectedVersion = nodeVersions.first ?? ""
            case .python:
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "python3 --version 2>/dev/null | awk '{print $2}'")
                let ver = result.trimmingCharacters(in: .whitespacesAndNewlines)
                pythonVersions = ver.isEmpty ? [] : [ver]
                selectedVersion = pythonVersions.first ?? ""
            default:
                selectedVersion = ""
            }
        } catch {
            CoreLogger.shared.error("Failed to load versions for \(runtime.rawValue): \(error.localizedDescription)", module: "AddWebsiteViewModel")
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

    private func onDomainChanged() {
        // Sanitize domain: only allow valid characters
        let sanitized = domain.filter { char in
            char.isASCII && (char.isLetter || char.isNumber || char == "." || char == "-")
        }.lowercased()

        if sanitized != domain {
            domain = sanitized
            return // will re-trigger didSet
        }

        // Clear validation error when user starts typing
        validationErrors.removeValue(forKey: "domain")

        // Auto-fill document root if user hasn't manually edited it
        if !userEditedDocumentRoot && !domain.isEmpty {
            documentRoot = "\(detectedWebRoot)/\(domain)"
        }
    }

    private func onRuntimeChanged() {
        Task {
            await loadVersionsForRuntime(runtime)
        }
    }

    // MARK: - Directory Browser

    public func loadDirectories(at path: String) async {
        guard let serverId = serverId else { return }
        isLoadingDirectories = true
        browserCurrentPath = path

        do {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "ls -1 -d \(path)/*/ 2>/dev/null | xargs -I{} basename {}")
            browserDirectories = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        } catch {
            browserDirectories = []
            CoreLogger.shared.error("Failed to list directories: \(error.localizedDescription)", module: "AddWebsiteViewModel")
        }

        isLoadingDirectories = false
    }

    public func createNewFolder() async {
        guard let serverId = serverId, !newFolderName.isEmpty else { return }

        let sanitizedName = newFolderName.filter { $0.isASCII && !$0.isWhitespace }
        guard !sanitizedName.isEmpty else { return }

        let fullPath = "\(browserCurrentPath)/\(sanitizedName)"

        do {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo mkdir -p \(fullPath)")
            newFolderName = ""
            await loadDirectories(at: browserCurrentPath)
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
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
            var config: [String: Any] = [
                "domain": domain,
                "document_root": documentRoot.isEmpty ? "\(detectedWebRoot)/\(domain)" : documentRoot
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
