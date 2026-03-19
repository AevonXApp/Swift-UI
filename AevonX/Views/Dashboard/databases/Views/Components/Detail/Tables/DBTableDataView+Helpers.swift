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

            // Row number
            Text("\(index + 1)")
                .font(AXTypography.monoXs)
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

    func cellView(value: String, columnName: String) -> some View {
        Group {
            if value == "NULL" || value.isEmpty {
                Text("NULL")
                    .font(AXTypography.monoXs).fontWeight(.medium)
                    .foregroundColor(.axTextMuted.opacity(0.5))
                    .italic()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(AXCornerRadius.xs)
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
            } else if value == "true" || value == "false" || value == "1" || value == "0" {
                // Boolean display
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
                let total = Int(viewModel.selectedTable?.rowCount ?? Int64(end))
                Text("Showing \(offset + 1)-\(end) of \(total) rows")
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
                    Text("Page")
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
                    Text("of \(viewModel.totalPages)")
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
                .disabled(!viewModel.hasNextPage)
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

    func generateInsertStatement(columns: [String], row: [String]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let cols = columns.map { "`\($0)`" }.joined(separator: ", ")
        let vals = row.map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" }.joined(separator: ", ")
        return "INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals));"
    }

    func generateUpdateStatement(columns: [String], row: [String]) -> String {
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

    var jsonViewerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JSON Viewer")
                    .font(AXTypography.headline).fontWeight(.bold)
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

    func exportCSV(_ result: QueryResult) -> String {
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

    func exportJSON(_ result: QueryResult) -> String {
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

    func exportSQL(_ result: QueryResult) -> String {
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

    func exportMarkdown(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append("| " + result.columns.joined(separator: " | ") + " |")
        lines.append("| " + result.columns.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in result.rows {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }
}
