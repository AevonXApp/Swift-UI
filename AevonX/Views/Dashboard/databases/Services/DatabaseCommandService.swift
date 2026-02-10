//
//  DatabaseCommandService.swift
//  AevonX
//
//  DEPRECATED: This service is deprecated and will be removed in a future version.
//  Use CoreDatabaseService from AevonXCore instead.
//
//  This file is maintained for backwards compatibility only.
//  All methods now redirect to CoreDatabaseService in the Core layer.
//

import Foundation
import AevonXCore
import Combine

// MARK: - Database Command Service (DEPRECATED)

/// DEPRECATED: Use CoreDatabaseService from AevonXCore instead
///
/// This service was the original implementation that directly executed SSH commands
/// from the UI layer, which violated the architectural separation of concerns.
///
/// All functionality has been moved to CoreDatabaseService in AevonXCore.
/// This wrapper is maintained only for backwards compatibility.
@available(*, deprecated, message: "Use CoreDatabaseService from AevonXCore instead")
@MainActor
public final class DatabaseCommandService: ObservableObject {

    // MARK: - Singleton

    public static let shared = DatabaseCommandService()

    // MARK: - Published State

    @Published public var isExecuting = false
    @Published public var lastError: DatabaseCommandError?

    // MARK: - Initialization

    private init() {}

    // MARK: - Server Detection (Redirects to Core)

    /// Detects which databases are installed on the server
    /// DEPRECATED: Use DatabaseEngineService.shared.detectInstalledDatabases instead
    public func detectInstalledDatabases(serverId: String) async -> [DatabaseInstallationState] {
        let coreStates = await DatabaseEngineService.shared.detectInstalledDatabases(serverId: serverId)

        // Convert Core models to UI models
        return coreStates.map { coreState in
            DatabaseInstallationState(
                id: coreState.id,
                type: coreState.type,
                isInstalled: coreState.isInstalled,
                installedVersion: coreState.installedVersion,
                installPath: coreState.installPath,
                serviceStatus: ServiceStatus(rawValue: coreState.serviceStatus.rawValue) ?? .unknown,
                isRunning: coreState.isRunning,
                lastCheckedAt: coreState.lastCheckedAt
            )
        }
    }

    // MARK: - Service Management (Redirects to Core)

    public func startService(type: DatabaseType, serverId: String) async throws {
        try await DatabaseEngineService.shared.startService(type: type, serverId: serverId)
    }

    public func stopService(type: DatabaseType, serverId: String) async throws {
        try await DatabaseEngineService.shared.stopService(type: type, serverId: serverId)
    }

    public func restartService(type: DatabaseType, serverId: String) async throws {
        try await DatabaseEngineService.shared.restartService(type: type, serverId: serverId)
    }

    // MARK: - Database Listing (Redirects to Core)

    public func listDatabases(type: DatabaseType, serverId: String) async throws -> [DatabaseInfo] {
        let coreDatabases = try await DatabaseManagementService.shared.listDatabases(type: type, serverId: serverId)

        // Convert Core models to UI models
        return coreDatabases.map { coreDB in
            DatabaseInfo(
                id: coreDB.id,
                name: coreDB.name,
                type: coreDB.type,
                version: coreDB.version,
                status: DatabaseStatus(rawValue: coreDB.status.rawValue) ?? .unknown,
                size: coreDB.size,
                tables: coreDB.tables,
                connections: coreDB.connections,
                host: coreDB.host,
                port: coreDB.port
            )
        }
    }

    // MARK: - User Management (Redirects to Core)

    public func listMySQLUsers(serverId: String) async throws -> [DatabaseUserInfo] {
        // DatabaseUserService.shared.listUsers(type: .mysql, serverId: serverId)
        let coreUsers = try await DatabaseUserService.shared.listUsers(type: .mysql, serverId: serverId)

        return coreUsers.map { coreUser in
            DatabaseUserInfo(
                id: coreUser.id,
                username: coreUser.username,
                host: coreUser.host
            )
        }
    }

    public func createUser(
        username: String,
        password: String,
        host: String = "%",
        databaseType: DatabaseType,
        serverId: String
    ) async throws {
        try await DatabaseUserService.shared.createUser(
            username: username,
            password: password,
            host: host,
            databaseType: databaseType,
            serverId: serverId
        )
    }

    public func grantPrivileges(
        username: String,
        host: String,
        database: String,
        privileges: [String],
        databaseType: DatabaseType,
        serverId: String
    ) async throws {
        try await DatabaseUserService.shared.grantPrivileges(
            username: username,
            host: host,
            database: database,
            privileges: privileges,
            databaseType: databaseType,
            serverId: serverId
        )
    }

    // MARK: - Database Creation/Deletion (Redirects to Core)

    public func createDatabase(
        name: String,
        type: DatabaseType,
        characterSet: String? = nil,
        collation: String? = nil,
        serverId: String
    ) async throws {
        try await DatabaseManagementService.shared.createDatabase(
            name: name,
            type: type,
            characterSet: characterSet,
            collation: collation,
            serverId: serverId
        )
    }

    public func deleteDatabase(name: String, type: DatabaseType, serverId: String) async throws {
        try await DatabaseManagementService.shared.deleteDatabase(name: name, type: type, serverId: serverId)
    }

    // MARK: - Server Information (Redirects to Core)

    public func getServerOSInfo(serverId: String) async throws -> ServerOSInfo {
        return try await DatabaseResourceService.shared.getServerOSInfo(serverId: serverId)
    }

    public func getServerResources(serverId: String) async throws -> ServerResources {
        return try await DatabaseResourceService.shared.getServerResources(serverId: serverId)
    }

    // MARK: - Raw Command Execution (REMOVED)

    /// REMOVED: Direct command execution is no longer supported from UI layer
    /// This method is only kept for API compatibility but will throw an error
    @available(*, deprecated, message: "Direct command execution from UI is not allowed. Use specialized service methods instead.")
    func executeRawCommand(_ command: String, serverId: String) async throws -> SSHCommandResult {
        // Redirect to SSHService directly for raw execution (restricted use)
        return try await SSHService.shared.execute(command, serverId: serverId)
    }
}

// MARK: - Database Command Error

public enum DatabaseCommandError: LocalizedError {
    case serviceActionFailed(action: String, database: String, reason: String)
    case userCreationFailed(username: String, reason: String)
    case userDeletionFailed(username: String, reason: String)
    case privilegeGrantFailed(username: String, reason: String)
    case databaseCreationFailed(name: String, reason: String)
    case databaseDeletionFailed(name: String, reason: String)
    case unsupportedOperation(String)
    case notInstalled(databaseType: DatabaseType)
    case connectionFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .serviceActionFailed(let action, let database, let reason):
            return "Failed to \(action) \(database): \(reason)"
        case .userCreationFailed(let username, let reason):
            return "Failed to create user '\(username)': \(reason)"
        case .userDeletionFailed(let username, let reason):
            return "Failed to delete user '\(username)': \(reason)"
        case .privilegeGrantFailed(let username, let reason):
            return "Failed to grant privileges to '\(username)': \(reason)"
        case .databaseCreationFailed(let name, let reason):
            return "Failed to create database '\(name)': \(reason)"
        case .databaseDeletionFailed(let name, let reason):
            return "Failed to delete database '\(name)': \(reason)"
        case .unsupportedOperation(let message):
            return message
        case .notInstalled(let type):
            return "\(type.displayName) is not installed on this server"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        }
    }
}
