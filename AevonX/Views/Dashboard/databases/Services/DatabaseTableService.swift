//
//  DatabaseTableService.swift
//  AevonX
//
//  Bridge-backed service for table management operations.
//  Replaces AevonXCore DatabaseTableService using DatabasesBridge + SSHBridge.
//

import Foundation
import AevonXCoreBridge

/// Service for table-level operations: list, describe, create, drop, optimize.
public actor DatabaseTableService {

    public static let shared = DatabaseTableService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func listTables(database: String, type: DatabaseType, serverId: String) async throws -> [BridgeTableInfo] {
        let cmd = bridge.listTablesCmd(engine: type.rawValue, database: database)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parseTableList(output)
    }

    public func describeTable(database: String, table: String, type: DatabaseType, serverId: String) async throws -> [BridgeColumnInfo] {
        let cmd = bridge.describeTableCmd(engine: type.rawValue, database: database, table: table)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parseColumns(output)
    }

    public func getTableIndexes(database: String, table: String, type: DatabaseType, serverId: String) async throws -> String {
        let cmd = bridge.getTableIndexesCmd(engine: type.rawValue, database: database, table: table)
        return await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    public func createTable(database: String, table: String, columns: [BridgeColumnDefinition], type: DatabaseType, serverId: String) async throws {
        let columnsJSON = BridgeColumnDefinition.encodeColumns(columns)
        let cmd = bridge.createTableCmd(engine: type.rawValue, database: database, table: table, columnsJSON: columnsJSON)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Create table failed: \(result)")
        }
    }

    public func dropTable(database: String, table: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.dropTableCmd(engine: type.rawValue, database: database, table: table)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Drop table failed: \(result)")
        }
    }

    public func truncateTable(database: String, table: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.truncateTableCmd(engine: type.rawValue, database: database, table: table)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Truncate table failed: \(result)")
        }
    }

    public func optimizeTable(database: String, table: String, type: DatabaseType, serverId: String) async throws -> String {
        let cmd = bridge.optimizeTableCmd(engine: type.rawValue, database: database, table: table)
        return await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    public func analyzeTable(database: String, table: String, type: DatabaseType, serverId: String) async throws -> String {
        let cmd = bridge.analyzeTableCmd(engine: type.rawValue, database: database, table: table)
        return await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    public func addColumn(database: String, table: String, name: String, type colType: String, length: String = "", nullable: Bool = true, primaryKey: Bool = false, autoIncrement: Bool = false, unique: Bool = false, defaultValue: String = "", afterColumn: String = "", engineType: String, serverId: String) async throws {
        let cmd = bridge.addColumnCmd(engine: engineType, database: database, table: table, name: name, type: colType, length: length, nullable: nullable, primaryKey: primaryKey, autoIncrement: autoIncrement, unique: unique, defaultValue: defaultValue, afterColumn: afterColumn)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Add column failed: \(result)")
        }
    }

    public func dropColumn(database: String, table: String, column: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.dropColumnCmd(engine: type.rawValue, database: database, table: table, column: column)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Drop column failed: \(result)")
        }
    }

    // MARK: - Parsing

    private func parseTableList(_ output: String) -> [BridgeTableInfo] {
        let lines = output.components(separatedBy: .newlines)
        var tables: [BridgeTableInfo] = []
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
            if !parts.isEmpty && !parts[0].isEmpty {
                tables.append(BridgeTableInfo(
                    name: parts[0],
                    engine: parts.count > 1 ? parts[1] : "",
                    rowCount: parts.count > 2 ? Int64(parts[2]) ?? 0 : 0,
                    dataSize: parts.count > 3 ? Int64(parts[3]) ?? 0 : 0,
                    indexSize: parts.count > 4 ? Int64(parts[4]) ?? 0 : 0,
                    collation: parts.count > 5 ? parts[5] : ""
                ))
            }
        }
        return tables
    }

    private func parseColumns(_ output: String) -> [BridgeColumnInfo] {
        let lines = output.components(separatedBy: .newlines)
        var columns: [BridgeColumnInfo] = []
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 {
                columns.append(BridgeColumnInfo(
                    name: parts[0],
                    type: parts[1],
                    isNullable: parts.count > 2 ? parts[2].uppercased() == "YES" : true,
                    defaultValue: parts.count > 4 ? parts[4] : "",
                    isPrimaryKey: parts.count > 3 ? parts[3].uppercased() == "PRI" : false,
                    isAutoIncrement: parts.count > 5 ? parts[5].lowercased().contains("auto_increment") : false,
                    extra: parts.count > 5 ? parts[5] : ""
                ))
            }
        }
        return columns
    }
}
