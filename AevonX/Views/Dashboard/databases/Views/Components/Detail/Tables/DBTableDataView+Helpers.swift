//
//  DBTableDataView+Helpers.swift
//  AevonX
//
//  Data row rendering, cell views, pagination, column type helpers,
//  value detection, SQL generators, JSON viewer, and export helpers.
//

import SwiftUI
import AevonXCoreBridge

extension DBTableDataView {
    // MARK: - Data Row

    func dataRow(
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
                    .font(AXTypography.footnote)
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted.opacity(0.4))
            }
            .buttonStyle(.plain)
            .frame(width: checkW, height: 30)

            // Row number (global, not page-local)
            Text("\(viewModel.currentPage * viewModel.pageSize + index + 1)")
                .font(AXTypography.monoXs)
                .foregroundColor(.axTextMuted.opacity(0.5))
                .frame(width: numW, height: 30)

            // Cell values
            ForEach(visibleCols, id: \.self) { colName in
                let colIdx = columns.firstIndex(of: colName) ?? 0
                let value = colIdx < row.count ? row[colIdx] : ""
                let flags: UInt8? = viewModel.browseResult?.cellFlags == nil
                    ? nil
                    : viewModel.browseResult?.flags(row: index, column: colIdx)
                cellView(value: value, columnName: colName, flags: flags)
                    .frame(width: colW, height: 30, alignment: .leading)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cellTapped(index: index, column: colName, columnIndex: colIdx, value: value, flags: flags ?? 0)
                    }
            }

            // Row actions — AXActionMenu
            AXActionMenu(sections: [
                AXMenuSection(L10n.Database.actions, items: [
                    AXMenuItem(L10n.Database.editRow, icon: "pencil", color: .axAccentBlue) {
                        viewModel.startEditingRow(index)
                    },
                ]),
                AXMenuSection(L10n.Button.copy, items: [
                    AXMenuItem(L10n.Database.copyRowValues, icon: "doc.on.doc", color: .cyan) {
                        Task {
                            guard let values = await viewModel.completeValues(forRowAt: index) else { return }
                            let line = columns.map { values[$0].map { $0 ?? "NULL" } ?? "" }.joined(separator: "\t")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(line, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.rowValuesCopied)
                        }
                    },
                    AXMenuItem(L10n.Database.copyAsINSERT, icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                        Task {
                            guard let values = await viewModel.completeValues(forRowAt: index) else { return }
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(generateInsertStatement(columns: columns, values: values), forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.insertCopied)
                        }
                    },
                    AXMenuItem(L10n.Database.copyAsUPDATE, icon: "arrow.triangle.2.circlepath", color: .orange) {
                        Task {
                            guard let values = await viewModel.completeValues(forRowAt: index) else { return }
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(generateUpdateStatement(columns: columns, values: values), forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.updateCopied)
                        }
                    },
                ]),
                AXMenuSection(L10n.Database.maintenance, items: [
                    AXMenuItem(L10n.Database.duplicateRowAction, icon: "plus.square.on.square", color: .purple) {
                        // Pre-populate the add row form with this row's complete values
                        Task { await viewModel.duplicateRow(at: index) }
                    },
                ]),
                AXMenuSection(items: [
                    AXMenuItem(L10n.Database.deleteRowAction, icon: "trash", isDestructive: true) {
                        if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmDeleteDBRow) {
                            viewModel.activeAlert = .confirmDeleteRow(index)
                        } else {
                            Task { await viewModel.deleteRow(at: index) }
                        }
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

    // MARK: - Cell Tap

    /// Previews open the complete value; other cells are copied.
    func cellTapped(index: Int, column: String, columnIndex: Int, value: String, flags: UInt8) {
        if flags & BridgeQueryResult.cellBinary != 0 { return }
        if flags & BridgeQueryResult.cellTruncated != 0 {
            Task {
                guard let full = await viewModel.fullCellValue(row: index, column: column) else { return }
                jsonViewerContent = isJSONValue(full) ? formatJSON(full) : full
                showJSONViewer = true
            }
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copiedCell = "\(index)-\(columnIndex)"
        GlobalToastManager.shared.showSuccess(L10n.Database.copiedPrefix(String(value.prefix(30))))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if copiedCell == "\(index)-\(columnIndex)" { copiedCell = nil }
        }
    }

    // MARK: - Cell View

    /// `flags` is nil for results without per-cell flags (legacy engines),
    /// where the literal text "NULL" is the only NULL signal.
    func cellView(value: String, columnName: String, flags: UInt8?) -> some View {
        let isNull = flags.map { $0 & BridgeQueryResult.cellNull != 0 } ?? (value == "NULL")
        let isBinary = (flags ?? 0) & BridgeQueryResult.cellBinary != 0
        let isPreview = (flags ?? 0) & BridgeQueryResult.cellTruncated != 0
        return Group {
            if isBinary {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "doc.zipper")
                        .font(AXTypography.caption2)
                    Text(L10n.Database.binaryValue(AXFormatter.formatBytes(Int64(value) ?? 0)))
                        .font(AXTypography.monoXs)
                }
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.xs)
            } else if isPreview {
                HStack(spacing: AXSpacing.xxs) {
                    Text(value.prefix(80))
                        .font(AXTypography.monoSm)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    Image(systemName: "ellipsis.rectangle")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axAccentBlue)
                }
                .help(L10n.Database.previewCellHint)
            } else if isNull {
                Text(L10n.Literal.null)
                    .font(AXTypography.monoXs).fontWeight(.medium)
                    .foregroundColor(.axTextMuted.opacity(0.5))
                    .italic()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(AXCornerRadius.xs)
            } else if value.isEmpty {
                Text("(\(L10n.Database.emptyValue.lowercased()))")
                    .font(AXTypography.monoXs).fontWeight(.medium)
                    .foregroundColor(.axTextMuted.opacity(0.35))
                    .italic()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
            } else if isJSONValue(value) {
                // JSON cell — clickable to open viewer
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "curlybraces")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axInfo)
                    Text(value.prefix(40) + (value.count > 40 ? "..." : ""))
                        .font(AXTypography.monoSm)
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
                        .font(AXTypography.caption2)
                        .foregroundColor(.axAccentBlue)
                    Text(value)
                        .font(AXTypography.monoSm)
                        .foregroundColor(.axAccentBlue)
                        .underline()
                        .lineLimit(1)
                }
                .onTapGesture {
                    if let url = URL(string: value) {
                        NSWorkspace.shared.open(url)
                    }
                }
            } else if value == "true" || value == "false" || ((value == "1" || value == "0") && isBooleanColumn(columnName)) {
                // Boolean display — only show icons for actual boolean/bit columns
                let isTrue = value == "true" || value == "1"
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: isTrue ? "checkmark.circle.fill" : "xmark.circle")
                        .font(AXTypography.caption)
                        .foregroundColor(isTrue ? .axAccentGreen : .axTextMuted)
                    Text(value)
                        .font(AXTypography.monoSm)
                        .foregroundColor(isTrue ? .axAccentGreen : .axTextMuted)
                }
            } else if Int(value) != nil || Double(value) != nil {
                Text(value)
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axAccentBlue)
                    .lineLimit(1)
            } else if value.count > 80 {
                // Long text truncation
                Text(value.prefix(80) + "...")
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                    .help(String(value.prefix(500)))
            } else {
                Text(value)
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Pagination

    var paginationBar: some View {
        HStack(spacing: AXSpacing.md) {
            // Info text
            if let result = viewModel.browseResult {
                let offset = viewModel.currentPage * viewModel.pageSize
                let end = offset + result.rows.count
                Group {
                    if let total = viewModel.displayedRowTotal {
                        Text(viewModel.isRowTotalExact
                             ? L10n.Database.showingRows(offset + 1, end, Int(total))
                             : L10n.Database.showingRowsEstimated(offset + 1, end, Int(total)))
                    } else {
                        Text(L10n.Database.showingRowsOpen(offset + 1, end))
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            }

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                Button {
                    viewModel.currentPage = 0
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.left.2")
                        .font(AXTypography.caption)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                Button {
                    Task { await viewModel.previousPage() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(AXTypography.footnote)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                // Page display with jump-to-page
                HStack(spacing: AXSpacing.xxs) {
                    Text(L10n.Database.pageLabel)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    TextField("", text: $jumpToPageText)
                        .font(AXTypography.monoSm).fontWeight(.medium)
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
                    Text(viewModel.isRowTotalExact
                         ? L10n.Database.ofTotalPages(viewModel.totalPages)
                         : L10n.Database.ofTotalPagesEstimated(viewModel.totalPages))
                        .font(AXTypography.caption)
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
                        .font(AXTypography.footnote)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)

                Button {
                    viewModel.currentPage = max(0, viewModel.totalPages - 1)
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.right.2")
                        .font(AXTypography.caption)
                }
                .buttonStyle(.plain)
                // The last page is only reachable once the total is exact.
                .disabled(!viewModel.hasNextPage || !viewModel.isRowTotalExact)
            }
            .foregroundColor(.axAccentBlue)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }

    // MARK: - Column Type Helpers

    func columnTypeIcon(_ col: String) -> String {
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

    func columnTypeColor(_ col: String) -> Color {
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

    func isPrimaryKey(_ col: String) -> Bool {
        guard let structure = viewModel.tableStructure else { return false }
        return structure.columns.first(where: { $0.name == col })?.isPrimaryKey ?? false
    }

    func columnTypeTooltip(_ col: String) -> String {
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

    func isBooleanColumn(_ columnName: String) -> Bool {
        guard let structure = viewModel.tableStructure else { return false }
        guard let col = structure.columns.first(where: { $0.name == columnName }) else { return false }
        let t = col.type.lowercased()
        return t.contains("bool") || t.contains("bit") || t == "tinyint(1)"
    }

    func isJSONValue(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) ||
               (trimmed.hasPrefix("[") && trimmed.hasSuffix("]"))
    }

    func isURLValue(_ value: String) -> Bool {
        return value.hasPrefix("http://") || value.hasPrefix("https://")
    }

    func formatJSON(_ value: String) -> String {
        guard let data = value.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else {
            return value
        }
        return str
    }

    // MARK: - Row SQL Generators

    /// Quotes an identifier for the current engine.
    func quoteIdent(_ name: String) -> String {
        switch viewModel.database.type {
        case .postgresql, .cockroachdb, .sqlite:
            return "\"" + name.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        default:
            return "`" + name.replacingOccurrences(of: "`", with: "``") + "`"
        }
    }

    /// A SQL literal; nil is NULL.
    func sqlLiteral(_ value: String?) -> String {
        guard let value else { return "NULL" }
        return "'" + value.replacingOccurrences(of: "'", with: "''") + "'"
    }

    /// `values`: column → value (nil = NULL); columns missing from `values`
    /// (binary) are left out of the statement.
    func generateInsertStatement(columns: [String], values: [String: String?]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let included = columns.filter { values[$0] != nil }
        let cols = included.map(quoteIdent).joined(separator: ", ")
        let vals = included.map { sqlLiteral(values[$0] ?? nil) }.joined(separator: ", ")
        return "INSERT INTO \(quoteIdent(tableName)) (\(cols)) VALUES (\(vals));"
    }

    func generateUpdateStatement(columns: [String], values: [String: String?]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        var sets: [String] = []
        var wheres: [String] = []
        for col in columns where values[col] != nil {
            let literal = sqlLiteral(values[col] ?? nil)
            sets.append("\(quoteIdent(col)) = \(literal)")
            if isPrimaryKey(col) {
                wheres.append("\(quoteIdent(col)) = \(literal)")
            }
        }
        let whereClause = wheres.isEmpty ? "WHERE 1=1 /* add condition */" : "WHERE \(wheres.joined(separator: " AND "))"
        return "UPDATE \(quoteIdent(tableName)) SET \(sets.joined(separator: ", ")) \(whereClause);"
    }

    // MARK: - JSON Viewer Sheet

    var jsonViewerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isJSONValue(jsonViewerContent ?? "") ? L10n.Database.jsonViewer : L10n.Database.fullValue)
                    .font(AXTypography.headline).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button {
                    if let content = jsonViewerContent {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(content, forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.jsonCopied)
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
                Button { showJSONViewer = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)

            ScrollView {
                Text(jsonViewerContent ?? "")
                    .font(AXTypography.monoMd)
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

    /// Column indices worth exporting (binary placeholders are left out).
    private func exportColumnIndices(_ result: QueryResult) -> [Int] {
        let binary = viewModel.binaryColumnNames
        return result.columns.indices.filter { !binary.contains(result.columns[$0]) }
    }

    /// The cell's value, nil for SQL NULL.
    private func exportValue(_ result: QueryResult, row: Int, column: Int) -> String? {
        let value = column < result.rows[row].count ? result.rows[row][column] : ""
        if result.cellFlags != nil {
            return result.flags(row: row, column: column) & BridgeQueryResult.cellNull != 0 ? nil : value
        }
        return value == "NULL" ? nil : value
    }

    private func jsonString(_ value: String) -> String {
        var out = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out + "\""
    }

    func exportCSV(_ result: QueryResult) -> String {
        let indices = exportColumnIndices(result)
        var lines: [String] = [indices.map { result.columns[$0] }.joined(separator: ",")]
        for row in result.rows.indices {
            let escaped = indices.map { column -> String in
                let v = exportValue(result, row: row, column: column) ?? ""
                if v.contains(",") || v.contains("\"") || v.contains("\n") || v.contains("\r") {
                    return "\"\(v.replacingOccurrences(of: "\"", with: "\"\""))\""
                }
                return v
            }
            lines.append(escaped.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    func exportJSON(_ result: QueryResult) -> String {
        let indices = exportColumnIndices(result)
        var objects: [String] = []
        for row in result.rows.indices {
            let pairs = indices.map { column -> String in
                let value = exportValue(result, row: row, column: column).map(jsonString) ?? "null"
                return "    \(jsonString(result.columns[column])): \(value)"
            }
            objects.append("  {\n\(pairs.joined(separator: ",\n"))\n  }")
        }
        return "[\n" + objects.joined(separator: ",\n") + "\n]"
    }

    func exportSQL(_ result: QueryResult) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let indices = exportColumnIndices(result)
        let cols = indices.map { quoteIdent(result.columns[$0]) }.joined(separator: ", ")
        return result.rows.indices.map { row in
            let vals = indices.map { sqlLiteral(exportValue(result, row: row, column: $0)) }
            return "INSERT INTO \(quoteIdent(tableName)) (\(cols)) VALUES (\(vals.joined(separator: ", ")));"
        }.joined(separator: "\n")
    }

    func exportMarkdown(_ result: QueryResult) -> String {
        let indices = exportColumnIndices(result)
        let cell: (String) -> String = { $0.replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\n", with: " ") }
        var lines: [String] = []
        lines.append("| " + indices.map { cell(result.columns[$0]) }.joined(separator: " | ") + " |")
        lines.append("| " + indices.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in result.rows.indices {
            lines.append("| " + indices.map { cell(exportValue(result, row: row, column: $0) ?? "NULL") }.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }
}
