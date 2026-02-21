//
//  ServerDatabasesViewModel.swift
//  AevonX
//
//  Manages database discovery, listing, and operations.
//  Extracted from ServerConnectionViewModel for single-responsibility.
//

import SwiftUI
import AevonXCore
import Combine

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
    private let sshService: any SSHServiceProtocol
    
    // MARK: - Initialization
    
    init(serverId: String, sshService: any SSHServiceProtocol = SSHService.shared) {
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
    
    // MARK: - Parsing Helpers
    
    private func parseMySQLDatabases(_ output: String) -> [DatabaseInfo] {
        var databases: [DatabaseInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  trimmed != "Database",
                  !trimmed.hasPrefix("+"),
                  !trimmed.hasPrefix("|") else { continue }
            
            let systemDBs = ["information_schema", "mysql", "performance_schema", "sys"]
            guard !systemDBs.contains(trimmed) else { continue }
            
            databases.append(DatabaseInfo(
                name: trimmed,
                type: .mysql,
                status: .online
            ))
        }
        
        return databases
    }
    
    private func parsePostgreSQLDatabases(_ output: String) -> [DatabaseInfo] {
        var databases: [DatabaseInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("Name"),
                  !trimmed.hasPrefix("-"),
                  !trimmed.hasPrefix("(") else { continue }
            
            let components = trimmed.components(separatedBy: "|")
            guard let name = components.first?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty,
                  name != "postgres",
                  name != "template0",
                  name != "template1" else { continue }
            
            databases.append(DatabaseInfo(
                name: name,
                type: .postgresql,
                status: .online
            ))
        }
        
        return databases
    }
    
    private func parseRedisInfo(_ output: String) -> DatabaseInfo? {
        guard output.contains("redis_version") else { return nil }
        
        var version: String?
        var usedMemory: Double = 0
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("redis_version:") {
                version = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
            }
            if line.hasPrefix("used_memory:") {
                if let bytesStr = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces),
                   let bytes = Double(bytesStr) {
                    usedMemory = bytes / (1024 * 1024)
                }
            }
        }
        
        return DatabaseInfo(
            name: "Redis Server",
            type: .redis,
            version: version,
            status: .online,
            size: usedMemory
        )
    }
}
