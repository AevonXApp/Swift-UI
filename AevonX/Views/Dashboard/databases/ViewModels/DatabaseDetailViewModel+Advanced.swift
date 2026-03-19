//
//  DatabaseDetailViewModel+Advanced.swift
//  AevonX
//
//  Backup enhancements, advanced operations, and table operations
//  for database detail VM.
//

import Foundation
import SwiftUI
import AevonXCoreBridge
import AppKit
import UniformTypeIdentifiers

// MARK: - Backup Enhancements

extension DatabaseDetailViewModel {

    public func deleteBackup(_ backupId: String) async {
        guard let serverId = serverId else { return }

        do {
            try await DatabaseBackupService.shared.deleteBackup(
                backupPath: backupId,
                type: database.type,
                serverId: serverId
            )
            backups.removeAll { $0.id == backupId }
            GlobalToastManager.shared.showSuccess("Backup deleted")
            log(action: "Delete Backup", detail: backupId, success: true)
        } catch {
            GlobalToastManager.shared.showError("Failed to delete backup: \(error.localizedDescription)")
            log(action: "Delete Backup", detail: backupId, success: false, error: error.localizedDescription)
        }
    }

    public func downloadBackup(_ backupId: String) async {
        guard let serverId = serverId else { return }

        isDownloadingBackup = true
        let progressId = GlobalToastManager.shared.showProgress("Downloading backup...")

        do {
            let data = try await DatabaseBackupService.shared.downloadBackup(
                backupPath: backupId,
                type: database.type,
                serverId: serverId
            )

            GlobalToastManager.shared.dismiss(id: progressId)

            // Present Save As panel
            let panel = NSSavePanel()
            panel.nameFieldStringValue = URL(fileURLWithPath: backupId).lastPathComponent
            panel.allowedContentTypes = [UTType(filenameExtension: "sql") ?? .plainText]
            panel.canCreateDirectories = true
            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                try data.write(to: url)
                GlobalToastManager.shared.showSuccess("Backup saved successfully")
                log(action: "Download Backup", detail: url.lastPathComponent, success: true)
            }
        } catch {
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showError("Download failed: \(error.localizedDescription)")
            log(action: "Download Backup", detail: backupId, success: false, error: error.localizedDescription)
        }

        isDownloadingBackup = false
    }

    public func importSQL(_ sqlContent: String) async {
        guard let serverId = serverId else { return }
        let content = sqlContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            GlobalToastManager.shared.showError("SQL content is empty")
            return
        }

        let progressId = GlobalToastManager.shared.showProgress("Importing SQL...")

        do {
            _ = try await DatabaseBackupService.shared.importSQL(
                database: database.name,
                sqlContent: content,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showSuccess("SQL imported successfully")
            log(action: "Import SQL", detail: "\(content.count) characters into '\(database.name)'", success: true)
            showImportSQL = false
            await loadTables()
        } catch {
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showError("Import failed: \(error.localizedDescription)")
            log(action: "Import SQL", detail: "Into '\(database.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func confirmDeleteBackup(_ backupId: String) {
        activeAlert = .confirmDeleteBackup(backupId)
    }

    // MARK: - Advanced Operations

    /// Duplicate a row by primary key
    public func duplicateRow(at index: Int) async {
        guard let pk = primaryKeyValues(forRowAt: index), let table = selectedTable else {
            GlobalToastManager.shared.showError("Cannot determine primary key for this row")
            return
        }
        guard let serverId = serverId else { return }

        guard let pkData = try? JSONSerialization.data(withJSONObject: pk),
              let pkJSON = String(data: pkData, encoding: .utf8) else {
            GlobalToastManager.shared.showError("Failed to encode primary key")
            return
        }
        let cmd = DatabasesBridge.shared.duplicateRowCmd(
            engine: database.type.rawValue,
            database: database.name,
            table: table.name,
            primaryKeyJSON: pkJSON
        )
        guard !cmd.isEmpty else {
            GlobalToastManager.shared.showError("Duplicate row not supported")
            return
        }
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            GlobalToastManager.shared.showError("Duplicate failed: \(result)")
            log(action: "Duplicate Row", detail: "Table '\(table.name)'", success: false, error: result)
        } else {
            GlobalToastManager.shared.showSuccess("Row duplicated")
            log(action: "Duplicate Row", detail: "Table '\(table.name)'", success: true)
            await loadTableData()
            await loadTables()
        }
    }

    /// Drop an index by name
    public func dropIndex(_ indexName: String) async {
        guard let table = selectedTable, let serverId = serverId else { return }

        let cmd = DatabasesBridge.shared.dropIndexCmd(
            engine: database.type.rawValue,
            database: database.name,
            table: table.name,
            indexName: indexName
        )
        guard !cmd.isEmpty else {
            GlobalToastManager.shared.showError("Drop index not supported")
            return
        }

        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            GlobalToastManager.shared.showError("Drop index failed: \(result)")
            log(action: "Drop Index", detail: "Index '\(indexName)'", success: false, error: result)
        } else {
            GlobalToastManager.shared.showSuccess("Index '\(indexName)' dropped")
            log(action: "Drop Index", detail: "Index '\(indexName)' from '\(table.name)'", success: true)
            await loadTableStructure()
        }
    }

    /// Rename a table
    public func renameTable(from oldName: String, to newName: String) async {
        guard let serverId = serverId else { return }

        let cmd = DatabasesBridge.shared.renameTableCmd(
            engine: database.type.rawValue,
            database: database.name,
            oldName: oldName,
            newName: newName
        )
        guard !cmd.isEmpty else {
            GlobalToastManager.shared.showError("Rename table not supported")
            return
        }

        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            GlobalToastManager.shared.showError("Rename failed: \(result)")
            log(action: "Rename Table", detail: "'\(oldName)' → '\(newName)'", success: false, error: result)
        } else {
            GlobalToastManager.shared.showSuccess("Table renamed to '\(newName)'")
            log(action: "Rename Table", detail: "'\(oldName)' → '\(newName)'", success: true)
            if selectedTable?.name == oldName {
                deselectTable()
            }
            await loadTables()
        }
    }

    /// Restore from a backup
    public func restoreBackup(_ backupId: String) async {
        guard let serverId = serverId else { return }

        let progressId = GlobalToastManager.shared.showProgress("Restoring backup...")
        do {
            try await DatabaseBackupService.shared.restoreBackup(
                backupPath: backupId,
                database: database.name,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showSuccess("Backup restored successfully")
            log(action: "Restore Backup", detail: backupId, success: true)
            await loadTables()
        } catch {
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showError("Restore failed: \(error.localizedDescription)")
            log(action: "Restore Backup", detail: backupId, success: false, error: error.localizedDescription)
        }
    }
}
