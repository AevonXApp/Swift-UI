//
//  HookLoader.swift
//  AevonXCoreBridge
//
//  High-performance plugin loader with:
//    • Batch SSH Discovery — single SSH command reads ALL JSON files at once
//    • Lazy Tab Loading   — tab content loaded on-demand, not upfront
//    • TTL Cache          — skips SSH for repeated loads within 5 minutes
//

import Foundation

public extension Notification.Name {
    static let pluginsDidReload = Notification.Name("pluginsDidReload")
}
import Combine

@MainActor
public final class HookLoader: ObservableObject {

    public static let shared = HookLoader()

    /// Remote root directory on the server
    static let remoteRoot = "/etc/aevonx/hooks"

    /// All loaded namespaces (for display in Plugins tab)
    @Published public private(set) var namespaces: [HookNamespace] = []

    /// Total number of loaded plugins across all namespaces
    @Published public private(set) var totalPluginCount: Int = 0

    /// Whether a load is in progress
    @Published public private(set) var isLoading: Bool = false

    /// Last load error
    @Published public private(set) var lastError: String?

    private let validator = PluginPermissionValidator.shared

    // ── Cache ────────────────────────────────────────────────────────────
    private var cacheServerId: String?
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    // ── Lazy Tab Storage ─────────────────────────────────────────────────
    /// Maps tab file paths to their raw JSON data (loaded during batch but injected lazily)
    private var tabDataCache: [String: Data] = [:]

    private init() {}

    // MARK: - Public API

    /// Load all plugins from /etc/aevonx/hooks/{namespace}/*.json on the remote server.
    /// Uses batch discovery (1 SSH call) + TTL cache.
    public func load(serverId: String, force: Bool = false) async {
        // Cache check — skip SSH if data is fresh
        if !force,
           cacheServerId == serverId,
           let ts = cacheTimestamp,
           Date().timeIntervalSince(ts) < cacheTTL,
           !namespaces.isEmpty {
            CoreLogger.shared.debug("[HookLoader] Using cached data (age: \(Int(Date().timeIntervalSince(ts)))s)", module: "HookLoader")
            return
        }

        isLoading = true
        lastError = nil

        let startTime = CFAbsoluteTimeGetCurrent()
        CoreLogger.shared.debug("[HookLoader] Batch loading from \(Self.remoteRoot) on server \(serverId)", module: "HookLoader")

        // ── SINGLE SSH CALL: Read ALL JSON files at once ─────────────────
        let discovered = await batchDiscoverAll(serverId: serverId)

        let sshTime = CFAbsoluteTimeGetCurrent() - startTime
        CoreLogger.shared.info("[HookLoader] SSH batch completed in \(String(format: "%.2f", sshTime))s — \(discovered.count) namespace(s)", module: "HookLoader")

        // Phase 1: Register ALL manifests first (for Smart Auto-Trust).
        // We forward `allowed_actions` from the namespace manifest so the
        // permission validator can enforce the whitelist when the user (not
        // a developer with the bypass toggle) invokes a config action.
        PluginManifestStore.shared.clearAll()
        for ns in discovered {
            if let nsManifest = ns.manifest {
                let pm = PluginManifestStore.PluginManifest(
                    slug: ns.id,
                    installPath: nsManifest.commandsPath ?? "",
                    argStyle: nsManifest.argStyle,
                    commandsPath: nsManifest.commandsPath,
                    binary: nsManifest.binary,
                    allowedActions: nsManifest.allowedActions
                )
                if let rawData = ns.manifestRawData {
                    PluginManifestStore.shared.register(pm, rawData: rawData)
                } else {
                    PluginManifestStore.shared.register(pm)
                }
            }
        }

        // Phase 2: Validate and register plugins
        let registry = HookRegistry.shared
        registry.clearAll()

        var allNamespaces: [HookNamespace] = []
        var total = 0

        for ns in discovered {
            if let manifest = ns.manifest {
                registry.registerManifest(manifest, namespace: ns.id)
            }

            var validPlugins: [HookPluginDefinition] = []
            for var plugin in ns.plugins {
                plugin.namespace = ns.id
                let validation = validator.validate(plugin: plugin)
                if validation.isAllowed {
                    registry.register(plugin)
                    validPlugins.append(plugin)
                } else {
                    CoreLogger.shared.warning("[HookLoader] Rejected \(plugin.id): \(validation.rejectionReason ?? "unknown")", module: "HookLoader")
                }
            }

            let updatedNs = HookNamespace(id: ns.id, manifest: ns.manifest, plugins: validPlugins, manifestRawData: ns.manifestRawData)
            allNamespaces.append(updatedNs)
            total += validPlugins.count
        }

        resolveDependencies(in: registry)

        namespaces = allNamespaces
        totalPluginCount = total
        isLoading = false

        // Update cache
        cacheServerId = serverId
        cacheTimestamp = Date()

        NotificationCenter.default.post(name: .pluginsDidReload, object: nil)

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        CoreLogger.shared.info("[HookLoader] Loaded \(total) plugins from \(allNamespaces.count) namespaces in \(String(format: "%.2f", totalTime))s", module: "HookLoader")
    }

    private func resolveDependencies(in registry: HookRegistry) {
        let allPlugins = registry.allPlugins()
        let loadedIds = Set(allPlugins.map { $0.id })

        for plugin in allPlugins {
            guard let deps = plugin.dependencies, !deps.isEmpty else { continue }
            for dep in deps {
                if !loadedIds.contains(dep) {
                    registry.unregister(pluginId: plugin.id)
                    CoreLogger.shared.warning("[HookLoader] Blocked '\(plugin.id)': missing dependency '\(dep)'", module: "HookLoader")
                    HookEventBus.shared.emit(
                        source: plugin.id,
                        name: "dependency.missing",
                        payload: ["plugin": plugin.id, "missing_dep": dep]
                    )
                    break
                }
            }
        }
    }

    public func unload() {
        HookRegistry.shared.clearAll()
        PluginManifestStore.shared.clearAll()
        namespaces = []
        totalPluginCount = 0
        tabDataCache = [:]
        cacheTimestamp = nil
        cacheServerId = nil
        CoreLogger.shared.debug("[HookLoader] Unloaded all plugins", module: "HookLoader")
    }

    /// Invalidate cache — next load will fetch from server
    public func invalidateCache() {
        cacheTimestamp = nil
        cacheServerId = nil
    }

    // MARK: - Batch Discovery (Single SSH Call)

    /// Reads ALL JSON files under /etc/aevonx/hooks in a single SSH command.
    /// Parses output into namespace structures with manifests, plugins, and tabs.
    private func batchDiscoverAll(serverId: String) async -> [HookNamespace] {
        // Single SSH command: find all JSON files and dump their content with path markers
        let batchCmd = """
        if [ ! -d \(Self.remoteRoot) ]; then echo "===EMPTY==="; exit 0; fi
        find \(Self.remoteRoot) -name '*.json' -type f 2>/dev/null | sort | while IFS= read -r f; do
          printf '===FILE:%s===\\n' "$f"
          cat "$f" 2>/dev/null
        done
        """

        let raw = await SSHBridge.shared.executeAsync(serverID: serverId, command: batchCmd)
        let result = SSHResult.parse(raw)

        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        if output.isEmpty || output == "===EMPTY===" {
            CoreLogger.shared.debug("[HookLoader] \(Self.remoteRoot) does not exist or is empty", module: "HookLoader")
            return []
        }

        // Parse the batch output into file path → content pairs
        let fileEntries = parseBatchOutput(output)
        CoreLogger.shared.debug("[HookLoader] Batch read \(fileEntries.count) JSON files in 1 SSH call", module: "HookLoader")

        // Group files by namespace
        return buildNamespaces(from: fileEntries)
    }

    /// Parses "===FILE:/path===\n{json content}" format into a dictionary
    private func parseBatchOutput(_ output: String) -> [(path: String, content: String)] {
        var entries: [(path: String, content: String)] = []

        let marker = "===FILE:"
        let parts = output.components(separatedBy: marker)

        for part in parts {
            guard !part.isEmpty else { continue }

            // Split at first "===\n" to get path and content
            guard let markerEnd = part.range(of: "===") else { continue }
            let path = String(part[part.startIndex..<markerEnd.lowerBound])
            let content = String(part[markerEnd.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !path.isEmpty, !content.isEmpty else { continue }
            entries.append((path: path, content: content))
        }

        return entries
    }

    /// Groups parsed file entries into HookNamespace structures
    private func buildNamespaces(from entries: [(path: String, content: String)]) -> [HookNamespace] {
        // Group by namespace (first directory under remoteRoot)
        // Path format: /etc/aevonx/hooks/{namespace}/...
        struct NamespaceFiles {
            var manifestData: Data?
            var entryFiles: [(path: String, data: Data)] = []  // _index.json, hook.json, *.json at root
            var tabFiles: [(path: String, data: Data)] = []    // tab-*.json in subdirs
            var subDirEntryFiles: [String: Data] = [:]         // subdir/_index.json or subdir/hook.json
            var subDirTabs: [String: [(path: String, data: Data)]] = [:]  // subdir/tab-*.json
            var subDirSidebarFiles: [String: [String: Data]] = [:]  // subdir/sidebar-*.json keyed by filename
        }

        var nsMap: [String: NamespaceFiles] = [:]
        let rootPrefix = Self.remoteRoot + "/"

        for entry in entries {
            guard entry.path.hasPrefix(rootPrefix) else { continue }
            let relativePath = String(entry.path.dropFirst(rootPrefix.count))
            let components = relativePath.components(separatedBy: "/")

            guard let namespaceName = components.first, !namespaceName.isEmpty else { continue }
            let data = Data(entry.content.utf8)

            if nsMap[namespaceName] == nil {
                nsMap[namespaceName] = NamespaceFiles()
            }

            let fileName = components.last ?? ""

            if components.count == 2 {
                // Root-level namespace file: {namespace}/{file}
                // e.g. obsidian/_manifest.json → ["obsidian", "_manifest.json"]
                if fileName == "_manifest.json" {
                    nsMap[namespaceName]?.manifestData = data
                } else if fileName.hasSuffix(".json") {
                    nsMap[namespaceName]?.entryFiles.append((path: entry.path, data: data))
                }
            } else if components.count == 3 {
                // Subdirectory file: {namespace}/{subdir}/{file}
                // e.g. obsidian/01-dashboard/_index.json → ["obsidian", "01-dashboard", "_index.json"]
                let subDirName = components[1]

                if fileName == "_manifest.json" {
                    // Sub-manifest (ignore — only root _manifest.json matters)
                } else if fileName == "_index.json" || fileName == "hook.json" {
                    nsMap[namespaceName]?.subDirEntryFiles[subDirName] = data
                } else if fileName.hasPrefix("tab-") && fileName.hasSuffix(".json") {
                    if nsMap[namespaceName]?.subDirTabs[subDirName] == nil {
                        nsMap[namespaceName]?.subDirTabs[subDirName] = []
                    }
                    nsMap[namespaceName]?.subDirTabs[subDirName]?.append((path: entry.path, data: data))
                } else if fileName.hasSuffix(".json") {
                    // Any JSON file not matching special prefixes could be sidebar content
                    // (referenced by "file" field in _index.json sidebar items)
                    if nsMap[namespaceName]?.subDirSidebarFiles[subDirName] == nil {
                        nsMap[namespaceName]?.subDirSidebarFiles[subDirName] = [:]
                    }
                    nsMap[namespaceName]?.subDirSidebarFiles[subDirName]?[fileName] = data
                }
            }
        }

        // Build HookNamespace array from grouped files
        var namespaces: [HookNamespace] = []

        for (nsName, files) in nsMap.sorted(by: { $0.key < $1.key }) {
            var manifest: HookNamespaceManifest? = nil
            var plugins: [HookPluginDefinition] = []

            // Decode manifest
            if let mData = files.manifestData {
                manifest = try? JSONDecoder().decode(HookNamespaceManifest.self, from: mData)
                if manifest != nil {
                    CoreLogger.shared.debug("[HookLoader] [\(nsName)] Manifest: \(manifest?.name ?? "?") v\(manifest?.version ?? "?")", module: "HookLoader")
                }
            }

            // Decode root-level single-file plugins
            for entry in files.entryFiles {
                guard var plugin = try? JSONDecoder().decode(HookPluginDefinition.self, from: entry.data),
                      plugin.isEnabled else { continue }
                plugin.namespace = nsName
                plugins.append(plugin)
            }

            // Decode folder-based plugins (subdirectories)
            for (subDirName, entryData) in files.subDirEntryFiles {
                var plugin: HookPluginDefinition
                do {
                    plugin = try JSONDecoder().decode(HookPluginDefinition.self, from: entryData)
                } catch {
                    CoreLogger.shared.warning("[HookLoader] [\(nsName)] Failed to decode \(subDirName)/_index.json: \(error)", module: "HookLoader")
                    continue
                }
                guard plugin.isEnabled else { continue }

                // Auto-collect tabs from batch-loaded data (no extra SSH!)
                let needsAutoTabs = plugin.tabs == nil || plugin.tabs?.isEmpty == true
                if needsAutoTabs, let tabEntries = files.subDirTabs[subDirName], !tabEntries.isEmpty {
                    var tabs: [HookPluginDefinition] = []
                    for tabEntry in tabEntries {
                        if let tab = try? JSONDecoder().decode(HookPluginDefinition.self, from: tabEntry.data) {
                            tabs.append(tab)
                        }
                    }
                    if !tabs.isEmpty {
                        plugin = plugin.withTabs(tabs)
                        CoreLogger.shared.debug("[HookLoader] [\(nsName)] \(subDirName): \(tabs.count) tabs", module: "HookLoader")
                    }
                }

                // Resolve sidebar file references from batch-loaded data
                if var sidebarItems = plugin.sidebar, !sidebarItems.isEmpty,
                   let sidebarFileMap = files.subDirSidebarFiles[subDirName] {
                    for i in sidebarItems.indices {
                        guard let fileName = sidebarItems[i].file,
                              let fileData = sidebarFileMap[fileName],
                              let content = try? JSONDecoder().decode(HookPluginDefinition.self, from: fileData) else {
                            continue
                        }
                        sidebarItems[i].content = content
                        CoreLogger.shared.debug("[HookLoader] [\(nsName)] Sidebar: \(sidebarItems[i].label) -> \(fileName)", module: "HookLoader")
                    }
                    plugin.sidebar = sidebarItems
                }

                plugin.namespace = nsName
                plugins.append(plugin)
            }

            if !plugins.isEmpty || manifest != nil {
                namespaces.append(HookNamespace(id: nsName, manifest: manifest, plugins: plugins, manifestRawData: files.manifestData))
            }
        }

        return namespaces
    }
}

// Backward compatibility
public typealias PluginLoader = HookLoader
