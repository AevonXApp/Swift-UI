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
        do {
            let cmd = bridge.listBackupsCmd(domain: domain)
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createBackup(type: SiteBackupType) async {
        isCreatingBackup = true
        backupProgress = "Creating \(type.rawValue) backup..."
        defer { isCreatingBackup = false; backupProgress = "" }
        do {
            let cmds = bridge.backupSiteCmds(domain: domain, docRoot: docRoot)
            for cmd in cmds {
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            }
            GlobalToastManager.shared.showSuccess("Backup created")
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreBackup(_ backup: SiteBackupInfo) async {
        backupProgress = "Restoring from \(backup.filename)..."
        do {
            let cmd = bridge.restoreBackupCmd(filename: backup.filename, docRoot: docRoot)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            GlobalToastManager.shared.showSuccess("Restored from \(backup.filename)")
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
        backupProgress = ""
    }

    func deleteBackup(_ backup: SiteBackupInfo) async {
        do {
            let cmd = bridge.deleteBackupCmd(filename: backup.filename)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteOldBackups(olderThanDays: Int) async {
        do {
            await detectPathsIfNeeded()
            let cmd = "find \(serverPaths.backupDir) -name '\(domain)_*' -mtime +\(olderThanDays) -delete 2>/dev/null; echo 'done'"
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            GlobalToastManager.shared.showSuccess("Old backups deleted")
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
