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

    func primaryKeyValues(forRowAt index: Int) -> [String: String]? {
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
}
