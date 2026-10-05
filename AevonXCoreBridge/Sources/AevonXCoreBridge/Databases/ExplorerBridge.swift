//
//  ExplorerBridge.swift
//  AevonXCoreBridge
//
//  Fast, on-demand data explorer for MySQL, MariaDB and PostgreSQL.
//
//  The Go Core builds the commands (names-first listings, keyset paging with
//  server-side cell previews, type-aware search, NULL-correct writes); this
//  file wraps those exports and decodes their output.
//
//  Output format: one record per line, tab-separated, starting with a marker
//  ("~R" row, "~C" count, …). Values are hex-encoded UTF-8, "~" is NULL and
//  "~B<n>" is a binary value of n bytes. Any other line is either noise
//  (client warnings) or a server error.
//

import Foundation
import AevonXCoreLib

// MARK: - Request

/// The JSON payload every request-based explorer command accepts.
public struct ExplorerRequest: Encodable, Sendable {

    public struct Column: Encodable, Sendable {
        public var name: String
        public var type: String
        public var isPrimaryKey: Bool

        public init(name: String, type: String, isPrimaryKey: Bool) {
            self.name = name
            self.type = type
            self.isPrimaryKey = isPrimaryKey
        }

        enum CodingKeys: String, CodingKey {
            case name, type
            case isPrimaryKey = "is_primary_key"
        }
    }

    public enum SearchMode: String, Encodable, Sendable, CaseIterable {
        case contains, exact, prefix
    }

    public var database: String
    public var table: String
    public var columns: [Column]
    public var limit: Int = 50
    public var offset: Int = 0
    public var orderBy: String = ""
    public var descending: Bool = false
    public var afterKey: String?
    public var search: String = ""
    public var searchColumn: String = ""
    public var searchMode: SearchMode = .contains
    public var previewChars: Int = 0
    public var key: [String: String] = [:]
    public var keys: [[String: String]] = []
    /// Row values for insert/update; `nil` is written as SQL NULL.
    public var values: [String: String?] = [:]

    public init(database: String, table: String, columns: [Column] = []) {
        self.database = database
        self.table = table
        self.columns = columns
    }

    enum CodingKeys: String, CodingKey {
        case database, table, columns, limit, offset, descending, search, key, keys, values
        case orderBy = "order_by"
        case afterKey = "after_key"
        case searchColumn = "search_column"
        case searchMode = "search_mode"
        case previewChars = "preview_chars"
    }

    func json() -> String {
        guard let data = try? JSONEncoder().encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - Errors

public enum ExplorerError: LocalizedError, Sendable {
    /// The server (or its database client) reported an error.
    case server(String)
    /// The Go Core refused to build the command (invalid request).
    case invalidRequest
    /// The command ran but produced no recognizable output.
    case noData

    public var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .invalidRequest: return "The request could not be built for this table."
        case .noData: return "The server returned no data."
        }
    }
}

// MARK: - Bridge

/// Builds explorer commands via the Go Core.
public final class ExplorerBridge: @unchecked Sendable {

    public static let shared = ExplorerBridge()
    private init() {}

    /// Whether the engine has explorer support (MySQL, MariaDB, PostgreSQL).
    public func supports(engine: String) -> Bool {
        let cStr = withCArgs { c in DBExplorerSupports(c.str(engine)) }
        defer { if let cStr { CoreFreeString(cStr) } }
        guard let cStr,
              let data = String(cString: cStr).data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = resp["data"] as? [String: Any] else { return false }
        return inner["supported"] as? Bool ?? false
    }

    public func listDatabasesCmd(engine: String) -> String {
        withCArgs { c in command(DBExplorerListDatabasesCmd(c.str(engine))) }
    }

    public func databaseStatsCmd(engine: String) -> String {
        withCArgs { c in command(DBExplorerDatabaseStatsCmd(c.str(engine))) }
    }

    public func listTablesCmd(engine: String, database: String) -> String {
        withCArgs { c in command(DBExplorerListTablesCmd(c.str(engine), c.str(database))) }
    }

    public func tableStatsCmd(engine: String, database: String) -> String {
        withCArgs { c in command(DBExplorerTableStatsCmd(c.str(engine), c.str(database))) }
    }

    public func describeCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in command(DBExplorerDescribeCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func browseCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerBrowseCmd(c.str(engine), c.str(request.json()))) }
    }

    public func countCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerCountCmd(c.str(engine), c.str(request.json()))) }
    }

    public func fetchRowCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerFetchRowCmd(c.str(engine), c.str(request.json()))) }
    }

    public func fetchRowsCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerFetchRowsCmd(c.str(engine), c.str(request.json()))) }
    }

    public func updateRowCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerUpdateRowCmd(c.str(engine), c.str(request.json()))) }
    }

    public func insertRowCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerInsertRowCmd(c.str(engine), c.str(request.json()))) }
    }

    public func deleteRowsCmd(engine: String, request: ExplorerRequest) -> String {
        withCArgs { c in command(DBExplorerDeleteRowsCmd(c.str(engine), c.str(request.json()))) }
    }

    private func command(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr else { return "" }
        defer { CoreFreeString(cStr) }
        guard let data = String(cString: cStr).data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              resp["success"] as? Bool == true,
              let inner = resp["data"] as? [String: Any],
              let value = inner["command"] as? String else { return "" }
        return value
    }
}

// MARK: - Output Decoding

/// Decodes explorer command output.
public enum ExplorerOutput {

    /// One table name from a names-only listing.
    public struct TableName: Sendable {
        public let name: String
        public let isView: Bool
    }

    /// Size/table-count statistics for one database.
    public struct DatabaseStats: Sendable {
        public let name: String
        public let sizeBytes: Int64
        /// -1 when the engine cannot report it cheaply (PostgreSQL).
        public let tables: Int
    }

    // MARK: Records

    /// Marker-prefixed records plus any server error lines in the output.
    static func records(_ output: String, marker: String) -> (records: [[Substring]], errors: [String]) {
        var rows: [[Substring]] = []
        var errors: [String] = []
        let prefix = marker + "\t"
        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.hasSuffix("\r") ? rawLine.dropLast() : rawLine
            if line.hasPrefix(prefix) {
                rows.append(Array(line.split(separator: "\t", omittingEmptySubsequences: false).dropFirst()))
            } else if isErrorLine(line) {
                errors.append(String(line))
            }
        }
        return (rows, errors)
    }

    static func isErrorLine(_ line: Substring) -> Bool {
        line.hasPrefix("ERROR") || line.contains("ERROR:") || line.contains("FATAL:")
            || line.hasPrefix("psql: error") || line.hasPrefix("sudo:")
            || line.contains("command not found") || line.contains("Access denied")
    }

    /// Throws the server error when there are no records but error lines.
    static func requireRecords(_ output: String, marker: String) throws -> [[Substring]] {
        let found = Self.records(output, marker: marker)
        if found.records.isEmpty, !found.errors.isEmpty {
            throw ExplorerError.server(found.errors.joined(separator: "\n"))
        }
        return found.records
    }

    // MARK: Values

    enum Cell {
        case null
        case binary(Int64)
        case text(String)
    }

    static func cell(_ field: Substring) -> Cell {
        if field == "~" { return .null }
        if field.hasPrefix("~B") { return .binary(Int64(field.dropFirst(2)) ?? 0) }
        return .text(decodeHex(field))
    }

    static func decodeHex(_ field: Substring) -> String {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(field.utf8.count / 2)
        var high: UInt8?
        for c in field.utf8 {
            let v: UInt8
            switch c {
            case 48...57: v = c - 48        // 0-9
            case 65...70: v = c - 55        // A-F
            case 97...102: v = c - 87       // a-f
            default: continue
            }
            if let h = high {
                bytes.append(h << 4 | v)
                high = nil
            } else {
                high = v
            }
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    static func text(_ field: Substring) -> String {
        if case .text(let s) = cell(field) { return s }
        return ""
    }

    // MARK: Results

    /// Decodes a page of rows. `previewChars` > 0 marks cells longer than that
    /// as truncated previews; `limit` trims the look-ahead row into `hasMore`.
    public static func page(_ output: String, columns: [String], previewChars: Int, limit: Int?) throws -> BridgeQueryResult {
        let records = try requireRecords(output, marker: "~R")
        var rows: [[String]] = []
        var flags: [[UInt8]] = []
        rows.reserveCapacity(records.count)
        flags.reserveCapacity(records.count)

        for record in records {
            var row: [String] = []
            row.reserveCapacity(columns.count)
            var rowFlags = [UInt8](repeating: 0, count: columns.count)
            for index in 0..<columns.count {
                let field: Substring = index < record.count ? record[index] : "~"
                switch cell(field) {
                case .null:
                    row.append("NULL")
                    rowFlags[index] = BridgeQueryResult.cellNull
                case .binary(let length):
                    row.append(String(length))
                    rowFlags[index] = BridgeQueryResult.cellBinary
                case .text(let value):
                    // The server sends previewChars + 1 characters (code points)
                    // when a value is longer than the preview.
                    if previewChars > 0, value.unicodeScalars.count > previewChars {
                        row.append(String(String.UnicodeScalarView(value.unicodeScalars.prefix(previewChars))))
                        rowFlags[index] = BridgeQueryResult.cellTruncated
                    } else {
                        row.append(value)
                    }
                }
            }
            rows.append(row)
            flags.append(rowFlags)
        }

        var hasMore = false
        if let limit, rows.count > limit {
            hasMore = true
            rows.removeLast(rows.count - limit)
            flags.removeLast(flags.count - limit)
        }
        return BridgeQueryResult(columns: columns, rows: rows, isSelect: true, cellFlags: flags, hasMore: hasMore)
    }

    /// Decodes a single complete row into column → value (nil = NULL,
    /// binary columns are omitted). Returns nil when the row no longer exists.
    public static func row(_ output: String, columns: [String]) throws -> [String: String?]? {
        guard let record = try requireRecords(output, marker: "~R").first else { return nil }
        var values: [String: String?] = [:]
        for (index, column) in columns.enumerated() {
            let field: Substring = index < record.count ? record[index] : "~"
            switch cell(field) {
            case .null: values[column] = .some(nil)
            case .binary: continue
            case .text(let value): values[column] = value
            }
        }
        return values
    }

    /// Decodes an exact row count.
    public static func count(_ output: String) throws -> Int64 {
        guard let record = try requireRecords(output, marker: "~C").first,
              let first = record.first, let value = Int64(first) else {
            throw ExplorerError.noData
        }
        return value
    }

    /// Decodes the affected-row count of a write.
    public static func affectedRows(_ output: String) throws -> Int64 {
        let found = Self.records(output, marker: "~O")
        if let first = found.records.first?.first, let value = Int64(first) {
            return value
        }
        throw ExplorerError.server(found.errors.isEmpty ? output.trimmingCharacters(in: .whitespacesAndNewlines) : found.errors.joined(separator: "\n"))
    }

    /// Decodes a names-only table listing.
    public static func tableNames(_ output: String) throws -> [TableName] {
        try requireRecords(output, marker: "~T").compactMap { record in
            guard let first = record.first else { return nil }
            let name = text(first)
            guard !name.isEmpty else { return nil }
            return TableName(name: name, isView: record.count > 1 && record[1] == "v")
        }
    }

    /// Decodes per-table statistics.
    public static func tableStats(_ output: String) throws -> [BridgeTableInfo] {
        try requireRecords(output, marker: "~S").compactMap { r in
            guard r.count >= 6 else { return nil }
            return BridgeTableInfo(
                name: text(r[0]),
                engine: String(r[1]),
                rowCount: Int64(r[2]) ?? 0,
                dataSize: Int64(r[3]) ?? 0,
                indexSize: Int64(r[4]) ?? 0,
                collation: String(r[5])
            )
        }
    }

    /// Decodes a column description.
    public static func columns(_ output: String) throws -> [BridgeColumnInfo] {
        try requireRecords(output, marker: "~K").compactMap { r in
            guard r.count >= 6 else { return nil }
            let extra = String(r[5])
            let defaultValue: String
            if case .text(let value) = cell(r[4]) { defaultValue = value } else { defaultValue = "NULL" }
            return BridgeColumnInfo(
                name: text(r[0]),
                type: text(r[1]),
                isNullable: r[2].uppercased() == "YES",
                defaultValue: defaultValue,
                isPrimaryKey: r[3] == "PRI",
                isAutoIncrement: extra.lowercased().contains("auto_increment"),
                extra: extra
            )
        }
    }

    /// Decodes a names-only database listing.
    public static func databaseNames(_ output: String) throws -> [String] {
        try requireRecords(output, marker: "~D").compactMap { r in
            guard let first = r.first else { return nil }
            let name = text(first)
            return name.isEmpty ? nil : name
        }
    }

    /// Decodes per-database statistics.
    public static func databaseStats(_ output: String) throws -> [DatabaseStats] {
        try requireRecords(output, marker: "~Z").compactMap { r in
            guard r.count >= 3 else { return nil }
            return DatabaseStats(name: text(r[0]), sizeBytes: Int64(r[1]) ?? 0, tables: Int(r[2]) ?? 0)
        }
    }
}
