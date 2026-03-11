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

    public var id: String { rawValue }

    var iconName: String {
        switch self {
        case .overview: return "chart.bar"
        case .tables: return "tablecells"
        case .queryConsole: return "terminal"
        case .backup: return "arrow.down.doc"
        case .activityLog: return "list.bullet.clipboard"
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

    public var id: String {
        switch self {
        case .confirmDropTable(let name): return "drop_\(name)"
        case .confirmTruncateTable(let name): return "truncate_\(name)"
        case .confirmDeleteDatabase: return "delete_db"
        case .confirmDropColumn(let name): return "dropcol_\(name)"
        case .confirmDeleteRow(let idx): return "deleterow_\(idx)"
        case .confirmDeleteSelectedRows: return "delete_selected_rows"
        case .confirmDeleteBackup(let id): return "deletebak_\(id)"
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
    private let serverId: String?

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
    @Published public var pageSize: Int = 50
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
    @Published public var dataSearchText = ""
    @Published public var isSearching = false

    // MARK: - SQL Console

    @Published public var queryText = ""
    @Published public var queryResult: QueryResult?
    @Published public var queryHistory: [QueryHistoryEntry] = []
    @Published public var isExecutingQuery = false

    // MARK: - Backup

    @Published public var backups: [BackupInfo] = []
    @Published public var isCreatingBackup = false
    @Published public var showImportSQL = false
    @Published public var isDownloadingBackup = false

    // MARK: - Activity Log

    @Published public var activityLog: [DBActivityLogEntry] = []

    private func log(action: String, detail: String, success: Bool, error: String? = nil) {
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
            GlobalToastManager.shared.showError("Failed to load tables: \(error.localizedDescription)")
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
            GlobalToastManager.shared.showError("Failed to load table structure: \(error.localizedDescription)")
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
            GlobalToastManager.shared.showError("Failed to load data: \(error.localizedDescription)")
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
        let startTime = Date()

        do {
            queryResult = try await DatabaseRowService.shared.executeQuery(
                database: database.name,
                query: query,
                type: database.type,
                serverId: serverId
            )

            queryHistory.insert(QueryHistoryEntry(
                query: query,
                timestamp: Date(),
                success: true,
                executionTime: Date().timeIntervalSince(startTime)
            ), at: 0)

            log(action: "Execute Query", detail: query.prefix(100) + (query.count > 100 ? "..." : ""), success: true)

        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)

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
        operationResult = .inProgress(message: "Creating backup of '\(database.name)'...", progress: nil)

        do {
            try await DatabaseBackupService.shared.createBackup(
                database: database.name,
                type: database.type,
                serverId: serverId
            )
            // Reload backups list after creation
            await loadBackups()
            GlobalToastManager.shared.showSuccess("Backup created successfully")
            log(action: "Create Backup", detail: "Database '\(database.name)'", success: true)
        } catch {
            GlobalToastManager.shared.showError("Backup failed: \(error.localizedDescription)")
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
    private func loggedAction(
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
            GlobalToastManager.shared.showSuccess("\(actionLabel) successful")
            log(action: actionLabel, detail: detail, success: true)
            await onSuccess?()
        } catch {
            GlobalToastManager.shared.showError("\(actionLabel) failed: \(error.localizedDescription)")
            log(action: actionLabel, detail: detail, success: false, error: error.localizedDescription)
        }
    }

    // MARK: - Table Actions

    public func confirmDropTable(_ tableName: String) {
        activeAlert = .confirmDropTable(tableName)
    }

    public func confirmTruncateTable(_ tableName: String) {
        activeAlert = .confirmTruncateTable(tableName)
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
            GlobalToastManager.shared.showSuccess("Table '\(name)' created successfully")
            log(action: "Create Table", detail: "Table '\(name)' with \(columns.count) columns in '\(database.name)'", success: true)
            showCreateTable = false
            await loadTables()
        } catch {
            GlobalToastManager.shared.showError("Failed to create table: \(error.localizedDescription)")
            log(action: "Create Table", detail: "Table '\(name)'", success: false, error: error.localizedDescription)
        }
    }

    // MARK: - Edit Table Structure

    @Published public var showAddColumn = false

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

    // MARK: - Row Management Methods

    public func insertRow(_ values: [String: String?]) async {
        guard let serverId = serverId, let table = selectedTable else { return }

        do {
            let nonNilValues = values.compactMapValues { $0 }
            try await DatabaseRowService.shared.insertRow(
                database: database.name,
                table: table.name,
                values: nonNilValues,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("Row inserted successfully")
            log(action: "Insert Row", detail: "Table '\(table.name)'", success: true)
            showAddRow = false
            await loadTableData()
            await loadTables()
        } catch {
            GlobalToastManager.shared.showError("Failed to insert row: \(error.localizedDescription)")
            log(action: "Insert Row", detail: "Table '\(table.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func updateRow(primaryKey: [String: String], values: [String: String?]) async {
        guard let serverId = serverId, let table = selectedTable else { return }

        do {
            let nonNilValues = values.compactMapValues { $0 }
            try await DatabaseRowService.shared.updateRow(
                database: database.name,
                table: table.name,
                primaryKey: primaryKey,
                values: nonNilValues,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("Row updated successfully")
            log(action: "Update Row", detail: "Table '\(table.name)'", success: true)
            showEditRow = false
            editingRowIndex = nil
            await loadTableData()
        } catch {
            GlobalToastManager.shared.showError("Failed to update row: \(error.localizedDescription)")
            log(action: "Update Row", detail: "Table '\(table.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func deleteRow(at index: Int) async {
        guard let pk = primaryKeyValues(forRowAt: index), let table = selectedTable else {
            GlobalToastManager.shared.showError("Cannot determine primary key for this row")
            return
        }
        guard let serverId = serverId else { return }

        do {
            try await DatabaseRowService.shared.deleteRow(
                database: database.name,
                table: table.name,
                primaryKey: pk,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("Row deleted successfully")
            log(action: "Delete Row", detail: "Table '\(table.name)'", success: true)
            selectedRows.remove(index)
            await loadTableData()
            await loadTables()
        } catch {
            GlobalToastManager.shared.showError("Failed to delete row: \(error.localizedDescription)")
            log(action: "Delete Row", detail: "Table '\(table.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func deleteSelectedRows() async {
        guard let serverId = serverId, let table = selectedTable else { return }

        var pks: [[String: String]] = []
        for index in selectedRows.sorted() {
            if let pk = primaryKeyValues(forRowAt: index) {
                pks.append(pk)
            }
        }

        guard !pks.isEmpty else {
            GlobalToastManager.shared.showError("Cannot determine primary keys for selected rows")
            return
        }

        do {
            try await DatabaseRowService.shared.deleteRows(
                database: database.name,
                table: table.name,
                primaryKeys: pks,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("\(pks.count) row(s) deleted successfully")
            log(action: "Delete Rows", detail: "\(pks.count) rows from '\(table.name)'", success: true)
            selectedRows.removeAll()
            await loadTableData()
            await loadTables()
        } catch {
            GlobalToastManager.shared.showError("Failed to delete rows: \(error.localizedDescription)")
            log(action: "Delete Rows", detail: "\(selectedRows.count) rows from '\(table.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func toggleRowSelection(_ index: Int) {
        if selectedRows.contains(index) {
            selectedRows.remove(index)
        } else {
            selectedRows.insert(index)
        }
    }

    public func selectAllRows() {
        guard let result = browseResult else { return }
        selectedRows = Set(0..<result.rows.count)
    }

    public func deselectAllRows() {
        selectedRows.removeAll()
    }

    public func searchData() async {
        guard let serverId = serverId, let table = selectedTable else { return }
        let search = dataSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else {
            await clearSearch()
            return
        }

        isSearching = true
        let columns = browseResult?.columns ?? tableStructure?.columns.map(\.name) ?? []
        guard !columns.isEmpty else {
            isSearching = false
            return
        }

        do {
            browseResult = try await DatabaseRowService.shared.searchRows(
                database: database.name,
                table: table.name,
                search: search,
                type: database.type,
                serverId: serverId,
                page: currentPage + 1,
                pageSize: pageSize,
                orderBy: sortColumn ?? "",
                ascending: sortAscending
            )
            selectedRows.removeAll()
        } catch {
            GlobalToastManager.shared.showError("Search failed: \(error.localizedDescription)")
        }
        isSearching = false
    }

    public func clearSearch() async {
        dataSearchText = ""
        isSearching = false
        currentPage = 0
        selectedRows.removeAll()
        await loadTableData()
    }

    public func startEditingRow(_ index: Int) {
        guard let result = browseResult, index < result.rows.count else { return }
        editingRowIndex = index
        let row = result.rows[index]
        var values: [String: String?] = [:]
        for (colIdx, col) in result.columns.enumerated() {
            values[col] = colIdx < row.count ? row[colIdx] : nil
        }
        editingRowValues = values
        showEditRow = true
    }

    private func primaryKeyValues(forRowAt index: Int) -> [String: String]? {
        guard let structure = tableStructure,
              let result = browseResult,
              index < result.rows.count else { return nil }

        let pkColumns = structure.columns.filter { $0.isPrimaryKey }.map(\.name)
        guard !pkColumns.isEmpty else {
            // Fallback: use first column as pseudo-PK
            if let firstCol = result.columns.first, !result.rows[index].isEmpty {
                let val = result.rows[index][0]
                return [firstCol: val]
            }
            return nil
        }

        var pk: [String: String] = [:]
        for pkCol in pkColumns {
            if let colIdx = result.columns.firstIndex(of: pkCol),
               colIdx < result.rows[index].count {
                pk[pkCol] = result.rows[index][colIdx]
            }
        }

        return pk.isEmpty ? nil : pk
    }

    // MARK: - Backup Enhancements

    public func deleteBackup(_ backupId: String) async {
        guard let serverId = serverId else { return }

        do {
            try await DatabaseBackupService.shared.deleteBackup(
                backupPath: backupId,
                type: database.type,
                serverId: serverId
            )
            backups.removeAll { $0.id == backupId }
            GlobalToastManager.shared.showSuccess("Backup deleted")
            log(action: "Delete Backup", detail: backupId, success: true)
        } catch {
            GlobalToastManager.shared.showError("Failed to delete backup: \(error.localizedDescription)")
            log(action: "Delete Backup", detail: backupId, success: false, error: error.localizedDescription)
        }
    }

    public func downloadBackup(_ backupId: String) async {
        guard let serverId = serverId else { return }

        isDownloadingBackup = true
        let progressId = GlobalToastManager.shared.showProgress("Downloading backup...")

        do {
            let data = try await DatabaseBackupService.shared.downloadBackup(
                backupPath: backupId,
                type: database.type,
                serverId: serverId
            )

            GlobalToastManager.shared.dismiss(id: progressId)

            // Present Save As panel
            let panel = NSSavePanel()
            panel.nameFieldStringValue = URL(fileURLWithPath: backupId).lastPathComponent
            panel.allowedContentTypes = [UTType(filenameExtension: "sql") ?? .plainText]
            panel.canCreateDirectories = true
            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                try data.write(to: url)
                GlobalToastManager.shared.showSuccess("Backup saved successfully")
                log(action: "Download Backup", detail: url.lastPathComponent, success: true)
            }
        } catch {
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showError("Download failed: \(error.localizedDescription)")
            log(action: "Download Backup", detail: backupId, success: false, error: error.localizedDescription)
        }

        isDownloadingBackup = false
    }

    public func importSQL(_ sqlContent: String) async {
        guard let serverId = serverId else { return }
        let content = sqlContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            GlobalToastManager.shared.showError("SQL content is empty")
            return
        }

        let progressId = GlobalToastManager.shared.showProgress("Importing SQL...")

        do {
            _ = try await DatabaseBackupService.shared.importSQL(
                database: database.name,
                sqlContent: content,
                type: database.type,
                serverId: serverId
            )
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showSuccess("SQL imported successfully")
            log(action: "Import SQL", detail: "\(content.count) characters into '\(database.name)'", success: true)
            showImportSQL = false
            await loadTables()
        } catch {
            GlobalToastManager.shared.dismiss(id: progressId)
            GlobalToastManager.shared.showError("Import failed: \(error.localizedDescription)")
            log(action: "Import SQL", detail: "Into '\(database.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func confirmDeleteBackup(_ backupId: String) {
        activeAlert = .confirmDeleteBackup(backupId)
    }

    // MARK: - Helpers

    public func dismissResult() {
        operationResult = .idle
    }

    /// Parse raw index string from SSH into TableIndex array
    private func parseIndexString(_ raw: String) -> [TableIndex] {
        guard !raw.isEmpty else { return [] }
        var indexes: [TableIndex] = []
        let lines = raw.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: "\t").filter { !$0.isEmpty }
            if parts.count >= 2 {
                let name = parts.count > 2 ? parts[2] : parts[0]
                let colName = parts.count > 4 ? parts[4] : parts.last ?? ""
                let isUnique = parts.count > 1 ? parts[1] == "0" : false
                let existing = indexes.firstIndex { $0.name == name }
                if let idx = existing {
                    var updated = indexes[idx]
                    var cols = updated.columns
                    cols.append(colName)
                    indexes[idx] = TableIndex(name: updated.name, columns: cols, isUnique: updated.isUnique, type: updated.type)
                } else {
                    indexes.append(TableIndex(name: name, columns: [colName], isUnique: isUnique))
                }
            }
        }
        return indexes
    }
}
