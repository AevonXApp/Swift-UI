//
//  DatabaseDetailViewModel+Explorer.swift
//  AevonX
//
//  Fast data explorer for MySQL, MariaDB and PostgreSQL:
//  - pages are fetched with server-side cell previews and limit+1 look-ahead,
//  - pages after the first use keyset cursors when ordered by the primary key,
//  - visited pages are cached and the next page is prefetched,
//  - exact counts are fetched only when cheap or when asked for,
//  - complete rows are fetched on demand (edit, duplicate, copy, view).
//

import Foundation
import SwiftUI
import AevonXCoreBridge

extension DatabaseDetailViewModel {

    /// Characters per text cell in the grid; longer values are previews.
    static let previewChars = 256
    /// Pages kept in memory per detail view.
    static let pageCacheLimit = 16
    /// Tables up to this many (estimated) rows get an exact count automatically.
    static let autoCountRowLimit: Int64 = 200_000

    // MARK: - Search

    /// The search as sent to the server. `column:value` scopes a search to a
    /// column, `column=value` is an exact match on that column.
    struct EffectiveSearch: Equatable {
        let term: String
        let column: String?
        let mode: ExplorerRequest.SearchMode
    }

    var effectiveSearch: EffectiveSearch? {
        guard let raw = activeSearch?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if let separator = raw.firstIndex(where: { $0 == ":" || $0 == "=" }) {
            let name = raw[..<separator].trimmingCharacters(in: .whitespaces)
            let value = raw[raw.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            if !value.isEmpty,
               let column = tableStructure?.columns.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                return EffectiveSearch(term: value, column: column.name, mode: raw[separator] == "=" ? .exact : searchMode)
            }
        }
        return EffectiveSearch(term: raw, column: searchColumn, mode: searchMode)
    }

    public var isSearchActive: Bool { effectiveSearch != nil }

    // MARK: - Signatures

    private var searchSignature: String {
        guard let s = effectiveSearch else { return "" }
        return "\(s.term)\u{1F}\(s.column ?? "*")\u{1F}\(s.mode.rawValue)"
    }

    /// Identifies a sequence of pages (cursors and cache entries belong to it).
    var explorerQuerySignature: String {
        [selectedTable?.name ?? "", searchSignature, sortColumn ?? "", sortAscending ? "a" : "d", String(pageSize)]
            .joined(separator: "\u{1E}")
    }

    /// Identifies the row set an exact count belongs to.
    var explorerCountSignature: String {
        (selectedTable?.name ?? "") + "\u{1E}" + searchSignature
    }

    private func pageKey(_ signature: String, _ page: Int) -> String {
        "\(signature)#\(page)"
    }

    /// Drops cursors/counts that belong to a different query.
    private func syncExplorerSignatures() {
        let query = explorerQuerySignature
        if cursorSignature != query {
            cursorSignature = query
            pageCursors.removeAll()
        }
        let count = explorerCountSignature
        if countSignature != count {
            countSignature = count
            exactRowCount = nil
            countTask?.cancel()
        }
    }

    // MARK: - Paging

    var explorerTotalPages: Int {
        let size = Int64(max(pageSize, 1))
        if let exact = exactRowCount {
            return max(1, Int((exact + size - 1) / size))
        }
        if !hasMoreRows {
            return currentPage + 1
        }
        if !isSearchActive, let estimate = selectedTable?.rowCount, estimate > 0 {
            return max(currentPage + 2, Int((estimate + size - 1) / size))
        }
        return currentPage + 2
    }

    /// Whether the total row count shown is exact (not an estimate).
    public var isRowTotalExact: Bool {
        !explorerEnabled || exactRowCount != nil || !hasMoreRows
    }

    /// Best known total for the current table/search (nil = unknown).
    public var displayedRowTotal: Int64? {
        if let exactRowCount { return exactRowCount }
        if !hasMoreRows, let rows = browseResult?.rows.count {
            return Int64(currentPage * pageSize + rows)
        }
        if !isSearchActive, let estimate = selectedTable?.rowCount, estimate > 0 {
            return estimate
        }
        return nil
    }

    /// The single-column primary key pages can be keyset-paginated on.
    private func keysetColumn(_ columns: [ColumnInfo]) -> String? {
        let pks = columns.filter(\.isPrimaryKey)
        guard pks.count == 1 else { return nil }
        if let sortColumn, sortColumn != pks[0].name { return nil }
        return pks[0].name
    }

    func explorerRequest(page: Int, columns: [ColumnInfo]) -> ExplorerRequest {
        var request = ExplorerRequest(
            database: database.name,
            table: selectedTable?.name ?? "",
            columns: columns.map { .init(name: $0.name, type: $0.type, isPrimaryKey: $0.isPrimaryKey) }
        )
        request.limit = pageSize
        request.orderBy = sortColumn ?? ""
        request.descending = !sortAscending
        request.previewChars = Self.previewChars
        request.offset = page * pageSize
        if page > 0, keysetColumn(columns) != nil, let cursor = pageCursors[page] {
            request.afterKey = cursor
            request.offset = 0
        }
        if let search = effectiveSearch {
            request.search = search.term
            request.searchColumn = search.column ?? ""
            request.searchMode = search.mode
        }
        return request
    }

    func loadExplorerPage(_ page: Int) async {
        guard let serverId = serverId, let table = selectedTable else { return }
        if tableStructure == nil {
            await loadTableStructure()
        }
        guard selectedTable?.name == table.name else { return }
        guard let columns = tableStructure?.columns, !columns.isEmpty else {
            // Without a column list the explorer can't build previews.
            await loadTableDataLegacy()
            return
        }

        syncExplorerSignatures()
        let signature = explorerQuerySignature
        if browsePageSignature != pageKey(signature, page) {
            selectedRows.removeAll()
            hydratedRows.removeAll()
        }

        if let cached = pageCache[pageKey(signature, page)] {
            applyExplorerPage(cached, page: page, signature: signature)
            return
        }

        browseGeneration += 1
        let generation = browseGeneration
        let searching = isSearchActive
        isLoading = true
        isSearching = searching

        do {
            let request = explorerRequest(page: page, columns: columns)
            let result = try await DatabaseRowService.shared.explorerBrowse(request, type: database.type, serverId: serverId)
            guard generation == browseGeneration else { return }
            storeExplorerPage(result, page: page, signature: signature, columns: columns)
            applyExplorerPage(result, page: page, signature: signature)
        } catch {
            guard generation == browseGeneration else { return }
            let title = searching ? L10n.Database.searchFailed : L10n.Database.loadDataFailed
            GlobalToastManager.shared.showError("\(title): \(error.localizedDescription)")
            log(action: searching ? "Search Rows" : "Browse Rows", detail: "Table '\(table.name)'", success: false, error: error.localizedDescription)
        }
        if generation == browseGeneration {
            isLoading = false
            isSearching = false
        }
    }

    private func applyExplorerPage(_ result: QueryResult, page: Int, signature: String) {
        browseResult = result
        hasMoreRows = result.hasMore ?? false
        browsePageSignature = pageKey(signature, page)
        // Reaching the end tells us the exact total for free.
        if !hasMoreRows, !(result.rows.isEmpty && page > 0) {
            exactRowCount = Int64(page * pageSize + result.rows.count)
        }
        schedulePrefetch(page + 1)
        if page == 0 { autoCountIfCheap() }
    }

    private func storeExplorerPage(_ result: QueryResult, page: Int, signature: String, columns: [ColumnInfo]) {
        // Cursor for the next page: the last row's primary key, when complete.
        if let keyColumn = keysetColumn(columns),
           let columnIndex = result.columns.firstIndex(of: keyColumn),
           let lastIndex = result.rows.indices.last {
            let flags = result.flags(row: lastIndex, column: columnIndex)
            if flags == 0, columnIndex < result.rows[lastIndex].count {
                pageCursors[page + 1] = result.rows[lastIndex][columnIndex]
            }
        }

        let key = pageKey(signature, page)
        pageCache[key] = result
        pageCacheOrder.removeAll { $0 == key }
        pageCacheOrder.append(key)
        while pageCacheOrder.count > Self.pageCacheLimit {
            pageCache.removeValue(forKey: pageCacheOrder.removeFirst())
        }
    }

    /// Fetches the next page in the background so "Next" is instant.
    private func schedulePrefetch(_ page: Int) {
        prefetchTask?.cancel()
        guard hasMoreRows, let serverId = serverId, let columns = tableStructure?.columns else { return }
        let signature = explorerQuerySignature
        guard pageCache[pageKey(signature, page)] == nil else { return }
        let request = explorerRequest(page: page, columns: columns)
        let type = database.type

        prefetchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            guard let result = try? await DatabaseRowService.shared.explorerBrowse(request, type: type, serverId: serverId) else { return }
            guard let self, !Task.isCancelled, self.explorerQuerySignature == signature else { return }
            self.storeExplorerPage(result, page: page, signature: signature, columns: columns)
        }
    }

    /// Forgets cached pages and cursors (after any write to the table).
    func invalidateExplorerPages() {
        prefetchTask?.cancel()
        pageCache.removeAll()
        pageCacheOrder.removeAll()
        pageCursors.removeAll()
        browsePageSignature = ""
        hydratedRows.removeAll()
    }

    // MARK: - Counting

    /// Exact row count for the current table or search, on demand.
    public func countRows() async {
        guard let serverId = serverId, let table = selectedTable,
              let columns = tableStructure?.columns, !columns.isEmpty else { return }
        let signature = explorerCountSignature
        isCountingRows = true
        do {
            let count = try await DatabaseRowService.shared.explorerCount(
                explorerRequest(page: 0, columns: columns),
                type: database.type,
                serverId: serverId
            )
            if signature == explorerCountSignature {
                exactRowCount = count
                if !isSearchActive { setRowCount(count, forTable: table.name) }
            }
        } catch {
            if signature == explorerCountSignature {
                GlobalToastManager.shared.showError("\(L10n.Database.countRows): \(error.localizedDescription)")
            }
        }
        isCountingRows = false
    }

    /// Counts automatically only when the table is known to be small.
    private func autoCountIfCheap() {
        guard explorerEnabled, exactRowCount == nil, hasMoreRows, !isSearchActive, tableStatsLoaded,
              let estimate = selectedTable?.rowCount, estimate <= Self.autoCountRowLimit else { return }
        countTask?.cancel()
        countTask = Task { [weak self] in await self?.countRows() }
    }

    // MARK: - Row Counts

    func setRowCount(_ count: Int64, forTable name: String) {
        guard let index = tables.firstIndex(where: { $0.name == name }) else { return }
        tables[index].rowCount = max(0, count)
        if selectedTable?.name == name {
            selectedTable = tables[index]
        }
    }

    /// Keeps counts right after inserts/deletes without reloading every table.
    func adjustRowCount(by delta: Int64) {
        guard let table = selectedTable else { return }
        setRowCount(table.rowCount + delta, forTable: table.name)
        if !isSearchActive, let exact = exactRowCount {
            exactRowCount = max(0, exact + delta)
        } else {
            exactRowCount = nil
        }
    }

    // MARK: - Table Statistics

    /// Fills row counts and sizes after the names are on screen.
    func loadTableStatsInBackground() {
        guard let serverId = serverId else { return }
        statsTask?.cancel()
        tableStatsLoaded = false
        let databaseName = database.name
        let type = database.type

        statsTask = Task { [weak self] in
            let stats = try? await DatabaseTableService.shared.loadTableStats(database: databaseName, type: type, serverId: serverId)
            guard let self, !Task.isCancelled else { return }
            if let stats {
                let byName = Dictionary(stats.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
                self.tables = self.tables.map { table in
                    guard var merged = byName[table.name] else { return table }
                    if merged.engine.isEmpty { merged.engine = table.engine }
                    return merged
                }
                if let selected = self.selectedTable, let updated = self.tables.first(where: { $0.name == selected.name }) {
                    self.selectedTable = updated
                }
            }
            self.tableStatsLoaded = true
        }
    }

    // MARK: - On-Demand Rows

    /// Primary key (or first-column fallback) for a row on the current page.
    /// Returns nil if a key cell is only a preview.
    func rowKey(forRowAt index: Int) -> [String: String]? {
        guard let result = browseResult, index < result.rows.count else { return nil }
        let pkColumns = tableStructure?.columns.filter(\.isPrimaryKey).map(\.name) ?? []
        let keyColumns = pkColumns.isEmpty ? Array(result.columns.prefix(1)) : pkColumns

        var key: [String: String] = [:]
        for name in keyColumns {
            guard let columnIndex = result.columns.firstIndex(of: name),
                  columnIndex < result.rows[index].count else { return nil }
            let flags = result.flags(row: index, column: columnIndex)
            if flags & (BridgeQueryResult.cellTruncated | BridgeQueryResult.cellBinary) != 0 { return nil }
            key[name] = result.rows[index][columnIndex]
        }
        return key.isEmpty ? nil : key
    }

    /// Values of a row as shown (NULL → nil, binary columns omitted).
    func previewValues(forRowAt index: Int) -> [String: String?] {
        guard let result = browseResult, index < result.rows.count else { return [:] }
        var values: [String: String?] = [:]
        for (columnIndex, column) in result.columns.enumerated() {
            let flags = result.flags(row: index, column: columnIndex)
            if flags & BridgeQueryResult.cellBinary != 0 { continue }
            let raw = columnIndex < result.rows[index].count ? result.rows[index][columnIndex] : nil
            if flags & BridgeQueryResult.cellNull != 0 || (result.cellFlags == nil && raw == "NULL") {
                values[column] = .some(nil)
            } else {
                values[column] = raw
            }
        }
        return values
    }

    /// The complete values of a row, fetched from the server only when the
    /// grid holds previews.
    func completeValues(forRowAt index: Int) async -> [String: String?]? {
        guard let result = browseResult, index < result.rows.count else { return nil }
        guard explorerEnabled, result.rowIsPartial(index) else { return previewValues(forRowAt: index) }
        if let cached = hydratedRows[index] { return cached }
        guard let serverId = serverId, let columns = tableStructure?.columns, let key = rowKey(forRowAt: index) else {
            GlobalToastManager.shared.showError(L10n.Database.noPrimaryKey)
            return nil
        }

        var request = explorerRequest(page: 0, columns: columns)
        request.key = key
        let signature = browsePageSignature
        isHydratingRow = true
        defer { isHydratingRow = false }
        do {
            guard let values = try await DatabaseRowService.shared.explorerFetchRow(request, type: database.type, serverId: serverId) else {
                GlobalToastManager.shared.showError(L10n.Database.rowNoLongerExists)
                return nil
            }
            if signature == browsePageSignature { hydratedRows[index] = values }
            return values
        } catch {
            GlobalToastManager.shared.showError("\(L10n.Database.loadDataFailed): \(error.localizedDescription)")
            return nil
        }
    }

    /// The complete value of one cell (fetches the row if the cell is a preview).
    public func fullCellValue(row index: Int, column: String) async -> String? {
        guard let values = await completeValues(forRowAt: index) else { return nil }
        return values[column] ?? nil
    }

    /// Opens the add-row sheet prefilled with a complete copy of a row.
    public func duplicateRow(at index: Int) async {
        guard let values = await completeValues(forRowAt: index) else { return }
        let autoIncrement = Set(tableStructure?.columns.filter(\.isAutoIncrement).map(\.name) ?? [])
        duplicateRowValues = values.reduce(into: [String: String]()) { result, pair in
            guard !autoIncrement.contains(pair.key), let value = pair.value else { return }
            result[pair.key] = value
        }
        showAddRow = true
    }

    /// The current page with complete values, for copying and exporting.
    /// Rows holding previews are completed in a single query.
    public func completePage() async -> QueryResult? {
        guard let result = browseResult else { return nil }
        let partial = result.rows.indices.filter { result.rowIsPartial($0) && hydratedRows[$0] == nil }

        if explorerEnabled, !partial.isEmpty {
            guard let serverId = serverId, let columns = tableStructure?.columns else { return nil }
            var keys: [[String: String]] = []
            var indexByKey: [String: Int] = [:]
            for index in partial {
                guard let key = rowKey(forRowAt: index) else {
                    GlobalToastManager.shared.showError(L10n.Database.noPrimaryKey)
                    return nil
                }
                keys.append(key)
                indexByKey[Self.keySignature(key)] = index
            }

            var request = explorerRequest(page: 0, columns: columns)
            request.keys = keys
            let signature = browsePageSignature
            isHydratingRow = true
            defer { isHydratingRow = false }
            do {
                let full = try await DatabaseRowService.shared.explorerFetchRows(request, type: database.type, serverId: serverId)
                guard signature == browsePageSignature else { return nil }
                let keyColumns = Array(keys[0].keys)
                for rowIndex in full.rows.indices {
                    var values: [String: String?] = [:]
                    for (columnIndex, column) in full.columns.enumerated() {
                        let flags = full.flags(row: rowIndex, column: columnIndex)
                        if flags & BridgeQueryResult.cellBinary != 0 { continue }
                        if flags & BridgeQueryResult.cellNull != 0 {
                            values[column] = .some(nil)
                        } else {
                            values[column] = full.rows[rowIndex][columnIndex]
                        }
                    }
                    var key: [String: String] = [:]
                    for column in keyColumns { key[column] = values[column] ?? nil }
                    if let index = indexByKey[Self.keySignature(key)] {
                        hydratedRows[index] = values
                    }
                }
            } catch {
                GlobalToastManager.shared.showError("\(L10n.Database.loadDataFailed): \(error.localizedDescription)")
                return nil
            }
        }

        // Merge completed rows into a copy of the page.
        var merged = result
        for (index, values) in hydratedRows where index < merged.rows.count {
            for (columnIndex, column) in merged.columns.enumerated() {
                guard let value = values[column] else { continue }   // binary: keep placeholder
                merged.rows[index][columnIndex] = value ?? "NULL"
                if merged.cellFlags != nil {
                    merged.cellFlags?[index][columnIndex] = value == nil ? BridgeQueryResult.cellNull : 0
                }
            }
        }
        return merged
    }

    private static func keySignature(_ key: [String: String]) -> String {
        key.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "\u{1F}")
    }

    /// Binary columns are never round-tripped through the text editors.
    var binaryColumnNames: Set<String> {
        Set((tableStructure?.columns ?? []).filter { DatabaseColumnKind.isBinary($0.type) }.map(\.name))
    }
}

// MARK: - Column Kinds

enum DatabaseColumnKind {
    /// Binary/spatial types the grid shows as a size placeholder.
    static func isBinary(_ type: String) -> Bool {
        let base = type.lowercased().split(whereSeparator: { $0 == "(" || $0 == " " }).first.map(String.init) ?? ""
        return ["binary", "varbinary", "tinyblob", "blob", "mediumblob", "longblob", "bytea",
                "geometry", "point", "linestring", "polygon", "multipoint", "multilinestring",
                "multipolygon", "geometrycollection", "geomcollection"].contains(base)
    }
}

// MARK: - Table Name Filter

/// Ranks table names for a filter query: exact, prefix, word prefix, contains,
/// then names containing the query's letters in order ("usrord" → user_orders).
enum TableNameFilter {

    static func filter(_ tables: [TableInfo], query: String) -> [TableInfo] {
        let needle = normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return tables }

        var ranked: [(rank: Int, index: Int)] = []
        ranked.reserveCapacity(tables.count)
        for (index, table) in tables.enumerated() {
            if let rank = rank(normalize(table.name), needle) {
                ranked.append((rank, index))
            }
        }
        ranked.sort { $0.rank != $1.rank ? $0.rank < $1.rank : $0.index < $1.index }
        return ranked.map { tables[$0.index] }
    }

    private static func normalize(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    private static func rank(_ name: String, _ needle: String) -> Int? {
        if name == needle { return 0 }
        if name.hasPrefix(needle) { return 1 }
        if let range = name.range(of: needle) {
            let before = range.lowerBound == name.startIndex ? nil : name[name.index(before: range.lowerBound)]
            if let before, "_-. ".contains(before) { return 2 }
            return 3
        }
        var remaining = needle[...]
        for character in name where character == remaining.first {
            remaining = remaining.dropFirst()
            if remaining.isEmpty { return 4 }
        }
        return nil
    }
}
