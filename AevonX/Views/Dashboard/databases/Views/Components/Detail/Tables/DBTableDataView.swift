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
    @State private var hoveredRow: Int? = nil
    @State private var copiedCell: String? = nil
    @State private var jsonViewerContent: String? = nil
    @State private var showJSONViewer = false
    @State private var hiddenColumns: Set<String> = []
    @State private var jumpToPageText = ""

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

    private var loadingState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading data...")
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axAccentBlue.opacity(0.05))
                    .frame(width: 64, height: 64)
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundColor(.axTextMuted.opacity(0.4))
            }
            Text("No Data")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.axTextPrimary)
            Text("This table is empty")
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
            Button {
                viewModel.showAddRow = true
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text("Insert First Row")
                        .font(.system(size: 12, weight: .semibold))
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

    private var dataToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                // Search
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    TextField("Search rows...", text: $viewModel.dataSearchText)
                        .font(.system(size: 12))
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(.plain)
                    if viewModel.isSearching {
                        ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
                    }
                    if !viewModel.dataSearchText.isEmpty {
                        Button { Task { await viewModel.clearSearch() } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
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
                            .font(.system(size: 9))
                        Text("\(displayCount) rows")
                    }
                    .font(.system(size: 10, weight: .medium))
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
                        viewModel.activeAlert = .confirmDeleteSelectedRows
                    } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Delete \(viewModel.selectedRows.count)")
                                .font(.system(size: 11, weight: .semibold))
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
                            .font(.system(size: 10))
                        Text("Add Row")
                            .font(.system(size: 11, weight: .semibold))
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
                        AXMenuSection("Data", items: [
                            AXMenuItem("Copy as CSV", icon: "tablecells", color: .axAccentBlue) {
                                let csv = exportCSV(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(csv, forType: .string)
                                GlobalToastManager.shared.showSuccess("Copied \(result.rows.count) rows as CSV")
                            },
                            AXMenuItem("Copy as JSON", icon: "curlybraces", color: .orange) {
                                let json = exportJSON(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(json, forType: .string)
                                GlobalToastManager.shared.showSuccess("Copied \(result.rows.count) rows as JSON")
                            },
                        ]),
                        AXMenuSection("SQL", items: [
                            AXMenuItem("Copy as SQL INSERT", icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                                let sql = exportSQL(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(sql, forType: .string)
                                GlobalToastManager.shared.showSuccess("Copied \(result.rows.count) rows as SQL INSERT")
                            },
                            AXMenuItem("Copy as Markdown", icon: "text.document", color: .purple) {
                                let md = exportMarkdown(result)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(md, forType: .string)
                                GlobalToastManager.shared.showSuccess("Copied as Markdown table")
                            },
                        ]),
                    ], triggerIcon: "square.and.arrow.up", triggerSize: 26)
                }

                // Page size
                HStack(spacing: AXSpacing.xs) {
                    Text("Rows:")
                        .font(.system(size: 10))
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
                        .font(.system(size: 11))
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
                        GlobalToastManager.shared.showSuccess("SELECT query copied")
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
                        viewModel.activeAlert = .confirmTruncateTable(tbl)
                    },
                    onDrop: {
                        if let table = viewModel.selectedTable {
                            viewModel.activeAlert = .confirmDropTable(table.name)
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
            await viewModel.searchData()
        }
        .sheet(isPresented: $viewModel.showRenameTable) {
            DBRenameTableView(viewModel: viewModel)
        }
    }

    private func sortIndicator(_ sortCol: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Text("Sorted:")
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
            Text(sortCol)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.axAccentBlue)
            Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                .font(.system(size: 8))
                .foregroundColor(.axAccentBlue)
            Button {
                viewModel.sortColumn = nil
                viewModel.currentPage = 0
                Task { await viewModel.loadTableData() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 9))
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

    private func dataTable(_ result: QueryResult) -> some View {
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
                                .font(.system(size: 11))
                                .foregroundColor(.axAccentBlue)
                        }
                        .buttonStyle(.plain)
                        .frame(width: checkW, height: 32)

                        Text("#")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.axTextMuted)
                            .frame(width: numW, height: 32)

                        ForEach(visibleCols, id: \.self) { col in
                            Button {
                                Task { await viewModel.sortBy(col) }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: columnTypeIcon(col))
                                        .font(.system(size: 8))
                                        .foregroundColor(columnTypeColor(col))

                                    Text(col)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.axTextSecondary)
                                        .lineLimit(1)

                                    if isPrimaryKey(col) {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 7))
                                            .foregroundColor(.axWarning)
                                    }

                                    if viewModel.sortColumn == col {
                                        Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 7))
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
                                        AXMenuItem("Hide Column", icon: "eye.slash", color: .axTextMuted) {
                                            hiddenColumns.insert(col)
                                        },
                                    ]
                                    if !hiddenColumns.isEmpty {
                                        items.append(AXMenuItem("Show All Columns", icon: "eye", color: .axAccentBlue) {
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

    // MARK: - Data Row

    private func dataRow(
        index: Int, row: [String], columns: [String],
        visibleCols: [String],
        checkW: CGFloat, numW: CGFloat,
        colW: CGFloat, actW: CGFloat
    ) -> some View {
        let isSelected = viewModel.selectedRows.contains(index)
        let isHovered = hoveredRow == index
        return HStack(spacing: 0) {
            // Checkbox
            Button {
                viewModel.toggleRowSelection(index)
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted.opacity(0.4))
            }
            .buttonStyle(.plain)
            .frame(width: checkW, height: 30)

            // Row number
            Text("\(index + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted.opacity(0.5))
                .frame(width: numW, height: 30)

            // Cell values
            ForEach(visibleCols, id: \.self) { colName in
                let colIdx = columns.firstIndex(of: colName) ?? 0
                let value = colIdx < row.count ? row[colIdx] : ""
                cellView(value: value, columnName: colName)
                    .frame(width: colW, height: 30, alignment: .leading)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(value, forType: .string)
                        copiedCell = "\(index)-\(colIdx)"
                        GlobalToastManager.shared.showSuccess("Copied: \(value.prefix(30))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if copiedCell == "\(index)-\(colIdx)" { copiedCell = nil }
                        }
                    }
            }

            // Row actions — AXActionMenu
            AXActionMenu(sections: [
                AXMenuSection("Actions", items: [
                    AXMenuItem("Edit Row", icon: "pencil", color: .axAccentBlue) {
                        viewModel.startEditingRow(index)
                    },
                ]),
                AXMenuSection("Copy", items: [
                    AXMenuItem("Copy Row Values", icon: "doc.on.doc", color: .cyan) {
                        let values = row.joined(separator: "\t")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(values, forType: .string)
                        GlobalToastManager.shared.showSuccess("Row values copied")
                    },
                    AXMenuItem("Copy as INSERT", icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                        let insert = generateInsertStatement(columns: columns, row: row)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(insert, forType: .string)
                        GlobalToastManager.shared.showSuccess("INSERT statement copied")
                    },
                    AXMenuItem("Copy as UPDATE", icon: "arrow.triangle.2.circlepath", color: .orange) {
                        let update = generateUpdateStatement(columns: columns, row: row)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(update, forType: .string)
                        GlobalToastManager.shared.showSuccess("UPDATE statement copied")
                    },
                ]),
                AXMenuSection("Management", items: [
                    AXMenuItem("Duplicate Row", icon: "plus.square.on.square", color: .purple) {
                        viewModel.showAddRow = true
                    },
                ]),
                AXMenuSection(items: [
                    AXMenuItem("Delete Row", icon: "trash", isDestructive: true) {
                        viewModel.activeAlert = .confirmDeleteRow(index)
                    },
                ]),
            ], triggerIcon: "ellipsis", triggerSize: 22)
            .frame(width: actW, height: 30)
        }
        .background(
            isSelected
                ? Color.axAccentBlue.opacity(0.08)
                : (isHovered
                    ? Color.axSurface.opacity(0.5)
                    : (index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.15)))
        )
        .onHover { hovering in
            hoveredRow = hovering ? index : nil
        }
    }

    // MARK: - Cell View

    private func cellView(value: String, columnName: String) -> some View {
        Group {
            if value == "NULL" || value.isEmpty {
                Text("NULL")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted.opacity(0.5))
                    .italic()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(2)
            } else if isJSONValue(value) {
                // JSON cell — clickable to open viewer
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 8))
                        .foregroundColor(.axInfo)
                    Text(value.prefix(40) + (value.count > 40 ? "..." : ""))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axInfo)
                        .lineLimit(1)
                }
                .onTapGesture {
                    jsonViewerContent = formatJSON(value)
                    showJSONViewer = true
                }
            } else if isURLValue(value) {
                // URL cell — clickable link
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "link")
                        .font(.system(size: 8))
                        .foregroundColor(.axAccentBlue)
                    Text(value)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                        .underline()
                        .lineLimit(1)
                }
                .onTapGesture {
                    if let url = URL(string: value) {
                        NSWorkspace.shared.open(url)
                    }
                }
            } else if value == "true" || value == "false" || value == "1" || value == "0" {
                // Boolean display
                let isTrue = value == "true" || value == "1"
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: isTrue ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(isTrue ? .axAccentGreen : .axTextMuted)
                    Text(value)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(isTrue ? .axAccentGreen : .axTextMuted)
                }
            } else if Int(value) != nil || Double(value) != nil {
                Text(value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
                    .lineLimit(1)
            } else if value.count > 80 {
                // Long text truncation
                Text(value.prefix(80) + "...")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                    .help(String(value.prefix(500)))
            } else {
                Text(value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Pagination

    private var paginationBar: some View {
        HStack(spacing: AXSpacing.md) {
            // Info text
            if let result = viewModel.browseResult {
                let offset = viewModel.currentPage * viewModel.pageSize
                let end = offset + result.rows.count
                let total = Int(viewModel.selectedTable?.rowCount ?? Int64(end))
                Text("Showing \(offset + 1)-\(end) of \(total) rows")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                Button {
                    viewModel.currentPage = 0
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.left.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                Button {
                    Task { await viewModel.previousPage() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                // Page display with jump-to-page
                HStack(spacing: AXSpacing.xxs) {
                    Text("Page")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    TextField("", text: $jumpToPageText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .frame(width: 30)
                        .onAppear { jumpToPageText = "\(viewModel.currentPage + 1)" }
                        .onChange(of: viewModel.currentPage) { _, _ in jumpToPageText = "\(viewModel.currentPage + 1)" }
                        .onSubmit {
                            if let page = Int(jumpToPageText), page >= 1, page <= viewModel.totalPages {
                                viewModel.currentPage = page - 1
                                Task { await viewModel.loadTableData() }
                            } else {
                                jumpToPageText = "\(viewModel.currentPage + 1)"
                            }
                        }
                    Text("of \(viewModel.totalPages)")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 3)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)

                Button {
                    Task { await viewModel.nextPage() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)

                Button {
                    viewModel.currentPage = max(0, viewModel.totalPages - 1)
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)
            }
            .foregroundColor(.axAccentBlue)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }

    // MARK: - Column Type Helpers

    private func columnTypeIcon(_ col: String) -> String {
        guard let structure = viewModel.tableStructure,
              let colInfo = structure.columns.first(where: { $0.name == col }) else {
            return "textformat"
        }
        let t = colInfo.type.uppercased()
        if t.contains("INT") || t.contains("DECIMAL") || t.contains("FLOAT") || t.contains("DOUBLE") {
            return "number"
        }
        if t.contains("VARCHAR") || t.contains("CHAR") || t.contains("TEXT") {
            return "textformat"
        }
        if t.contains("DATE") || t.contains("TIME") || t.contains("YEAR") {
            return "calendar"
        }
        if t.contains("JSON") { return "curlybraces" }
        if t.contains("BOOL") { return "switch.2" }
        if t.contains("BLOB") { return "doc" }
        return "textformat"
    }

    private func columnTypeColor(_ col: String) -> Color {
        guard let structure = viewModel.tableStructure,
              let colInfo = structure.columns.first(where: { $0.name == col }) else {
            return .axTextMuted
        }
        let t = colInfo.type.uppercased()
        if t.contains("INT") || t.contains("DECIMAL") || t.contains("FLOAT") || t.contains("DOUBLE") {
            return .axAccentBlue
        }
        if t.contains("VARCHAR") || t.contains("CHAR") || t.contains("TEXT") {
            return .axAccentGreen
        }
        if t.contains("DATE") || t.contains("TIME") || t.contains("YEAR") {
            return .axWarning
        }
        if t.contains("JSON") || t.contains("BLOB") { return .axInfo }
        if t.contains("BOOL") { return .axError }
        return .axTextMuted
    }

    private func isPrimaryKey(_ col: String) -> Bool {
        guard let structure = viewModel.tableStructure else { return false }
        return structure.columns.first(where: { $0.name == col })?.isPrimaryKey ?? false
    }

    private func columnTypeTooltip(_ col: String) -> String {
        guard let structure = viewModel.tableStructure,
              let colInfo = structure.columns.first(where: { $0.name == col }) else {
            return col
        }
        var parts = [colInfo.type]
        if colInfo.isPrimaryKey { parts.append("PRIMARY KEY") }
        if !colInfo.isNullable { parts.append("NOT NULL") }
        if !colInfo.defaultValue.isEmpty { parts.append("DEFAULT \(colInfo.defaultValue)") }
        return parts.joined(separator: " | ")
    }

    // MARK: - Value Detection Helpers

    private func isJSONValue(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) ||
               (trimmed.hasPrefix("[") && trimmed.hasSuffix("]"))
    }

    private func isURLValue(_ value: String) -> Bool {
        return value.hasPrefix("http://") || value.hasPrefix("https://")
    }

    private func formatJSON(_ value: String) -> String {
        guard let data = value.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else {
            return value
        }
        return str
    }

    // MARK: - Row SQL Generators

    private func generateInsertStatement(columns: [String], row: [String]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let cols = columns.map { "`\($0)`" }.joined(separator: ", ")
        let vals = row.map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" }.joined(separator: ", ")
        return "INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals));"
    }

    private func generateUpdateStatement(columns: [String], row: [String]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        var sets: [String] = []
        var wheres: [String] = []
        for (i, col) in columns.enumerated() {
            let val = i < row.count ? row[i] : ""
            sets.append("`\(col)` = '\(val.replacingOccurrences(of: "'", with: "''"))'")
            if isPrimaryKey(col) {
                wheres.append("`\(col)` = '\(val.replacingOccurrences(of: "'", with: "''"))'")
            }
        }
        let whereClause = wheres.isEmpty ? "WHERE 1=1 /* add condition */" : "WHERE \(wheres.joined(separator: " AND "))"
        return "UPDATE `\(tableName)` SET \(sets.joined(separator: ", ")) \(whereClause);"
    }

    // MARK: - JSON Viewer Sheet

    private var jsonViewerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JSON Viewer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button {
                    if let content = jsonViewerContent {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(content, forType: .string)
                        GlobalToastManager.shared.showSuccess("JSON copied")
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
                Button { showJSONViewer = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)

            ScrollView {
                Text(jsonViewerContent ?? "")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .textSelection(.enabled)
                    .padding(AXSpacing.md)
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .padding(.horizontal, AXSpacing.md)
            .padding(.bottom, AXSpacing.md)
        }
        .frame(width: 500, height: 400)
        .background(Color.axBackground)
    }

    // MARK: - Export Helpers

    private func exportCSV(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append(result.columns.joined(separator: ","))
        for row in result.rows {
            let escaped = row.map { v -> String in
                if v.contains(",") || v.contains("\"") || v.contains("\n") {
                    return "\"\(v.replacingOccurrences(of: "\"", with: "\"\""))\""
                }
                return v
            }
            lines.append(escaped.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func exportJSON(_ result: QueryResult) -> String {
        var lines: [String] = ["["]
        for (idx, row) in result.rows.enumerated() {
            var pairs: [String] = []
            for (i, col) in result.columns.enumerated() {
                let val = i < row.count ? row[i] : ""
                pairs.append("    \"\(col)\": \"\(val.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            let comma = idx < result.rows.count - 1 ? "," : ""
            lines.append("  {\n\(pairs.joined(separator: ",\n"))\n  }\(comma)")
        }
        lines.append("]")
        return lines.joined(separator: "\n")
    }

    private func exportSQL(_ result: QueryResult) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        var statements: [String] = []
        for row in result.rows {
            let vals = row.map { v -> String in
                return "'\(v.replacingOccurrences(of: "'", with: "''"))'"
            }
            let cols = result.columns.map { "`\($0)`" }.joined(separator: ", ")
            statements.append("INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals.joined(separator: ", ")));")
        }
        return statements.joined(separator: "\n")
    }

    private func exportMarkdown(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append("| " + result.columns.joined(separator: " | ") + " |")
        lines.append("| " + result.columns.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in result.rows {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }
}
