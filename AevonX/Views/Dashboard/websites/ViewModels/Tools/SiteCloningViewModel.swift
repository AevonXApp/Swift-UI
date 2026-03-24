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
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
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
            sitesAvailable: serverPaths.nginxSitesAvailable,
            sitesEnabled: serverPaths.nginxSitesEnabled
        )
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

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
            sitesAvailable: serverPaths.nginxSitesAvailable,
            sitesEnabled: serverPaths.nginxSitesEnabled
        )
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

        lastCloneResult = CloneResultItem(domain: stagingDomain, docRoot: "\(serverPaths.webRoot)/\(stagingDomain)", size: "N/A")
        GlobalToastManager.shared.showSuccess("Staging created: \(stagingDomain)")
    }

    func exportForMigration() async {
        isCloning = true; cloningProgress = "Exporting for migration..."
        defer { isCloning = false; cloningProgress = "" }
        await detectPathsIfNeeded()
        let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let cmds = bridge.exportMigrationCmds(domain: domain, docRoot: docRoot, sitesAvailable: serverPaths.nginxSitesAvailable, timestamp: ts)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        exportPath = "\(serverPaths.backupDir)/\(domain)_migration_\(ts).tar.gz"
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
