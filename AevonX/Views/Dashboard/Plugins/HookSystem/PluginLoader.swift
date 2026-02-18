//
//  PluginLoader.swift
//  AevonX
//
//  Loads plugins from the REMOTE server via SSH.
//  Scans /etc/aevonx/hooks/{namespace}/*.json on the connected server.
//  Each subdirectory is a "namespace" (tool/developer name).
//  An optional _manifest.json in each namespace provides metadata.
//

import Foundation
import Combine
import AevonXCore

@MainActor
final class PluginLoader: ObservableObject {

    static let shared = PluginLoader()

    /// Remote root directory on the server
    static let remoteRoot = "/etc/aevonx/hooks"

    /// All loaded namespaces (for display in Plugins tab)
    @Published private(set) var namespaces: [HookNamespace] = []

    /// Total number of loaded plugins across all namespaces
    @Published private(set) var totalPluginCount: Int = 0

    /// Whether a load is in progress
    @Published private(set) var isLoading: Bool = false

    /// Last load error
    @Published private(set) var lastError: String?

    private let validator = PluginPermissionValidator.shared

    private init() {}

    // MARK: - Public API

    /// Load all plugins from /etc/aevonx/hooks/{namespace}/*.json on the remote server.
    /// Pass the serverId of the currently connected server.
    func load(serverId: String, force: Bool = false) async {
        isLoading = true
        lastError = nil

        print("[PluginLoader] Scanning \(Self.remoteRoot) on server \(serverId)")

        let discovered = await discoverNamespaces(serverId: serverId)

        // Register all plugins into HookRegistry
        let registry = HookRegistry.shared
        registry.clearAll()

        var allNamespaces: [HookNamespace] = []
        var total = 0

        for ns in discovered {
            for plugin in ns.plugins {
                registry.register(plugin)
            }
            allNamespaces.append(ns)
            total += ns.pluginCount
        }

        namespaces = allNamespaces
        totalPluginCount = total
        isLoading = false

        print("[PluginLoader] Loaded \(total) plugins from \(allNamespaces.count) namespaces")
    }

    /// Clear all plugins (called on disconnect)
    func unload() {
        HookRegistry.shared.clearAll()
        namespaces = []
        totalPluginCount = 0
        print("[PluginLoader] Unloaded all plugins")
    }

    // MARK: - Remote Discovery

    private func discoverNamespaces(serverId: String) async -> [HookNamespace] {
        // First ensure the directory exists
        let checkCmd = "test -d \(Self.remoteRoot) && echo EXISTS || echo MISSING"
        if let checkResult = try? await SSHService.shared.execute(checkCmd, serverId: serverId) {
            if checkResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "MISSING" {
                print("[PluginLoader] \(Self.remoteRoot) does not exist on server — create it with: mkdir -p \(Self.remoteRoot)")
                return []
            }
        }

        // List subdirectories — find is more reliable than ls glob
        let listCmd = "find \(Self.remoteRoot) -mindepth 1 -maxdepth 1 -type d 2>/dev/null; true"
        let result: SSHCommandResult
        do {
            result = try await SSHService.shared.execute(listCmd, serverId: serverId)
        } catch {
            print("[PluginLoader] SSH error listing \(Self.remoteRoot): \(error.localizedDescription)")
            return []
        }

        let dirs = result.stdout
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if dirs.isEmpty {
            print("[PluginLoader] No namespace directories found in \(Self.remoteRoot)")
            return []
        }

        print("[PluginLoader] Found \(dirs.count) namespace(s): \(dirs.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", "))")

        var namespaces: [HookNamespace] = []
        for dir in dirs {
            let namespaceName = URL(fileURLWithPath: dir).lastPathComponent
            let ns = await loadNamespace(id: namespaceName, remotePath: dir, serverId: serverId)
            if !ns.plugins.isEmpty || ns.manifest != nil {
                namespaces.append(ns)
            }
        }

        return namespaces
    }

    private func loadNamespace(id: String, remotePath: String, serverId: String) async -> HookNamespace {
        var manifest: HookNamespaceManifest? = nil
        var plugins: [HookPluginDefinition] = []

        // remotePath is absolute e.g. /etc/aevonx/hooks/waf-vip
        let manifestPath = "\(remotePath)/_manifest.json"
        if let manifestResult = try? await SSHService.shared.execute("cat '\(manifestPath)' 2>/dev/null", serverId: serverId),
           !manifestResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let data = manifestResult.stdout.data(using: .utf8) {
            manifest = try? JSONDecoder().decode(HookNamespaceManifest.self, from: data)
        }

        // List all .json files (skip _manifest.json) — find is reliable
        let listCmd = "find '\(remotePath)' -maxdepth 1 -name '*.json' ! -name '_manifest.json' 2>/dev/null; true"
        guard let listResult = try? await SSHService.shared.execute(listCmd, serverId: serverId) else {
            return HookNamespace(id: id, manifest: manifest, plugins: [])
        }

        let jsonFiles = listResult.stdout
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.hasSuffix(".json") }

        for filePath in jsonFiles {
            let catCmd = "cat \(filePath) 2>/dev/null"
            guard let fileResult = try? await SSHService.shared.execute(catCmd, serverId: serverId),
                  !fileResult.stdout.isEmpty,
                  let data = fileResult.stdout.data(using: .utf8) else {
                print("[PluginLoader] [\(id)] Failed to read \(filePath)")
                continue
            }

            guard var plugin = try? JSONDecoder().decode(HookPluginDefinition.self, from: data) else {
                print("[PluginLoader] [\(id)] Invalid JSON in \(filePath)")
                continue
            }

            guard plugin.isEnabled else {
                print("[PluginLoader] [\(id)] Skipping disabled: \(plugin.id)")
                continue
            }

            // Inject namespace
            plugin.namespace = id

            // Security validation
            let validation = validator.validate(plugin: plugin)
            guard validation.isAllowed else {
                print("[PluginLoader] [\(id)] SECURITY: Rejected \(plugin.id) — \(validation.rejectionReason ?? "unknown")")
                continue
            }

            plugins.append(plugin)
            print("[PluginLoader] [\(id)] ✓ \(plugin.id) → \(plugin.hook.rawValue)")
        }

        return HookNamespace(id: id, manifest: manifest, plugins: plugins)
    }
}
