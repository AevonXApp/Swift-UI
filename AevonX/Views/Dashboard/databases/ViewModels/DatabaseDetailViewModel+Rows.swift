//
//  DatabaseDetailViewModel+Rows.swift
//  AevonX
//
//  Row management, data search, and row editing for database detail VM.
//

import Foundation
import SwiftUI
import AevonXCoreBridge

// MARK: - Row Management

extension DatabaseDetailViewModel {

    public func insertRow(_ values: [String: String?]) async {
        guard let serverId = serverId, let table = selectedTable else { return }

        do {
            if explorerEnabled {
                var request = ExplorerRequest(database: database.name, table: table.name)
                request.values = values.filter { !binaryColumnNames.contains($0.key) }
                _ = try await DatabaseRowService.shared.explorerWrite(.insert, request, type: database.type, serverId: serverId)
            } else {
                // Legacy adapters have no NULL literal; keep their old contract.
                let nonNilValues = values.reduce(into: [String: String]()) { result, pair in
                    result[pair.key] = pair.value ?? "NULL"
                }
                try await DatabaseRowService.shared.insertRow(
                    database: database.name,
                    table: table.name,
                    values: nonNilValues,
                    type: database.type,
                    serverId: serverId
                )
            }
            GlobalToastManager.shared.showSuccess(L10n.Database.rowInserted)
            log(action: "Insert Row", detail: "Table '\(table.name)'", success: true)
            showAddRow = false
            adjustRowCount(by: 1)
            invalidateExplorerPages()
            await loadTableData()
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.rowInsertFailed): \(error.localizedDescription)")
            log(action: "Insert Row", detail: "Table '\(table.name)'", success: false, error: error.localizedDescription)
        }
    }

    /// Saves only the columns that changed since the edit sheet opened
    /// (binary columns are never written back from text).
    public func updateRow(primaryKey: [String: String], values: [String: String?]) async {
        guard let serverId = serverId, let table = selectedTable else { return }

        let binary = binaryColumnNames
        var changed: [String: String?] = [:]
        for (column, value) in values where !binary.contains(column) {
            let original: String?? = editingOriginalValues[column]
            if original == nil || original! != value {
                changed[column] = value
            }
        }
        guard !changed.isEmpty else {
            GlobalToastManager.shared.showSuccess(L10n.Database.noChangesToSave)
            showEditRow = false
            editingRowIndex = nil
            return
        }

        var key = primaryKey
        if key.isEmpty, let index = editingRowIndex, let fallback = rowKey(forRowAt: index) {
            key = fallback
        }
        guard !key.isEmpty else {
            GlobalToastManager.shared.showError(L10n.Database.noPrimaryKey)
            return
        }

        do {
            if explorerEnabled {
                var request = ExplorerRequest(database: database.name, table: table.name)
                request.key = key
                request.values = changed
                _ = try await DatabaseRowService.shared.explorerWrite(.update, request, type: database.type, serverId: serverId)
            } else {
                let nonNilValues = changed.reduce(into: [String: String]()) { result, pair in
                    result[pair.key] = pair.value ?? "NULL"
                }
                try await DatabaseRowService.shared.updateRow(
                    database: database.name,
                    table: table.name,
                    primaryKey: key,
                    values: nonNilValues,
                    type: database.type,
                    serverId: serverId
                )
            }
            GlobalToastManager.shared.showSuccess(L10n.Database.rowUpdated)
            log(action: "Update Row", detail: "Table '\(table.name)' (\(changed.count) columns)", success: true)
            showEditRow = false
            editingRowIndex = nil
            editingOriginalValues = [:]
            invalidateExplorerPages()
            await loadTableData()
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.rowUpdateFailed): \(error.localizedDescription)")
            log(action: "Update Row", detail: "Table '\(table.name)'", success: false, error: error.localizedDescription)
        }
    }

    public func deleteRow(at index: Int) async {
        guard let pk = primaryKeyValues(forRowAt: index), let table = selectedTable else {
            GlobalToastManager.shared.showError(L10n.Database.noPrimaryKey)
            return
        }
        guard let serverId = serverId else { return }

        do {
            if explorerEnabled {
                var request = ExplorerRequest(database: database.name, table: table.name)
                request.keys = [pk]
                _ = try await DatabaseRowService.shared.explorerWrite(.delete, request, type: database.type, serverId: serverId)
            } else {
                try await DatabaseRowService.shared.deleteRow(
                    database: database.name,
                    table: table.name,
                    primaryKey: pk,
                    type: database.type,
                    serverId: serverId
                )
            }
            GlobalToastManager.shared.showSuccess(L10n.Database.rowDeleted)
            log(action: "Delete Row", detail: "Table '\(table.name)'", success: true)
            selectedRows.removeAll()
            adjustRowCount(by: -1)
            invalidateExplorerPages()
            await loadTableData()
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.rowDeleteFailed): \(error.localizedDescription)")
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
            GlobalToastManager.shared.showError(L10n.Database.noPrimaryKeys)
            return
        }

        do {
            var deleted = Int64(pks.count)
            if explorerEnabled {
                var request = ExplorerRequest(database: database.name, table: table.name)
                request.keys = pks
                deleted = try await DatabaseRowService.shared.explorerWrite(.delete, request, type: database.type, serverId: serverId)
            } else {
                try await DatabaseRowService.shared.deleteRows(
                    database: database.name,
                    table: table.name,
                    primaryKeys: pks,
                    type: database.type,
                    serverId: serverId
                )
            }
            GlobalToastManager.shared.showSuccess(L10n.Database.rowsDeleted(Int(deleted)))
            log(action: "Delete Rows", detail: "\(deleted) rows from '\(table.name)'", success: true)
            selectedRows.removeAll()
            adjustRowCount(by: -deleted)
            invalidateExplorerPages()
            await loadTableData()
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.rowsDeleteFailed): \(error.localizedDescription)")
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

    // MARK: - Search

    /// Applies `dataSearchText` (empty text restores the unfiltered rows).
    public func searchData() async {
        let text = dataSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let search: String? = text.isEmpty ? nil : text
        guard search != activeSearch else { return }
        activeSearch = search
        currentPage = 0
        selectedRows.removeAll()
        await loadTableData()
    }

    /// Re-runs the active search after the scope or mode changed.
    public func searchOptionsChanged() async {
        guard activeSearch != nil else { return }
        currentPage = 0
        await loadTableData()
    }

    public func clearSearch() async {
        dataSearchText = ""
        isSearching = false
        guard activeSearch != nil else { return }
        activeSearch = nil
        currentPage = 0
        selectedRows.removeAll()
        await loadTableData()
    }

    /// Search for engines without the explorer (whole-row text search).
    func searchDataLegacy() async {
        guard let serverId = serverId, let table = selectedTable, let search = activeSearch else { return }

        isSearching = true
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
            GlobalToastManager.shared.showError("\(L10n.Database.searchFailed): \(error.localizedDescription)")
        }
        isSearching = false
    }

    // MARK: - Editing

    /// Opens the edit sheet with the row's complete values (fetched first when
    /// the grid only holds previews).
    public func startEditingRow(_ index: Int) {
        guard let result = browseResult, index < result.rows.count else { return }
        editingRowIndex = index
        Task {
            guard let values = await completeValues(forRowAt: index) else { return }
            guard editingRowIndex == index else { return }
            editingRowValues = values
            editingOriginalValues = values
            showEditRow = true
        }
    }

    func primaryKeyValues(forRowAt index: Int) -> [String: String]? {
        rowKey(forRowAt: index)
    }
}
