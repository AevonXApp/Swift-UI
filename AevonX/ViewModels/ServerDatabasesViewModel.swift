//
//  ServerDatabasesViewModel.swift
//  AevonX
//
//  Manages database discovery, listing, and operations.
//  Extracted from ServerConnectionViewModel for single-responsibility.
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Server Databases ViewModel

/// Manages database listing, discovery and operations for a connected server.
/// Uses the existing DatabaseInfo model from DatabaseInfo.swift.
@MainActor
public class ServerDatabasesViewModel: ObservableObject {
    
    /// View modes for the database list
    public enum DatabaseViewMode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case table = "Table"
        public var id: String { rawValue }
    }
    
    // MARK: - Published Properties
    
    /// Array of databases on the server
    @Published private(set) var databases: [DatabaseInfo] = []
    
    /// Current view mode for databases
    @Published var viewMode: DatabaseViewMode = .grid
    
    /// Whether databases are being loaded
    @Published private(set) var isLoading: Bool = false
    
    /// Error from database loading, if any
    @Published private(set) var error: String?
    
    // MARK: - Private Properties
    
    private let serverId: String
    private let sshService: any AevonXCoreBridge.SSHServiceProtocol
    
    // MARK: - Initialization
    
    init(serverId: String, sshService: any AevonXCoreBridge.SSHServiceProtocol = SSHBridge.shared) {
        self.serverId = serverId
        self.sshService = sshService
    }
    
    // MARK: - Database Loading
    
    /// Load all databases from the server.
    func loadDatabases() async {
        guard await sshService.isConnected(serverId: serverId) else { return }
        
        isLoading = true
        error = nil
        
        var loadedDatabases: [DatabaseInfo] = []
        
        // Try to fetch MySQL databases
        if let mysqlResult = try? await sshService.execute(
            CommandTemplate.databases(.listMySQL).build(), serverId: serverId
        ) {
            let mysqlDBs = parseMySQLDatabases(mysqlResult.stdout)
            loadedDatabases.append(contentsOf: mysqlDBs)
        }
        
        // Try to fetch PostgreSQL databases
        if let pgResult = try? await sshService.execute(
            CommandTemplate.databases(.listPostgreSQL).build(), serverId: serverId
        ) {
            let pgDBs = parsePostgreSQLDatabases(pgResult.stdout)
            loadedDatabases.append(contentsOf: pgDBs)
        }
        
        // Try to fetch Redis info
        if let redisResult = try? await sshService.execute(
            CommandTemplate.databases(.listRedis).build(), serverId: serverId
        ) {
            if let redisDB = parseRedisInfo(redisResult.stdout) {
                loadedDatabases.append(redisDB)
            }
        }
        
        databases = loadedDatabases
        isLoading = false
    }
    
    /// Reset database state.
    func reset() {
        databases = []
        error = nil
        isLoading = false
    }
    
    // MARK: - Parsing Helpers (delegated to InventoryBridge / Go)
    //
    // The system-database filter list, the column conventions of `psql -l`,
    // and the Redis INFO format all live in `core-go/pkg/remote/databases/parsing`.
    // Centralising in Go means future Windows/Linux clients reuse the same
    // logic — and the open-source UI doesn't need to know which schemas to hide.

    private func parseMySQLDatabases(_ output: String) -> [DatabaseInfo] {
        InventoryBridge.shared.parseMySQLDatabases(output).map(toLocal(.mysql))
    }

    private func parsePostgreSQLDatabases(_ output: String) -> [DatabaseInfo] {
        InventoryBridge.shared.parsePostgreSQLDatabases(output).map(toLocal(.postgresql))
    }

    private func parseRedisInfo(_ output: String) -> DatabaseInfo? {
        guard let core = InventoryBridge.shared.parseRedisInfo(output) else { return nil }
        return DatabaseInfo(
            name: core.name,
            type: .redis,
            version: core.version,
            status: .online,
            size: core.size ?? 0
        )
    }

    private func toLocal(_ type: DatabaseType) -> (DatabaseInfoCore) -> DatabaseInfo {
        return { core in
            DatabaseInfo(name: core.name, type: type, status: .online)
        }
    }
}
