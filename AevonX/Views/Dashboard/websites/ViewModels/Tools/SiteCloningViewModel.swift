//
//  SiteCloningViewModel.swift
//  AevonX
//
//  ViewModel for site cloning and migration — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class SiteCloningViewModel: ObservableObject {
    @Published var targetDomain = ""
    @Published var isCloning = false
    @Published var cloningProgress = ""
    @Published var lastCloneResult: CloneResultItem?
    @Published var exportPath: String?
    @Published var includeDBInExport = true

    let serverId: String
    let domain: String
    let docRoot: String
    let engine: String
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, docRoot: String, engine: String = "nginx") {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
        self.engine = engine
    }

    /// Resolve sites-available / sites-enabled based on the engine type
    private var sitesAvailable: String {
        engine == "apache" ? serverPaths.apacheSitesAvailable : serverPaths.nginxSitesAvailable
    }

    private var sitesEnabled: String {
        engine == "apache" ? serverPaths.apacheSitesEnabled : serverPaths.nginxSitesEnabled
    }

    func cloneSite() async {
        guard !targetDomain.isEmpty else { return }
        isCloning = true; cloningProgress = "Cloning files..."
        defer { isCloning = false; cloningProgress = "" }
        await detectPathsIfNeeded()
        let cmds = bridge.cloneSiteCmds(
            source: domain,
            target: targetDomain,
            docRoot: docRoot,
            sitesAvailable: sitesAvailable,
            sitesEnabled: sitesEnabled,
            webOwnership: serverPaths.webOwnership
        )
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartEngineCmdRouted(engine: engine))

        let sizeResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.getDiskUsageCmd(docRoot: "\(serverPaths.webRoot)/\(targetDomain)"))
        let size = sizeResult.trimmingCharacters(in: .whitespacesAndNewlines)
        lastCloneResult = CloneResultItem(domain: targetDomain, docRoot: "\(serverPaths.webRoot)/\(targetDomain)", size: size.isEmpty ? "N/A" : size)
        GlobalToastManager.shared.showSuccess("Site cloned to \(targetDomain)")
    }

    func createStaging() async {
        isCloning = true; cloningProgress = "Creating staging..."
        defer { isCloning = false; cloningProgress = "" }
        await detectPathsIfNeeded()
        let stagingDomain = "staging.\(domain)"
        let cmds = bridge.cloneSiteCmds(
            source: domain,
            target: stagingDomain,
            docRoot: docRoot,
            sitesAvailable: sitesAvailable,
            sitesEnabled: sitesEnabled,
            webOwnership: serverPaths.webOwnership
        )
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartEngineCmdRouted(engine: engine))

        lastCloneResult = CloneResultItem(domain: stagingDomain, docRoot: "\(serverPaths.webRoot)/\(stagingDomain)", size: "N/A")
        GlobalToastManager.shared.showSuccess("Staging created: \(stagingDomain)")
    }

    func exportForMigration() async {
        isCloning = true; cloningProgress = "Exporting for migration..."
        defer { isCloning = false; cloningProgress = "" }
        await detectPathsIfNeeded()
        let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        var cmds = bridge.exportMigrationCmds(domain: domain, docRoot: docRoot, sitesAvailable: sitesAvailable, timestamp: ts)

        // If user wants DB included, inject a mysqldump before the tar step
        if includeDBInExport {
            let exportDir = "/tmp/aevonx_migration_\(domain)_\(ts)"
            let dbDumpCmd = "DB_NAME=$(grep -oP \"define\\\\(\\s*'DB_NAME'\\s*,\\s*'\\\\K[^']+\" \(docRoot)/wp-config.php 2>/dev/null || echo ''); " +
                "if [ -n \"$DB_NAME\" ]; then sudo mysqldump --single-transaction \"$DB_NAME\" 2>/dev/null | gzip > \(exportDir)/database.sql.gz; fi"
            // Insert before the tar command (second to last)
            if cmds.count >= 2 {
                cmds.insert(dbDumpCmd, at: cmds.count - 2)
            }
        }

        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        // Go ExportForMigrationCmds creates archive at /tmp/aevonx_migration_{domain}_{ts}.tar.gz
        exportPath = "/tmp/aevonx_migration_\(domain)_\(ts).tar.gz"
        GlobalToastManager.shared.showSuccess("Migration export ready")
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}

// MARK: - UI Models

struct CloneResultItem: Identifiable {
    let id = UUID()
    let domain: String
    let docRoot: String
    let size: String
}
