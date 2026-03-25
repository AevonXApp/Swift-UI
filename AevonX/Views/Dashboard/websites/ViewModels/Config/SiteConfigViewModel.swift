//
//  SiteConfigViewModel.swift
//  AevonX
//
//  ViewModel for per-site Nginx config editing — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class SiteConfigViewModel: ObservableObject {
    @Published var configContent = ""
    @Published var configPath = ""
    @Published var configBackups: [ConfigBackupItem] = []
    @Published var validationResult: String?
    @Published var validationPassed = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isValidating = false
    @Published var hasUnsavedChanges = false

    let serverId: String
    let domain: String
    let engine: String
    private var originalContent = ""
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, engine: String = "nginx") {
        self.serverId = serverId
        self.domain = domain
        self.engine = engine
    }

    func loadConfig() async {
        isLoading = true
        defer { isLoading = false }
        await detectPathsIfNeeded()
        let path = resolveConfigPath()
        configPath = path
        let cmd = bridge.readConfigCmdRouted(engine: engine, configPath: path)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        configContent = result
        originalContent = result
        hasUnsavedChanges = false
    }

    func validateConfig() async {
        isValidating = true
        defer { isValidating = false }
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.validateConfigCmdRouted(engine: engine))
        validationResult = result
        validationPassed = result.contains("successful") || result.contains("syntax is ok") || result.contains("Syntax OK")
    }

    func saveConfig() async {
        isSaving = true
        defer { isSaving = false }
        await detectPathsIfNeeded()
        let path = configPath.isEmpty ? resolveConfigPath() : configPath
        let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupDir = "/var/backups/aevonx"
        // Backup + write via bridge
        let saveCmds = bridge.saveConfigCmdsRouted(engine: engine, configPath: path, content: configContent, domain: domain, timestamp: ts, backupDir: backupDir)
        for cmd in saveCmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        // Validate
        let test = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.validateConfigCmdRouted(engine: engine))
        validationResult = test
        validationPassed = test.contains("successful") || test.contains("syntax is ok") || test.contains("Syntax OK")
        if validationPassed {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId))
            originalContent = configContent
            hasUnsavedChanges = false
            GlobalToastManager.shared.showSuccess("Config saved & \(engine.capitalized) reloaded")
            await loadBackups()
        } else {
            // Rollback via bridge
            let backupFilename = "\(domain)_\(ts).conf.bak"
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restoreConfigBackupCmd(configPath: path, backupFilename: backupFilename, backupDir: backupDir))
            errorMessage = "Validation failed — config rolled back"
        }
    }

    func loadBackups() async {
        let backupDir = "/var/backups/aevonx"
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.listConfigBackupsCmd(domain: domain, backupDir: backupDir))
        configBackups = result.components(separatedBy: "\n").filter { !$0.isEmpty }.map {
            let filename = ($0 as NSString).lastPathComponent
            let parts = $0.components(separatedBy: " ")
            let date = parts.count > 1 ? parts.dropFirst().joined(separator: " ") : filename
            return ConfigBackupItem(filename: filename, formattedDate: date)
        }
    }

    func restoreBackup(_ backup: ConfigBackupItem) async {
        let path = configPath.isEmpty ? resolveConfigPath() : configPath
        let backupDir = "/var/backups/aevonx"
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restoreConfigBackupCmd(configPath: path, backupFilename: backup.filename, backupDir: backupDir))
        await loadConfig()
        GlobalToastManager.shared.showSuccess("Backup restored")
    }

    func applyTemplate(_ template: SiteConfigTemplate, docRoot: String) {
        configContent = bridge.generateTemplateConfig(template: template.rawValue.lowercased(), domain: domain, docRoot: docRoot)
        hasUnsavedChanges = true
    }

    func contentDidChange() {
        hasUnsavedChanges = configContent != originalContent
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    private func resolveConfigPath() -> String {
        let sa = engine == "apache" ? serverPaths.apacheSitesAvailable : serverPaths.nginxSitesAvailable
        if engine == "apache" {
            return "\(sa)/\(domain).conf"
        }
        if serverPaths.serverType == "bt_panel" || sa.contains("/www/server") || sa.contains("/conf.d") || sa.contains("/vhost") {
            return "\(sa)/\(domain).conf"
        }
        return "\(sa)/\(domain)"
    }
}

// MARK: - UI Models

struct ConfigBackupItem: Identifiable {
    let id = UUID()
    let filename: String
    let formattedDate: String
}
