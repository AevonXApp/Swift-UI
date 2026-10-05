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
    private let explorer = ExplorerBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func browseRows(database: String, table: String, type: DatabaseType, serverId: String, page: Int = 1, pageSize: Int = 50, orderBy: String = "", ascending: Bool = true) async throws -> BridgeQueryResult {
        let cmd = bridge.browseRowsCmd(engine: type.rawValue, database: database, table: table, page: page, pageSize: pageSize, orderBy: orderBy, ascending: ascending)
        CoreLogger.shared.debug("browseRows: \(database).\(table) page=\(page)", module: "DatabaseRowService")
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        CoreLogger.shared.debug("browseRows response: \(output.count) chars", module: "DatabaseRowService")
        return try parseQueryResult(output, isSelect: true, type: type)
    }

    public func executeQuery(database: String, query: String, type: DatabaseType, serverId: String) async throws -> BridgeQueryResult {
        let cmd = bridge.executeQueryCmd(engine: type.rawValue, database: database, query: query)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return try parseQueryResult(output, isSelect: Self.returnsRows(query), type: type)
    }

    /// Statements whose output is a result set (not just a status).
    static func returnsRows(_ query: String) -> Bool {
        var text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasPrefix("(") { text.removeFirst() }
        let keyword = text.prefix { $0.isLetter }.uppercased()
        return ["SELECT", "SHOW", "DESCRIBE", "DESC", "EXPLAIN", "WITH", "VALUES", "TABLE", "PRAGMA", "CALL", "CHECK", "ANALYZE", "OPTIMIZE", "REPAIR"].contains(keyword)
    }

    // MARK: - Fast Explorer

    public enum ExplorerWriteOperation: Sendable {
        case insert, update, delete
    }

    /// One page of rows with previews and a has-more flag.
    public func explorerBrowse(_ request: ExplorerRequest, type: DatabaseType, serverId: String) async throws -> BridgeQueryResult {
        let cmd = explorer.browseCmd(engine: type.rawValue, request: request)
        guard !cmd.isEmpty else { throw ExplorerError.invalidRequest }
        let started = Date()
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        var result = try ExplorerOutput.page(output, columns: request.columns.map(\.name), previewChars: request.previewChars, limit: request.limit)
        result.executionTime = Date().timeIntervalSince(started)
        return result
    }

    /// Exact number of rows matching the request's search (or the table).
    public func explorerCount(_ request: ExplorerRequest, type: DatabaseType, serverId: String) async throws -> Int64 {
        let cmd = explorer.countCmd(engine: type.rawValue, request: request)
        guard !cmd.isEmpty else { throw ExplorerError.invalidRequest }
        return try ExplorerOutput.count(await ssh.executeAsync(serverID: serverId, command: cmd))
    }

    /// One complete row by key (nil when it no longer exists).
    public func explorerFetchRow(_ request: ExplorerRequest, type: DatabaseType, serverId: String) async throws -> [String: String?]? {
        let cmd = explorer.fetchRowCmd(engine: type.rawValue, request: request)
        guard !cmd.isEmpty else { throw ExplorerError.invalidRequest }
        return try ExplorerOutput.row(await ssh.executeAsync(serverID: serverId, command: cmd), columns: request.columns.map(\.name))
    }

    /// Complete rows (no previews) for `request.keys`, in one round trip.
    public func explorerFetchRows(_ request: ExplorerRequest, type: DatabaseType, serverId: String) async throws -> BridgeQueryResult {
        let cmd = explorer.fetchRowsCmd(engine: type.rawValue, request: request)
        guard !cmd.isEmpty else { throw ExplorerError.invalidRequest }
        return try ExplorerOutput.page(await ssh.executeAsync(serverID: serverId, command: cmd), columns: request.columns.map(\.name), previewChars: 0, limit: nil)
    }

    /// Insert/update/delete with real NULLs; returns the affected row count.
    @discardableResult
    public func explorerWrite(_ operation: ExplorerWriteOperation, _ request: ExplorerRequest, type: DatabaseType, serverId: String) async throws -> Int64 {
        let cmd: String
        switch operation {
        case .insert: cmd = explorer.insertRowCmd(engine: type.rawValue, request: request)
        case .update: cmd = explorer.updateRowCmd(engine: type.rawValue, request: request)
        case .delete: cmd = explorer.deleteRowsCmd(engine: type.rawValue, request: request)
        }
        guard !cmd.isEmpty else { throw ExplorerError.invalidRequest }
        return try ExplorerOutput.affectedRows(await ssh.executeAsync(serverID: serverId, command: cmd))
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
        return try parseQueryResult(output, isSelect: true, type: type)
    }

    public func importSQL(database: String, sqlContent: String, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.importSQLCmd(engine: type.rawValue, database: database, sqlContent: sqlContent)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Import failed: \(result)")
        }
    }

    // MARK: - Parsing

    /// Parses client output (MySQL batch / psql unaligned). Server errors are
    /// thrown instead of being shown as a result row.
    private func parseQueryResult(_ output: String, isSelect: Bool, type: DatabaseType) throws -> BridgeQueryResult {
        var lines = output.components(separatedBy: "\n").map { $0.hasSuffix("\r") ? String($0.dropLast()) : $0 }
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty { lines.removeLast() }

        if let errorLine = lines.first(where: Self.isServerError) {
            let message = lines.drop { $0 != errorLine }.joined(separator: "\n")
            throw DatabaseServiceError.operationFailed(message)
        }
        guard !lines.isEmpty else {
            return BridgeQueryResult(isSelect: isSelect)
        }

        // MySQL's batch mode escapes \n, \t, \\ and NUL inside values.
        let unescape = type == .mysql || type == .mariadb
        let split: (String) -> [String] = { line in
            let fields = line.components(separatedBy: "\t")
            return unescape ? fields.map(Self.unescapeMySQLBatch) : fields
        }

        if isSelect {
            // First line = column headers, remaining lines = data rows
            let columns = split(lines[0])
            var rows: [[String]] = []
            for line in lines.dropFirst() {
                // Skip PostgreSQL separator and footer lines ("----+----", "(3 rows)")
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty, trimmed.allSatisfy({ $0 == "-" || $0 == "+" || $0 == "|" }) { continue }
                if trimmed.hasPrefix("(") && (trimmed.hasSuffix("rows)") || trimmed.hasSuffix("row)")) { continue }

                let cols = split(line)
                // For PostgreSQL pipe-separated output, try splitting by |
                if cols.count == 1 && columns.count > 1 && line.contains("|") {
                    rows.append(line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) })
                } else {
                    rows.append(cols)
                }
            }
            return BridgeQueryResult(columns: columns, rows: rows, isSelect: true)
        } else {
            return BridgeQueryResult(affectedRows: Int64(lines.count), isSelect: false)
        }
    }

    /// Matches client error lines only, so data that merely starts with
    /// "ERROR" (log tables) is not mistaken for a failure.
    private static func isServerError(_ line: String) -> Bool {
        // MySQL/MariaDB: "ERROR 1064 (42000) at line 1: …"
        if line.hasPrefix("ERROR "), line.dropFirst(6).prefix(while: \.isNumber).count >= 4 { return true }
        // psql: "ERROR:  …", "psql:<stdin>:1: ERROR:  …", "psql: error: …"
        if line.hasPrefix("ERROR:  ") || line.hasPrefix("FATAL:  ") || line.hasPrefix("psql: error") { return true }
        return line.hasPrefix("psql:") && (line.contains(" ERROR:  ") || line.contains(" FATAL:  "))
    }

    private static func unescapeMySQLBatch(_ field: String) -> String {
        guard field.contains("\\") else { return field }
        var result = ""
        result.reserveCapacity(field.count)
        var escaping = false
        for character in field {
            if escaping {
                switch character {
                case "n": result.append("\n")
                case "t": result.append("\t")
                case "0": result.append("\0")
                case "\\": result.append("\\")
                default: result.append("\\"); result.append(character)
                }
                escaping = false
            } else if character == "\\" {
                escaping = true
            } else {
                result.append(character)
            }
        }
        if escaping { result.append("\\") }
        return result
    }
}
