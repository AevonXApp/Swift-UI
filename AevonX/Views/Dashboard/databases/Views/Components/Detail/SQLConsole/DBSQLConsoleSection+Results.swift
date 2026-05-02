//
//  DBSQLConsoleSection+Results.swift
//  AevonX
//
//  Query results, error panel, results table, SQL formatter,
//  and export helpers for the SQL console section.
//

import SwiftUI
import AevonXCoreBridge

extension DBSQLConsoleSection {
    // MARK: - Query Results

    @ViewBuilder
    var queryResults: some View {
        if let error = viewModel.queryError {
            errorPanel(error)
        } else if let result = viewModel.queryResult {
            if let errorMsg = extractErrorFromResult(result) {
                // MySQL returned error as data — show premium error panel
                errorPanel(errorMsg)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    resultStatusBar(result)

                    if result.isSelect && !result.columns.isEmpty {
                        Divider().background(Color.axBorder)
                        queryResultsTable(result)
                    }
                }
            }
        } else {
            // Empty state — top-aligned, no vertical centering
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.05))
                        .frame(width: 60, height: 60)
                    Image(systemName: "terminal")
                        .font(AXTypography.title)
                        .foregroundColor(.axTextMuted.opacity(0.3))
                }
                VStack(spacing: AXSpacing.xxs) {
                    Text(L10n.Database.pressToExecute)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                    Text(L10n.Database.useQuickActions)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
            }
            .padding(.top, AXSpacing.xxxl)
            .padding(.bottom, AXSpacing.lg)
        }
    }

    // MARK: - Error Panel

    func errorPanel(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Error header
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.axError.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AXTypography.callout)
                        .foregroundColor(.axError)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Database.queryError)
                        .font(AXTypography.callout).fontWeight(.bold)
                        .foregroundColor(.axError)

                    if let codeRange = error.range(of: #"ERROR \d+ \([A-Z0-9]+\)"#, options: .regularExpression) {
                        Text(String(error[codeRange]))
                            .font(AXTypography.monoXxs).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axError.opacity(0.6))
                            .cornerRadius(AXCornerRadius.xs)
                    }
                }

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(error, forType: .string)
                    GlobalToastManager.shared.showSuccess(L10n.Database.errorCopied)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 24, height: 24)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.queryError = nil
                    viewModel.queryResult = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 24, height: 24)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)

            Rectangle().fill(Color.axError.opacity(0.15)).frame(height: 1)

            // Error message body
            Text(error)
                .font(AXTypography.monoSm).fontWeight(.medium)
                .foregroundColor(.axError)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AXSpacing.md)

            Rectangle().fill(Color.axError.opacity(0.15)).frame(height: 1)

            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axWarning)
                Text(L10n.Database.checkSQLHint)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
        }
        .background(Color.axError.opacity(0.04))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axError.opacity(0.25), lineWidth: 1)
        )
        .padding(AXSpacing.lg)
    }

    func resultStatusBar(_ result: QueryResult) -> some View {
        HStack(spacing: AXSpacing.md) {
            if result.isSelect {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axSuccess)
                    Text(L10n.Database.rowCountDisplay(result.rows.count))
                        .font(AXTypography.footnote).fontWeight(.bold)
                        .foregroundColor(.axTextSecondary)
                    Text("×")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text(L10n.Database.columnCountDisplay(result.columns.count))
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextMuted)
                }
            } else {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axSuccess)
                    Text(L10n.Database.querySuccess)
                        .font(AXTypography.footnote).fontWeight(.bold)
                        .foregroundColor(.axSuccess)
                    if result.affectedRows > 0 {
                        Text("· \(L10n.Database.rowsAffected(result.affectedRows))")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer()

            // Execution time badge
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: "clock")
                    .font(AXTypography.caption2)
                Text(String(format: "%.3fs", result.executionTime))
                    .font(AXTypography.monoXs).fontWeight(.medium)
            }
            .foregroundColor(.axTextMuted)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 3)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)

            // Copy results
            if result.isSelect && !result.rows.isEmpty {
                AXActionMenu(sections: [
                    AXMenuSection(L10n.Database.data, items: [
                        AXMenuItem(L10n.Database.copyAsTSV, icon: "tablecells", color: .axAccentBlue) {
                            let csv = formatAsCSV(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(csv, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.copiedRowsAsTSV(result.rows.count))
                        },
                        AXMenuItem(L10n.Database.copyAsJSON, icon: "curlybraces", color: .orange) {
                            let json = formatAsJSON(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(json, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.copiedRowsAsJSON(result.rows.count))
                        },
                    ]),
                    AXMenuSection("SQL", items: [
                        AXMenuItem(L10n.Database.copyAsINSERT, icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                            let sql = formatAsInsert(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(sql, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.copiedRowsAsINSERT(result.rows.count))
                        },
                        AXMenuItem(L10n.Database.copyAsMarkdown, icon: "text.document", color: .purple) {
                            let md = formatAsMarkdown(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(md, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.copiedAsMarkdownTable)
                        },
                    ]),
                ], triggerIcon: "square.and.arrow.up", triggerSize: 22)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.3))
    }

    // MARK: - Results Table

    func queryResultsTable(_ result: QueryResult) -> some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let numW: CGFloat = 40
            let colCount = max(CGFloat(result.columns.count), 1)
            let contentMinW = max(totalW, colCount * 130 + numW)
            let colW = max((contentMinW - numW) / colCount, 130)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Column headers
                    HStack(spacing: 0) {
                        Text("#")
                            .font(AXTypography.caption2).fontWeight(.heavy)
                            .foregroundColor(.axTextMuted)
                            .frame(width: numW, alignment: .center)
                            .padding(.vertical, AXSpacing.sm)

                        ForEach(result.columns, id: \.self) { col in
                            Text(col)
                                .font(AXTypography.caption).fontWeight(.bold)
                                .foregroundColor(.axTextSecondary)
                                .frame(width: colW, alignment: .leading)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.sm)
                        }
                    }
                    .frame(minWidth: contentMinW)
                    .background(Color.axSurface.opacity(0.6))

                    Rectangle().fill(Color.axBorder.opacity(0.4)).frame(height: 1)

                    // Data rows
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                                HStack(spacing: 0) {
                                    Text("\(index + 1)")
                                        .font(AXTypography.monoXxs)
                                        .foregroundColor(.axTextMuted.opacity(0.5))
                                        .frame(width: numW, alignment: .center)
                                        .padding(.vertical, AXSpacing.xs)

                                    ForEach(Array(row.enumerated()), id: \.offset) { colIdx, value in
                                        resultCellView(value: value, row: index, col: colIdx)
                                            .frame(width: colW, alignment: .leading)
                                            .padding(.horizontal, AXSpacing.sm)
                                            .padding(.vertical, AXSpacing.xs)
                                    }
                                }
                                .frame(minWidth: contentMinW)
                                .background(
                                    hoveredResultRow == index
                                        ? Color.axAccentBlue.opacity(0.06)
                                        : (index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.15))
                                )
                                .onHover { h in hoveredResultRow = h ? index : nil }

                                // Results row actions
                                HStack {
                                    Spacer()
                                    AXActionMenu(sections: [
                                        AXMenuSection(L10n.Button.copy, items: {
                                            var items: [AXMenuItem] = [
                                                AXMenuItem(L10n.Database.copyRow, icon: "doc.on.doc", color: .axAccentBlue) {
                                                    let vals = row.joined(separator: "\t")
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(vals, forType: .string)
                                                    GlobalToastManager.shared.showSuccess(L10n.Database.rowCopied)
                                                },
                                            ]
                                            if !result.columns.isEmpty {
                                                items.append(AXMenuItem(L10n.Database.copyAsINSERT, icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                                                    let insert = generateInsertFromResult(columns: result.columns, row: row)
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(insert, forType: .string)
                                                    GlobalToastManager.shared.showSuccess(L10n.Database.insertCopied)
                                                })
                                            }
                                            return items
                                        }()),
                                    ], triggerIcon: "ellipsis", triggerSize: 18)
                                }
                                .padding(.trailing, AXSpacing.xs)

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

    func resultCellView(value: String, row: Int, col: Int) -> some View {
        let cellId = "\(row)-\(col)"
        let isCopied = copiedResultCell == cellId
        return Group {
            if value.isEmpty || value == "NULL" {
                Text(L10n.Literal.null)
                    .font(AXTypography.monoXs).fontWeight(.medium)
                    .foregroundColor(.axTextMuted.opacity(0.4))
                    .italic()
            } else if Int(value) != nil || Double(value) != nil {
                Text(value)
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axAccentBlue)
                    .lineLimit(1)
            } else {
                Text(value.count > 60 ? String(value.prefix(60)) + "..." : value)
                    .font(AXTypography.monoSm)
                    .foregroundColor(isCopied ? .axSuccess : .axTextPrimary)
                    .lineLimit(1)
            }
        }
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            copiedResultCell = cellId
            GlobalToastManager.shared.showSuccess(L10n.Database.copiedPrefix(String(value.prefix(30))))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if copiedResultCell == cellId { copiedResultCell = nil }
            }
        }
        .help(value)
    }

    // MARK: - SQL Formatter

    func formatSQL(_ sql: String) -> String {
        let keywords = ["SELECT", "FROM", "WHERE", "AND", "OR", "ORDER BY", "GROUP BY",
                        "HAVING", "LIMIT", "OFFSET", "JOIN", "LEFT JOIN", "RIGHT JOIN",
                        "INNER JOIN", "OUTER JOIN", "ON", "INSERT INTO", "VALUES",
                        "UPDATE", "SET", "DELETE FROM", "CREATE TABLE", "ALTER TABLE",
                        "DROP TABLE", "UNION", "UNION ALL", "EXPLAIN"]
        var result = sql
        // Uppercase keywords
        for kw in keywords {
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: kw))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: kw
                )
            }
        }
        // Add newlines before major keywords
        let breakKeywords = ["FROM", "WHERE", "AND", "OR", "ORDER BY", "GROUP BY",
                             "HAVING", "LIMIT", "JOIN", "LEFT JOIN", "RIGHT JOIN",
                             "INNER JOIN", "ON", "SET", "VALUES"]
        for kw in breakKeywords {
            result = result.replacingOccurrences(of: " \(kw) ", with: "\n\(kw) ")
        }
        return result
    }

    // MARK: - Helpers

    func generateInsertFromResult(columns: [String], row: [String]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let cols = columns.map { "`\($0)`" }.joined(separator: ", ")
        let vals = row.map { v -> String in
            if v.isEmpty || v == "NULL" { return "NULL" }
            return "'\(v.replacingOccurrences(of: "'", with: "''"))'"
        }.joined(separator: ", ")
        return "INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals));"
    }

    func formatAsCSV(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append(result.columns.joined(separator: "\t"))
        for row in result.rows {
            lines.append(row.map { $0.isEmpty ? "NULL" : $0 }.joined(separator: "\t"))
        }
        return lines.joined(separator: "\n")
    }

    func formatAsJSON(_ result: QueryResult) -> String {
        var items: [String] = []
        for row in result.rows {
            var pairs: [String] = []
            for (i, col) in result.columns.enumerated() {
                let val = i < row.count ? (row[i].isEmpty ? "null" : row[i]) : "null"
                pairs.append("    \"\(col)\": \"\(val.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            items.append("  {\n\(pairs.joined(separator: ",\n"))\n  }")
        }
        return "[\n\(items.joined(separator: ",\n"))\n]"
    }

    func formatAsInsert(_ result: QueryResult) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        var stmts: [String] = []
        for row in result.rows {
            let vals = row.map { v -> String in
                if v.isEmpty { return "NULL" }
                return "'\(v.replacingOccurrences(of: "'", with: "''"))'"
            }
            let cols = result.columns.map { "`\($0)`" }.joined(separator: ", ")
            stmts.append("INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals.joined(separator: ", ")));")
        }
        return stmts.joined(separator: "\n")
    }

    func formatAsMarkdown(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append("| " + result.columns.joined(separator: " | ") + " |")
        lines.append("| " + result.columns.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in result.rows {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }
}
