//
//  BackupViewModel.swift
//  AevonX
//
//  ViewModel for per-site backup/restore — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class BackupViewModel: ObservableObject {
    @Published var backups: [SiteBackupInfo] = []
    @Published var isCreatingBackup = false
    @Published var backupProgress = ""
    @Published var errorMessage: String?

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

    func loadBackups() async {
        await detectPathsIfNeeded()
        let cmd = bridge.listBackupsCmd(domain: domain, backupDir: serverPaths.backupDir)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseBackupList(output: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let entries = resp["data"] as? [[String: Any]] {
            backups = entries.compactMap { entry in
                guard let filename = entry["filename"] as? String else { return nil }
                let typeStr = entry["type"] as? String ?? "full"
                let backupType: SiteBackupType
                switch typeStr {
                case "files": backupType = .filesOnly
                case "database": backupType = .databaseOnly
                default: backupType = .full
                }
                return SiteBackupInfo(
                    filename: filename,
                    type: backupType,
                    date: Date(),
                    size: entry["size"] as? String ?? "Unknown",
                    path: filename,
                    includesDatabase: typeStr == "full" || typeStr == "database"
                )
            }
        }
    }

    func createBackup(type: SiteBackupType) async {
        isCreatingBackup = true
        backupProgress = "Creating \(type.rawValue) backup..."
        defer { isCreatingBackup = false; backupProgress = "" }
        await detectPathsIfNeeded()
        let cmds = bridge.backupSiteCmds(domain: domain, docRoot: docRoot, backupDir: serverPaths.backupDir)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        GlobalToastManager.shared.showSuccess("Backup created")
        await loadBackups()
    }

    func restoreBackup(_ backup: SiteBackupInfo) async {
        backupProgress = "Restoring from \(backup.filename)..."
        let cmd = bridge.restoreBackupCmd(domain: domain, backupFile: backup.filename, docRoot: docRoot)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        GlobalToastManager.shared.showSuccess("Restored from \(backup.filename)")
        await loadBackups()
        backupProgress = ""
    }

    func deleteBackup(_ backup: SiteBackupInfo) async {
        let cmd = bridge.deleteBackupCmd(filename: backup.filename, domain: domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        await loadBackups()
    }

    func deleteOldBackups(olderThanDays: Int) async {
        await detectPathsIfNeeded()
        let safeDir = ShellSanitizer.escapePath(serverPaths.backupDir)
        let safeDomain = ShellSanitizer.sanitizeIdentifier(domain)
        let safeDays = max(1, olderThanDays)
        let cmd = "find \(safeDir) -name '\(safeDomain)_*' -mtime +\(safeDays) -delete 2>/dev/null; echo 'done'"
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        GlobalToastManager.shared.showSuccess("Old backups deleted")
        await loadBackups()
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
