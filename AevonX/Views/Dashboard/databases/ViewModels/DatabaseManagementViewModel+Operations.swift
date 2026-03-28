//
//  DatabaseManagementViewModel+Operations.swift
//  AevonX
//
//  Filtering, database operations, user management,
//  and statistics for database management VM.
//

import Foundation
import SwiftUI
import AevonXCoreBridge

extension DatabaseManagementViewModel {
    // MARK: - Filtering

    /// Filters databases based on selected type and search text
    func filterDatabases() {
        var filtered = allDatabases

        // Filter by type
        if let selectedType = selectedDatabaseType {
            filtered = filtered.filter { $0.type == selectedType }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredDatabases = filtered
    }

    /// Updates selected type based on tab index
    func updateSelectedTypeFromTab() {
        if activeTabIndex == 0 {
            selectedDatabaseType = nil
        } else {
            let types = DatabaseType.allCases.filter { $0 != .unknown }
            if activeTabIndex - 1 < types.count {
                selectedDatabaseType = types[activeTabIndex - 1]
            }
        }
    }

    // MARK: - Database Operations (Via Core Layer)

    /// Creates a new database via Core layer
    public func createDatabase(
        name: String,
        type: DatabaseType,
        characterSet: String? = nil,
        collation: String? = nil
    ) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseManagementService.shared.createDatabase(
            name: name,
            type: type.rawValue,
            characterSet: characterSet,
            collation: collation,
            serverId: serverId
        )

        // Reload data (force refresh to bypass cache)
        await loadData(forceRefresh: true)
    }

    /// Deletes a database via Core layer
    public func deleteDatabase(name: String, type: DatabaseType) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseManagementService.shared.deleteDatabase(name: name, type: type.rawValue, serverId: serverId)

        // Reload data (force refresh to bypass cache)
        await loadData(forceRefresh: true)
    }

    /// Starts a database service via Core layer
    public func startService(type: DatabaseType) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseEngineService.shared.startService(type: type, serverId: serverId)
        await loadData()
    }

    /// Stops a database service via Core layer
    public func stopService(type: DatabaseType) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseEngineService.shared.stopService(type: type, serverId: serverId)
        await loadData()
    }

    /// Restarts a database service via Core layer
    public func restartService(type: DatabaseType) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseEngineService.shared.restartService(type: type, serverId: serverId)
        await loadData()
    }

    // MARK: - User Management (Via Core Layer)

    /// Creates a new database user via Core layer
    public func createUser(
        username: String,
        password: String,
        host: String = "%",
        databaseType: DatabaseType
    ) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseUserService.shared.createUser(
            username: username,
            password: password,
            host: host,
            type: databaseType,
            serverId: serverId
        )

        // Reload users
        await loadDatabaseUsers(serverId: serverId)
    }

    /// Grants privileges to a user via Core layer
    public func grantPrivileges(
        username: String,
        host: String,
        database: String,
        privileges: [String],
        databaseType: DatabaseType
    ) async throws {
        guard let serverId = serverId else {
            throw DatabaseOperationError.serverNotConfigured
        }

        try await DatabaseUserService.shared.grantPrivileges(
            username: username,
            host: host,
            database: database,
            privileges: privileges,
            type: databaseType,
            serverId: serverId
        )

        // Reload users
        await loadDatabaseUsers(serverId: serverId)
    }

    /// Checks if a database type is installed
    public func isEngineInstalled(_ type: DatabaseType) -> Bool {
        return installationStates.first { $0.type == type }?.isInstalled ?? false
    }

    /// Gets installation state for a database type
    public func installationState(for type: DatabaseType) -> DatabaseInstallationState? {
        return installationStates.first { $0.type == type }
    }

    // MARK: - Statistics

    /// Total number of databases
    public var totalDatabaseCount: Int {
        allDatabases.count
    }

    /// Total size of all databases
    public var totalDatabaseSize: Double {
        allDatabases.reduce(0) { $0 + $1.size }
    }

    /// Formatted total size (size is in bytes from Go adapters)
    public var formattedTotalSize: String {
        let total = Int64(totalDatabaseSize)
        return total > 0 ? AXFormatter.formatBytes(total) : "0 B"
    }

    /// Total number of users
    public var totalUserCount: Int {
        databaseUsers.count
    }

    /// Number of installed database types
    public var installedDatabaseTypesCount: Int {
        installationStates.filter { $0.isInstalled }.count
    }

    /// Available database types for tabs — ONLY installed engines
    public var availableDatabaseTypes: [DatabaseType] {
        installationStates.filter { $0.isInstalled }.map { $0.type }.sorted { $0.displayName < $1.displayName }
    }
}

// MARK: - Database Operation Errors

/// Errors specific to database operations from UI layer
public enum DatabaseOperationError: LocalizedError {
    case serverNotConfigured
    case notConnected
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .serverNotConfigured:
            return L10n.Error.serverNotConfigured
        case .notConnected:
            return L10n.Error.notConnected
        case .operationFailed(let reason):
            return L10n.Database.operationFailed(reason)
        }
    }
}
