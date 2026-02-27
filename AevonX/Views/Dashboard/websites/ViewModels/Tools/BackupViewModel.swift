//
//  BackupViewModel.swift
//  AevonX
//
//  ViewModel for per-site backup/restore — delegates to SiteBackupService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class BackupViewModel: ObservableObject {
    @Published var backups: [SiteBackupInfo] = []
    @Published var isCreatingBackup = false
    @Published var backupProgress = ""
    @Published var errorMessage: String?

    let serverId: String
    let domain: String
    let docRoot: String
    private let service = SiteBackupService.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func loadBackups() async {
        do {
            let entries = try await service.listBackups(domain: domain, serverId: serverId)
            backups = entries.map { entry in
                let backupType: SiteBackupType
                switch entry.type {
                case "full": backupType = .full
                case "files": backupType = .filesOnly
                case "database": backupType = .databaseOnly
                default: backupType = .full
                }
                return SiteBackupInfo(
                    filename: entry.filename,
                    type: backupType,
                    date: Date(),
                    size: entry.size,
                    path: entry.filename,
                    includesDatabase: entry.type == "full" || entry.type == "database"
                )
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
            let filename = try await service.createBackup(
                type: type.rawValue.lowercased(),
                domain: domain,
                docRoot: docRoot,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("Backup created: \(filename)")
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreBackup(_ backup: SiteBackupInfo) async {
        backupProgress = "Restoring from \(backup.filename)..."
        do {
            try await service.restoreBackup(
                filename: backup.filename,
                domain: domain,
                docRoot: docRoot,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("Restored from \(backup.filename)")
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
        backupProgress = ""
    }

    func deleteBackup(_ backup: SiteBackupInfo) async {
        do {
            try await service.deleteBackup(filename: backup.filename, domain: domain, serverId: serverId)
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteOldBackups(olderThanDays: Int) async {
        do {
            let count = try await service.deleteOldBackups(domain: domain, olderThanDays: olderThanDays, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Deleted \(count) old backups")
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
