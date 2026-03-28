//
//  DBTableDataView.swift
//  AevonX
//
//  Premium data table with type-colored column headers,
//  row numbers, hover effects, copy-on-click cells,
//  NULL badges, and enhanced toolbar/pagination.
//

import SwiftUI
import AevonXCoreBridge

struct DBTableDataView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State var hoveredRow: Int? = nil
    @State var copiedCell: String? = nil
    @State var jsonViewerContent: String? = nil
    @State var showJSONViewer = false
    @State private var hiddenColumns: Set<String> = []
    @State var jumpToPageText = ""

    var body: some View {
        VStack(spacing: 0) {
            dataToolbar
            Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1)

            if viewModel.isLoading && viewModel.browseResult == nil {
                loadingState
            } else if let result = viewModel.browseResult {
                if result.rows.isEmpty {
                    emptyState
                } else {
                    dataTable(result)
                }
            } else {
                emptyState
            }

            if viewModel.browseResult?.rows.isEmpty == false {
                Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1)
                paginationBar
            }
        }
        .sheet(isPresented: $showJSONViewer) {
            jsonViewerSheet
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if viewModel.tableStructure == nil {
                await viewModel.loadTableStructure()
            }
            if viewModel.browseResult == nil {
                await viewModel.loadTableData()
            }
        }
    }

    // MARK: - Loading State

    var loadingState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text(L10n.Status.loading)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axAccentBlue.opacity(0.05))
                    .frame(width: 64, height: 64)
                Image(systemName: "tray")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextMuted.opacity(0.4))
            }
            Text(L10n.Database.noData)
                .font(AXTypography.title3).fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text(L10n.Database.tableIsEmpty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Button {
                viewModel.showAddRow = true
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus")
                        .font(AXTypography.caption)
                    Text(L10n.Database.insertFirstRow)
                        .font(AXTypography.subheadline).fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentGreen)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Toolbar

    var dataToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                // Search
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextMuted)
                    TextField(L10n.Database.searchRows, text: $viewModel.dataSearchText)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(.plain)
                    if viewModel.isSearching {
                        ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
                    }
                    if !viewModel.dataSearchText.isEmpty {
                        Button { Task { await viewModel.clearSearch() } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs + 1)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                )
                .frame(maxWidth: 220)

                // Row count badge
                if let result = viewModel.browseResult {
                    let tableCount = Int(viewModel.selectedTable?.rowCount ?? 0)
                    let displayCount = tableCount > 0 ? tableCount : result.rows.count
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "number")
                            .font(AXTypography.caption2)
                        Text(L10n.Database.rowCountDisplay(displayCount))
                    }
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 3)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }

                // Sort indicator
                if let sortCol = viewModel.sortColumn {
                    sortIndicator(sortCol)
                }

                Spacer()

                // Delete selected
                if !viewModel.selectedRows.isEmpty {
                    Button {
                        if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmDeleteDBRow) {
                            viewModel.activeAlert = .confirmDeleteSelectedRows
                        } else {
                            Task { await viewModel.deleteSelectedRows() }
                        }
                    } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "trash")
                                .font(AXTypography.caption)
                            Text(L10n.Database.deleteCount(viewModel.selectedRows.count))
                                .font(AXTypography.footnote).fontWeight(.semibold)
                        }
                        .foregroundColor(.axError)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }

                // Add Row button
                Button { viewModel.showAddRow = true } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(AXTypography.caption)
                        Text(L10n.Database.addRow)
                            .font(AXTypography.footnote).fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentGreen)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentGreen.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Export
                if let result = viewModel.browseResult, !result.rows.isEmpty {
                    AXActionMenu(sections: [
                        AXMenuSection(L10n.Database.data, items: [
                            AXMenuItem(L10n.Database.copyAsCSV, icon: "tablecells", color: .axAccentBlue) {
                                let csv = exportCSV(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(csv, forType: .string)
                                GlobalToastManager.shared.showSuccess(L10n.Database.copiedRowsAsCSV(result.rows.count))
                            },
                            AXMenuItem(L10n.Database.copyAsJSON, icon: "curlybraces", color: .orange) {
                                let json = exportJSON(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(json, forType: .string)
                                GlobalToastManager.shared.showSuccess(L10n.Database.copiedRowsAsJSON(result.rows.count))
                            },
                        ]),
                        AXMenuSection("SQL", items: [
                            AXMenuItem(L10n.Database.copyAsSQLInsert, icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                                let sql = exportSQL(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(sql, forType: .string)
                                GlobalToastManager.shared.showSuccess(L10n.Database.copiedRowsAsSQLInsert(result.rows.count))
                            },
                            AXMenuItem(L10n.Database.copyAsMarkdown, icon: "text.document", color: .purple) {
                                let md = exportMarkdown(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(md, forType: .string)
                                GlobalToastManager.shared.showSuccess(L10n.Database.copiedAsMarkdownTable)
                            },
                        ]),
                    ], triggerIcon: "square.and.arrow.up", triggerSize: 26)
                }

                // Page size
                HStack(spacing: AXSpacing.xs) {
                    Text(L10n.Database.rowsPerPage)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: Binding(
                        get: { viewModel.pageSize },
                        set: { newSize in
                            viewModel.pageSize = newSize
                            viewModel.currentPage = 0
                            Task { await viewModel.loadTableData() }
                        }
                    )) {
                        Text("25").tag(25)
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .labelsHidden()
                    .frame(width: 65)
                }

                // Refresh
                Button {
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 26, height: 26)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

                // Table Actions Menu — AXActionMenu popover
                AXActionMenu.databaseTableActions(
                    onRename: {
                        viewModel.showRenameTable = true
                    },
                    onShowCreate: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        viewModel.queryText = "SHOW CREATE TABLE `\(tbl)`"
                        viewModel.currentSection = .queryConsole
                        Task { await viewModel.executeQuery() }
                    },
                    onOptimize: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        viewModel.queryText = "OPTIMIZE TABLE `\(tbl)`"
                        viewModel.currentSection = .queryConsole
                        Task { await viewModel.executeQuery() }
                    },
                    onCheck: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        viewModel.queryText = "CHECK TABLE `\(tbl)`"
                        viewModel.currentSection = .queryConsole
                        Task { await viewModel.executeQuery() }
                    },
                    onRepair: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        viewModel.queryText = "REPAIR TABLE `\(tbl)`"
                        viewModel.currentSection = .queryConsole
                        Task { await viewModel.executeQuery() }
                    },
                    onCopySelect: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        let sql = "SELECT * FROM `\(tbl)` LIMIT 100"
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(sql, forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.selectQueryCopied)
                    },
                    onDescribe: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        viewModel.queryText = "DESCRIBE `\(tbl)`"
                        viewModel.currentSection = .queryConsole
                        Task { await viewModel.executeQuery() }
                    },
                    onTruncate: {
                        let tbl = viewModel.selectedTable?.name ?? ""
                        viewModel.queryText = "TRUNCATE TABLE `\(tbl)`"
                        viewModel.confirmTruncateTable(tbl)
                    },
                    onDrop: {
                        if let table = viewModel.selectedTable {
                            viewModel.confirmDropTable(table.name)
                        }
                    }
                )
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
        }
        .task(id: viewModel.dataSearchText) {
            guard !viewModel.dataSearchText.isEmpty else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            viewModel.currentPage = 0
            await viewModel.searchData()
        }
        .sheet(isPresented: $viewModel.showRenameTable) {
            DBRenameTableView(viewModel: viewModel)
        }
    }

    func sortIndicator(_ sortCol: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Text(L10n.Database.sorted)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(sortCol)
                .font(AXTypography.monoXs).fontWeight(.semibold)
                .foregroundColor(.axAccentBlue)
            Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                .font(AXTypography.caption2)
                .foregroundColor(.axAccentBlue)
            Button {
                viewModel.sortColumn = nil
                viewModel.currentPage = 0
                Task { await viewModel.loadTableData() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 3)
        .background(Color.axAccentBlue.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }

    // MARK: - Data Table

    func dataTable(_ result: QueryResult) -> some View {
        let visibleCols = result.columns.filter { !hiddenColumns.contains($0) }
        return GeometryReader { geo in
            let totalW = geo.size.width
            let checkW: CGFloat = 36
            let numW: CGFloat = 44
            let actW: CGFloat = 72
            let fixedW = checkW + numW + actW
            let colCount = max(CGFloat(visibleCols.count), 1)
            let contentMinW = max(totalW, colCount * 150 + fixedW)
            let colW = max((contentMinW - fixedW) / colCount, 100)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // ── Column Headers ──
                    HStack(spacing: 0) {
                        Button {
                            if viewModel.selectedRows.count == result.rows.count {
                                viewModel.deselectAllRows()
                            } else {
                                viewModel.selectAllRows()
                            }
                        } label: {
                            Image(systemName: viewModel.selectedRows.count == result.rows.count && !result.rows.isEmpty
                                  ? "checkmark.square.fill" : "square")
                                .font(AXTypography.footnote)
                                .foregroundColor(.axAccentBlue)
                        }
                        .buttonStyle(.plain)
                        .frame(width: checkW, height: 32)

                        Text("#")
                            .font(AXTypography.caption).fontWeight(.bold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: numW, height: 32)

                        ForEach(visibleCols, id: \.self) { col in
                            Button {
                                Task { await viewModel.sortBy(col) }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: columnTypeIcon(col))
                                        .font(AXTypography.caption2)
                                        .foregroundColor(columnTypeColor(col))

                                    Text(col)
                                        .font(AXTypography.footnote).fontWeight(.bold)
                                        .foregroundColor(.axTextSecondary)
                                        .lineLimit(1)

                                    if isPrimaryKey(col) {
                                        Image(systemName: "key.fill")
                                            .font(AXTypography.caption2)
                                            .foregroundColor(.axWarning)
                                    }

                                    if viewModel.sortColumn == col {
                                        Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                            .font(AXTypography.caption2)
                                            .foregroundColor(.axAccentBlue)
                                    }

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: colW, height: 32)
                            .padding(.horizontal, 6)
                            .help(columnTypeTooltip(col))

                            AXActionMenu(sections: [
                                AXMenuSection(items: {
                                    var items: [AXMenuItem] = [
                                        AXMenuItem(L10n.Database.hideColumn, icon: "eye.slash", color: .axTextMuted) {
                                            hiddenColumns.insert(col)
                                        },
                                    ]
                                    if !hiddenColumns.isEmpty {
                                        items.append(AXMenuItem(L10n.Database.showAllColumns, icon: "eye", color: .axAccentBlue) {
                                            hiddenColumns.removeAll()
                                        })
                                    }
                                    return items
                                }()),
                            ], triggerIcon: "chevron.down", triggerSize: 14)
                        }

                        Spacer().frame(width: actW)
                    }
                    .frame(minWidth: contentMinW)
                    .background(Color.axSurface.opacity(0.6))

                    Rectangle().fill(Color.axBorder.opacity(0.4)).frame(height: 1)

                    // ── Data Rows ──
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                                dataRow(
                                    index: index, row: row,
                                    columns: result.columns,
                                    visibleCols: visibleCols,
                                    checkW: checkW, numW: numW,
                                    colW: colW, actW: actW
                                )
                                if index < result.rows.count - 1 {
                                    Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: contentMinW)
            }
        }
    }


    // Data row, cell view, pagination, column helpers, value detection,
    // SQL generators, JSON viewer, export → DBTableDataView+Helpers.swift
}
