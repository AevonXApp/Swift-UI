//
//  DatabaseRowService.swift
//  AevonX
//
//  Bridge-backed service for row-level operations.
//  Replaces AevonXCore DatabaseRowService using DatabasesBridge + SSHBridge.
//

import Foundation
import AevonXCoreBridge

/// Service for row CRUD, browsing, searching, and query execution.
public actor DatabaseRowService {

    public static let shared = DatabaseRowService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func browseRows(database: String, table: String, type: DatabaseType, serverId: String, page: Int = 1, pageSize: Int = 50, orderBy: String = "", ascending: Bool = true) async throws -> BridgeQueryResult {
        let cmd = bridge.browseRowsCmd(engine: type.rawValue, database: database, table: table, page: page, pageSize: pageSize, orderBy: orderBy, ascending: ascending)
        print("[DatabaseRowService] browseRows cmd: \(cmd)")
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        print("[DatabaseRowService] browseRows raw output (\(output.count) chars): '\(output.prefix(500))'")
        return parseQueryResult(output, isSelect: true)
    }

    public func executeQuery(database: String, query: String, type: DatabaseType, serverId: String) async throws -> BridgeQueryResult {
        let cmd = bridge.executeQueryCmd(engine: type.rawValue, database: database, query: query)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        let isSelect = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix("SELECT")
        return parseQueryResult(output, isSelect: isSelect)
    }

    public func insertRow(database: String, table: String, values: [String: String], type: DatabaseType, serverId: String) async throws {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: values),
              let valuesJSON = String(data: jsonData, encoding: .utf8) else {
            throw DatabaseServiceError.invalidResponse("Failed to encode values")
        }
        let cmd = bridge.insertRowCmd(engine: type.rawValue, database: database, table: table, valuesJSON: valuesJSON)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Insert failed: \(result)")
        }
    }

    public func updateRow(database: String, table: String, primaryKey: [String: String], values: [String: String], type: DatabaseType, serverId: String) async throws {
        guard let pkData = try? JSONSerialization.data(withJSONObject: primaryKey),
              let pkJSON = String(data: pkData, encoding: .utf8),
              let valData = try? JSONSerialization.data(withJSONObject: values),
              let valJSON = String(data: valData, encoding: .utf8) else {
            throw DatabaseServiceError.invalidResponse("Failed to encode data")
        }
        let cmd = bridge.updateRowCmd(engine: type.rawValue, database: database, table: table, primaryKeyJSON: pkJSON, valuesJSON: valJSON)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Update failed: \(result)")
        }
    }

    public func deleteRow(database: String, table: String, primaryKey: [String: String], type: DatabaseType, serverId: String) async throws {
        guard let pkData = try? JSONSerialization.data(withJSONObject: primaryKey),
              let pkJSON = String(data: pkData, encoding: .utf8) else {
            throw DatabaseServiceError.invalidResponse("Failed to encode primary key")
        }
        let cmd = bridge.deleteRowCmd(engine: type.rawValue, database: database, table: table, primaryKeyJSON: pkJSON)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Delete failed: \(result)")
        }
    }

    public func deleteRows(database: String, table: String, primaryKeys: [[String: String]], type: DatabaseType, serverId: String) async throws {
        guard let pksData = try? JSONSerialization.data(withJSONObject: primaryKeys),
              let pksJSON = String(data: pksData, encoding: .utf8) else {
            throw DatabaseServiceError.invalidResponse("Failed to encode primary keys")
        }
        let cmd = bridge.deleteRowsCmd(engine: type.rawValue, database: database, table: table, primaryKeysJSON: pksJSON)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Delete rows failed: \(result)")
        }
    }

    public func searchRows(database: String, table: String, search: String, type: DatabaseType, serverId: String, page: Int = 1, pageSize: Int = 50, orderBy: String = "", ascending: Bool = true) async throws -> BridgeQueryResult {
        let cmd = bridge.searchRowsCmd(engine: type.rawValue, database: database, table: table, search: search, page: page, pageSize: pageSize, orderBy: orderBy, ascending: ascending)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parseQueryResult(output, isSelect: true)
    }

    public func importSQL(database: String, sqlContent: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.importSQLCmd(engine: type.rawValue, database: database, sqlContent: sqlContent)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Import failed: \(result)")
        }
    }

    // MARK: - Parsing

    private func parseQueryResult(_ output: String, isSelect: Bool) -> BridgeQueryResult {
        let lines = output.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !lines.isEmpty else {
            return BridgeQueryResult(isSelect: isSelect)
        }

        if isSelect {
            // First line = column headers, remaining lines = data rows
            let columns = lines[0].components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
            var rows: [[String]] = []
            for line in lines.dropFirst() {
                // Skip PostgreSQL separator lines (e.g. "----+----+----")
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.allSatisfy({ $0 == "-" || $0 == "+" || $0 == "|" }) { continue }
                // Skip PostgreSQL footer lines (e.g. "(3 rows)")
                if trimmed.hasPrefix("(") && trimmed.hasSuffix("rows)") { continue }
                if trimmed.hasPrefix("(") && trimmed.hasSuffix("row)") { continue }
                
                let cols = line.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
                // For PostgreSQL pipe-separated output, try splitting by |
                if cols.count == 1 && line.contains("|") {
                    let pipeCols = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                    rows.append(pipeCols)
                } else {
                    rows.append(cols)
                }
            }
            return BridgeQueryResult(columns: columns, rows: rows, isSelect: true)
        } else {
            return BridgeQueryResult(affectedRows: Int64(lines.count), isSelect: false)
        }
    }
}
