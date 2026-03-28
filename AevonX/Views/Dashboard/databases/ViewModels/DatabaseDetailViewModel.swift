//
//  DatabaseDetailViewModel.swift
//  AevonX
//
//  ViewModel for the Database Detail page
//  Handles tables, structure, data browsing, queries, and backups
//

import Foundation
import SwiftUI
import AevonXCoreBridge
import Combine
import AppKit
import UniformTypeIdentifiers

// MARK: - Section Navigation

public enum DatabaseDetailSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case tables = "Tables"
    case queryConsole = "SQL Console"
    case backup = "Backup"
    case activityLog = "Activity Log"
    case importSQL = "Import SQL"

    public var id: String { rawValue }

    var iconName: String {
        switch self {
        case .overview: return "chart.bar"
        case .tables: return "tablecells"
        case .queryConsole: return "terminal"
        case .backup: return "arrow.down.doc"
        case .activityLog: return "list.bullet.clipboard"
        case .importSQL: return "arrow.up.doc"
        }
    }
}

public enum TableDetailTab: String, CaseIterable, Identifiable {
    case structure = "Structure"
    case data = "Data"
    case indexes = "Indexes"

    public var id: String { rawValue }
}

// MARK: - Alert Types

public enum DatabaseDetailAlert: Identifiable {
    case confirmDropTable(String)
    case confirmTruncateTable(String)
    case confirmDeleteDatabase
    case confirmDropColumn(String)
    case confirmDeleteRow(Int)
    case confirmDeleteSelectedRows
    case confirmDeleteBackup(String)
    case confirmDropIndex(String)
    case confirmRestoreBackup(String)

    public var id: String {
        switch self {
        case .confirmDropTable(let name): return "drop_\(name)"
        case .confirmTruncateTable(let name): return "truncate_\(name)"
        case .confirmDeleteDatabase: return "delete_db"
        case .confirmDropColumn(let name): return "dropcol_\(name)"
        case .confirmDeleteRow(let idx): return "deleterow_\(idx)"
        case .confirmDeleteSelectedRows: return "delete_selected_rows"
        case .confirmDeleteBackup(let id): return "deletebak_\(id)"
        case .confirmDropIndex(let name): return "dropidx_\(name)"
        case .confirmRestoreBackup(let id): return "restorebak_\(id)"
        }
    }
}

// MARK: - Query History Entry

public struct QueryHistoryEntry: Identifiable {
    public let id = UUID()
    public let query: String
    public let timestamp: Date
    public let success: Bool
    public let executionTime: TimeInterval
}

// MARK: - Activity Log Entry

public struct DBActivityLogEntry: Identifiable {
    public let id = UUID()
    public let action: String
    public let detail: String
    public let timestamp: Date
    public let success: Bool
    public let errorMessage: String?

    public init(action: String, detail: String, success: Bool, errorMessage: String? = nil) {
        self.action = action
        self.detail = detail
        self.timestamp = Date()
        self.success = success
        self.errorMessage = errorMessage
    }
}

// MARK: - ViewModel

@MainActor
public final class DatabaseDetailViewModel: ObservableObject {

    // MARK: - Database Info

    @Published public var database: DatabaseInfo
    let serverId: String?
    public var currentServerId: String? { serverId }

    // MARK: - Navigation

    @Published public var currentSection: DatabaseDetailSection = .overview
    @Published public var tableDetailTab: TableDetailTab = .structure

    // MARK: - Tables

    @Published public var tables: [TableInfo] = []
    @Published public var selectedTable: TableInfo?
    @Published public var tableStructure: TableStructure?
    @Published public var showCreateTable = false
    @Published public var tableIndexes: [TableIndex] = []
    @Published public var tableSearchText = ""

    public var filteredTables: [TableInfo] {
        if tableSearchText.isEmpty { return tables }
        return tables.filter { $0.name.localizedCaseInsensitiveContains(tableSearchText) }
    }

    // MARK: - Data Browsing

    @Published public var browseResult: QueryResult?
    @Published public var currentPage: Int = 0
    @Published public var pageSize: Int = AppSettingsManager.shared.dbMaxRowsDisplay
    @Published public var sortColumn: String?
    @Published public var sortAscending: Bool = true

    public var totalPages: Int {
        guard let table = selectedTable else { return 0 }
        let total = Int(table.rowCount)
        return max(1, (total + pageSize - 1) / pageSize)
    }

    public var hasNextPage: Bool {
        currentPage < totalPages - 1
    }

    public var hasPreviousPage: Bool {
        currentPage > 0
    }

    // MARK: - Row Management

    @Published public var selectedRows: Set<Int> = []
    @Published public var showAddRow = false
    @Published public var showEditRow = false
    @Published public var editingRowIndex: Int?
    @Published public var editingRowValues: [String: String?] = [:]
    @Published public var duplicateRowValues: [String: String]?
    @Published public var dataSearchText = ""
    @Published public var isSearching = false

    // MARK: - SQL Console

    @Published public var queryText = ""
    @Published public var queryResult: QueryResult?
    @Published public var queryError: String?
    @Published public var queryHistory: [QueryHistoryEntry] = []
    @Published public var isExecutingQuery = false

    // MARK: - Backup

    @Published public var backups: [BackupInfo] = []
    @Published public var isCreatingBackup = false
    @Published public var showImportSQL = false
    @Published public var isDownloadingBackup = false

    // MARK: - Activity Log

    @Published public var activityLog: [DBActivityLogEntry] = []

    func log(action: String, detail: String, success: Bool, error: String? = nil) {
        activityLog.insert(DBActivityLogEntry(action: action, detail: detail, success: success, errorMessage: error), at: 0)
    }

    // MARK: - State

    @Published public var isLoading = false
    @Published public var operationResult: OperationResult = .idle
    @Published public var activeAlert: DatabaseDetailAlert?

    // MARK: - Init

    public init(database: DatabaseInfo, serverId: String?) {
        self.database = database
        self.serverId = serverId
    }

    // MARK: - Loading

    public func loadTables() async {
        guard let serverId = serverId else { return }

        isLoading = true
        do {
            tables = try await DatabaseTableService.shared.listTables(
                database: database.name,
                type: database.type,
                serverId: serverId
            )
            log(action: "Load Tables", detail: "Loaded \(tables.count) tables from '\(database.name)'", success: true)
        } catch {
            log(action: "Load Tables", detail: "Database '\(database.name)'", success: false, error: error.localizedDescription)
            GlobalToastManager.shared.showError("\(L10n.Database.loadTablesFailed): \(error.localizedDescription)")
        }
        isLoading = false
    }

    public func selectTable(_ table: TableInfo) {
        selectedTable = table
        tableDetailTab = .structure
        tableStructure = nil
        tableIndexes = []
        browseResult = nil
        currentPage = 0
        sortColumn = nil
        Task {
            await loadTableStructure()
        }
    }

    public func deselectTable() {
        selectedTable = nil
        tableStructure = nil
        tableIndexes = []
        browseResult = nil
    }

    public func loadTableStructure() async {
        guard let serverId = serverId, let table = selectedTable else { return }

        isLoading = true
        do {
            async let structure = DatabaseTableService.shared.describeTable(
                database: database.name,
                table: table.name,
                type: database.type,
                serverId: serverId
            )
            async let indexes = DatabaseTableService.shared.getTableIndexes(
                database: database.name,
                table: table.name,
                type: database.type,
                serverId: serverId
            )

            let cols = try await structure
            tableStructure = TableStructure(columns: cols)
            let indexStr = try await indexes
            tableIndexes = parseIndexString(indexStr)
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.loadStructureFailed): \(error.localizedDescription)")
        }
        isLoading = false
    }

    public func loadTableData() async {
        guard let serverId = serverId, let table = selectedTable else {
            print("[DBDetailVM] loadTableData: no serverId or selectedTable")
            return
        }

        isLoading = true
        do {
            print("[DBDetailVM] loadTableData: browsing \(database.name).\(table.name) page=\(currentPage) pageSize=\(pageSize)")
            browseResult = try await DatabaseRowService.shared.browseRows(
                database: database.name,
                table: table.name,
                type: database.type,
                serverId: serverId,
                page: currentPage + 1,
                pageSize: pageSize,
                orderBy: sortColumn ?? "",
                ascending: sortAscending
            )
            print("[DBDetailVM] loadTableData: browseResult rows=\(browseResult?.rows.count ?? -1) columns=\(browseResult?.columns.count ?? -1)")
        } catch {
            print("[DBDetailVM] loadTableData ERROR: \(error)")
            GlobalToastManager.shared.showError("\(L10n.Database.loadDataFailed): \(error.localizedDescription)")
        }
        isLoading = false
    }

    public func nextPage() async {
        guard hasNextPage else { return }
        currentPage += 1
        await loadTableData()
    }

    public func previousPage() async {
        guard hasPreviousPage else { return }
        currentPage -= 1
        await loadTableData()
    }

    public func sortBy(_ column: String) async {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
        currentPage = 0
        await loadTableData()
    }

    // MARK: - SQL Console

    public func executeQuery() async {
        guard let serverId = serverId else { return }
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isExecutingQuery = true
        queryError = nil
        let startTime = Date()
        let timeout = AppSettingsManager.shared.dbQueryTimeout

        do {
            queryResult = try await withThrowingTaskGroup(of: QueryResult.self) { group in
                group.addTask {
                    try await DatabaseRowService.shared.executeQuery(
                        database: self.database.name,
                        query: query,
                        type: self.database.type,
                        serverId: serverId
                    )
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeout) * 1_000_000_000)
                    throw DatabaseServiceError.invalidResponse("Query timed out after \(timeout)s")
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }

            queryHistory.insert(QueryHistoryEntry(
                query: query,
                timestamp: Date(),
                success: true,
                executionTime: Date().timeIntervalSince(startTime)
            ), at: 0)

            log(action: "Execute Query", detail: query.prefix(100) + (query.count > 100 ? "..." : ""), success: true)

        } catch {
            queryError = error.localizedDescription
            queryResult = nil

            queryHistory.insert(QueryHistoryEntry(
                query: query,
                timestamp: Date(),
                success: false,
                executionTime: Date().timeIntervalSince(startTime)
            ), at: 0)

            log(action: "Execute Query", detail: query.prefix(100) + (query.count > 100 ? "..." : ""), success: false, error: error.localizedDescription)
        }

        isExecutingQuery = false
    }

    // MARK: - Backup

    public func createBackup() async {
        guard let serverId = serverId else { return }

        isCreatingBackup = true
        operationResult = .inProgress(message: "\(L10n.Database.createBackup) '\(database.name)'...", progress: nil)

        do {
            try await DatabaseBackupService.shared.createBackup(
                database: database.name,
                type: database.type,
                serverId: serverId
            )
            // Reload backups list after creation
            await loadBackups()
            GlobalToastManager.shared.showSuccess(L10n.Database.backupCreated)
            log(action: "Create Backup", detail: "Database '\(database.name)'", success: true)
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.backupFailed): \(error.localizedDescription)")
            log(action: "Create Backup", detail: "Database '\(database.name)'", success: false, error: error.localizedDescription)
        }

        isCreatingBackup = false
    }

    public func loadBackups() async {
        guard let serverId = serverId else { return }

        do {
            backups = try await DatabaseBackupService.shared.listBackups(
                type: database.type,
                serverId: serverId
            )
        } catch {
            // Non-critical, don't show error
        }
    }

    // MARK: - Operation Helper
    
    /// Shared helper for table operations: sets progress, executes, shows toast, logs activity.
    /// Preserves all features: operationResult tracking, toast notifications, and activity logging.
    func loggedAction(
        action actionLabel: String,
        detail: String,
        progressMessage: String,
        execute: () async throws -> Void,
        onSuccess: (() async -> Void)? = nil
    ) async {
        guard serverId != nil else { return }
        operationResult = .inProgress(message: progressMessage, progress: nil)
        do {
            try await execute()
            GlobalToastManager.shared.showSuccess(L10n.Database.actionSuccessful(actionLabel))
            log(action: actionLabel, detail: detail, success: true)
            await onSuccess?()
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.actionFailed(actionLabel)): \(error.localizedDescription)")
            log(action: actionLabel, detail: detail, success: false, error: error.localizedDescription)
        }
    }

    // MARK: - Table Actions

    public func confirmDropTable(_ tableName: String) {
        if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmDropDBTable) {
            activeAlert = .confirmDropTable(tableName)
        } else {
            Task { await dropTable(tableName) }
        }
    }

    public func confirmTruncateTable(_ tableName: String) {
        if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmTruncateTable) {
            activeAlert = .confirmTruncateTable(tableName)
        } else {
            Task { await truncateTable(tableName) }
        }
    }

    public func dropTable(_ tableName: String) async {
        await loggedAction(
            action: "Drop Table",
            detail: "Table '\(tableName)' from '\(database.name)'",
            progressMessage: "Dropping table '\(tableName)'...",
            execute: {
                try await DatabaseTableService.shared.dropTable(
                    database: database.name, table: tableName,
                    type: database.type, serverId: serverId!
                )
            },
            onSuccess: {
                if self.selectedTable?.name == tableName { self.deselectTable() }
                await self.loadTables()
            }
        )
    }

    public func truncateTable(_ tableName: String) async {
        await loggedAction(
            action: "Truncate Table",
            detail: "Table '\(tableName)'",
            progressMessage: "Truncating table '\(tableName)'...",
            execute: {
                try await DatabaseTableService.shared.truncateTable(
                    database: database.name, table: tableName,
                    type: database.type, serverId: serverId!
                )
            },
            onSuccess: {
                await self.loadTables()
                if self.selectedTable?.name == tableName { await self.loadTableData() }
            }
        )
    }

    public func optimizeTable(_ tableName: String) async {
        await loggedAction(
            action: "Optimize Table",
            detail: "Table '\(tableName)'",
            progressMessage: "Optimizing table '\(tableName)'...",
            execute: {
                _ = try await DatabaseTableService.shared.optimizeTable(
                    database: database.name, table: tableName,
                    type: database.type, serverId: serverId!
                )
            }
        )
    }

    public func analyzeTable(_ tableName: String) async {
        await loggedAction(
            action: "Analyze Table",
            detail: "Table '\(tableName)'",
            progressMessage: "Analyzing table '\(tableName)'...",
            execute: {
                _ = try await DatabaseTableService.shared.analyzeTable(
                    database: database.name, table: tableName,
                    type: database.type, serverId: serverId!
                )
            }
        )
    }

    // MARK: - Create Table

    public func createTable(name: String, columns: [CreateTableColumnDefinition]) async {
        guard let serverId = serverId else { return }

        operationResult = .inProgress(message: "Creating table '\(name)'...", progress: nil)
        do {
            try await DatabaseTableService.shared.createTable(
                database: database.name,
                table: name,
                columns: columns,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess(L10n.Database.tableCreated(name))
            log(action: "Create Table", detail: "Table '\(name)' with \(columns.count) columns in '\(database.name)'", success: true)
            showCreateTable = false
            await loadTables()
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.createTableFailed): \(error.localizedDescription)")
            log(action: "Create Table", detail: "Table '\(name)'", success: false, error: error.localizedDescription)
        }
    }

    // MARK: - Edit Table Structure

    @Published public var showAddColumn = false
    @Published public var showCreateIndex = false
    @Published public var showRenameTable = false

    public func addColumn(_ column: CreateTableColumnDefinition, afterColumn: String?) async {
        guard let table = selectedTable else { return }
        await loggedAction(
            action: "Add Column",
            detail: "Column '\(column.name)' (\(column.type)) to table '\(table.name)'",
            progressMessage: "Adding column '\(column.name)'...",
            execute: {
                try await DatabaseTableService.shared.addColumn(
                    database: database.name, table: table.name,
                    name: column.name,
                    type: column.type,
                    length: column.length ?? "",
                    nullable: column.isNullable,
                    primaryKey: column.isPrimaryKey,
                    autoIncrement: column.isAutoIncrement,
                    unique: column.isUnique,
                    defaultValue: column.defaultValue,
                    afterColumn: afterColumn ?? "",
                    engineType: database.type.rawValue,
                    serverId: serverId!
                )
            },
            onSuccess: {
                self.showAddColumn = false
                await self.loadTableStructure()
            }
        )
    }

    public func dropColumn(_ columnName: String) async {
        guard let table = selectedTable else { return }
        await loggedAction(
            action: "Drop Column",
            detail: "Column '\(columnName)' from table '\(table.name)'",
            progressMessage: "Dropping column '\(columnName)'...",
            execute: {
                try await DatabaseTableService.shared.dropColumn(
                    database: database.name, table: table.name,
                    column: columnName,
                    type: database.type, serverId: serverId!
                )
            },
            onSuccess: { await self.loadTableStructure() }
        )
    }

    // Row management methods → DatabaseDetailViewModel+Rows.swift
    // Backup + advanced ops → DatabaseDetailViewModel+Advanced.swift

    // MARK: - Helpers

    public func dismissResult() {
        operationResult = .idle
    }

    /// Parse raw index string from SSH into TableIndex array (engine-aware)
    func parseIndexString(_ raw: String) -> [TableIndex] {
        guard !raw.isEmpty else { return [] }
        switch database.type {
        case .postgresql, .cockroachdb:
            return parsePostgreSQLIndexes(raw)
        case .sqlite:
            return parseSQLiteIndexes(raw)
        case .mongodb:
            return parseMongoDBIndexes(raw)
        default:
            return parseMySQLIndexes(raw)
        }
    }

    /// MySQL/MariaDB: SHOW INDEX output — tab-separated columns
    /// Format: Table | Non_unique | Key_name | Seq | Column_name | ...
    private func parseMySQLIndexes(_ raw: String) -> [TableIndex] {
        var indexes: [TableIndex] = []
        for line in raw.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: "\t").filter { !$0.isEmpty }
            if parts.count >= 5 {
                let name = parts[2]
                let colName = parts[4]
                let isUnique = parts[1] == "0"
                if let idx = indexes.firstIndex(where: { $0.name == name }) {
                    var cols = indexes[idx].columns
                    cols.append(colName)
                    indexes[idx] = TableIndex(name: name, columns: cols, isUnique: indexes[idx].isUnique, type: indexes[idx].type)
                } else {
                    indexes.append(TableIndex(name: name, columns: [colName], isUnique: isUnique))
                }
            }
        }
        return indexes
    }

    /// PostgreSQL: "indexname | indexdef" from pg_indexes
    private func parsePostgreSQLIndexes(_ raw: String) -> [TableIndex] {
        var indexes: [TableIndex] = []
        for line in raw.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2 else { continue }
            let name = parts[0]
            let indexDef = parts[1]
            let isUnique = indexDef.lowercased().contains("unique")
            // Extract columns from "... (col1, col2)" pattern
            var columns: [String] = []
            if let parenStart = indexDef.range(of: "(", options: .backwards),
               let parenEnd = indexDef.range(of: ")", options: .backwards) {
                let colStr = indexDef[parenStart.upperBound..<parenEnd.lowerBound]
                columns = colStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            let indexType = indexDef.lowercased().contains("using btree") ? "BTREE" :
                            indexDef.lowercased().contains("using hash") ? "HASH" :
                            indexDef.lowercased().contains("using gin") ? "GIN" :
                            indexDef.lowercased().contains("using gist") ? "GiST" : "BTREE"
            indexes.append(TableIndex(name: name, columns: columns, isUnique: isUnique, type: indexType))
        }
        return indexes
    }

    /// SQLite: PRAGMA index_list output — pipe-separated: seq|name|unique|origin|partial
    private func parseSQLiteIndexes(_ raw: String) -> [TableIndex] {
        var indexes: [TableIndex] = []
        for line in raw.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: "|")
            guard parts.count >= 3 else { continue }
            let name = parts[1]
            let isUnique = parts[2] == "1"
            indexes.append(TableIndex(name: name, columns: [], isUnique: isUnique))
        }
        return indexes
    }

    /// MongoDB: JSON per line from getIndexes()
    private func parseMongoDBIndexes(_ raw: String) -> [TableIndex] {
        var indexes: [TableIndex] = []
        for line in raw.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("{"), let data = trimmed.data(using: .utf8) else { continue }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let name = json["name"] as? String ?? ""
                let isUnique = json["unique"] as? Bool ?? false
                var columns: [String] = []
                if let key = json["key"] as? [String: Any] {
                    columns = Array(key.keys)
                }
                indexes.append(TableIndex(name: name, columns: columns, isUnique: isUnique))
            }
        }
        return indexes
    }
}

