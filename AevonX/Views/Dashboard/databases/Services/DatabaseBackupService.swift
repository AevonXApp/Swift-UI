//
//  DatabaseBackupService.swift
//  AevonX
//
//  Bridge-backed service for database backup operations.
//

import Foundation
import AevonXCoreBridge

/// Service for creating, listing, restoring, and deleting database backups.
public actor DatabaseBackupService {

    public static let shared = DatabaseBackupService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func createBackup(database: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.createBackupCmd(engine: type.rawValue, database: database)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if !result.contains("OK") && result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Backup creation failed: \(result)")
        }
    }

    public func listBackups(type: DatabaseType, serverId: String) async throws -> [BridgeBackupInfo] {
        let cmd = bridge.listBackupsCmd(engine: type.rawValue)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parseBackups(output)
    }

    public func restoreBackup(backupPath: String, database: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.restoreBackupCmd(engine: type.rawValue, backupPath: backupPath, database: database)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Restore failed: \(result)")
        }
    }

    public func deleteBackup(backupPath: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.deleteBackupCmd(engine: type.rawValue, backupPath: backupPath)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if !result.contains("OK") {
            throw DatabaseServiceError.operationFailed("Delete backup failed: \(result)")
        }
    }

    private func parseBackups(_ output: String) -> [BridgeBackupInfo] {
        let lines = output.components(separatedBy: .newlines)
        var backups: [BridgeBackupInfo] = []
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 2 {
                backups.append(BridgeBackupInfo(path: parts[1], size: parts[0]))
            }
        }
        return backups
    }

    /// Download backup content from server
    public func downloadBackup(backupPath: String, type: DatabaseType, serverId: String) async throws -> Data {
        guard ShellSanitizer.isValidPath(backupPath) else {
            throw DatabaseServiceError.operationFailed("Invalid backup path")
        }
        let cmd = "cat \(ShellSanitizer.escapePath(backupPath))"
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        guard let data = result.data(using: .utf8), !data.isEmpty else {
            throw DatabaseServiceError.operationFailed("Failed to download backup")
        }
        return data
    }

    /// Import SQL content into a database
    public func importSQL(database: String, sqlContent: String, type: DatabaseType, serverId: String) async throws {
        let safeDB = ShellSanitizer.sanitizeIdentifier(database)
        guard !safeDB.isEmpty else {
            throw DatabaseServiceError.operationFailed("Invalid database name")
        }
        let safeSQL = ShellSanitizer.quote(sqlContent)
        let cmd: String
        switch type {
        case .mysql, .mariadb:
            cmd = "echo \(safeSQL) | mysql \(ShellSanitizer.quote(safeDB))"
        case .postgresql, .cockroachdb:
            cmd = "echo \(safeSQL) | psql \(ShellSanitizer.quote(safeDB))"
        default:
            throw DatabaseServiceError.operationFailed("SQL import not supported for \(type.rawValue)")
        }
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("SQL import failed: \(result)")
        }
    }
}
