//
//  DBSQLConsoleSection.swift
//  AevonX
//
//  Premium SQL Console with AXCodeEditor, query history,
//  keyboard shortcuts, quick action bar, formatted results table,
//  and multi-format export.
//

import SwiftUI
import AevonXCoreBridge

struct DBSQLConsoleSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    @State private var editorHeight: CGFloat = 180
    @State private var hoveredResultRow: Int? = nil
    @State private var copiedResultCell: String? = nil


    /// Check if a QueryResult contains an error returned as data by MySQL
    private func resultContainsError(_ result: QueryResult) -> Bool {
        if result.rows.isEmpty {
            // Check if any column name hints at error
            return result.columns.contains(where: { $0.lowercased().contains("error") })
        }
        // Check first row for error pattern
        return result.rows.first?.contains(where: { $0.hasPrefix("ERROR ") }) ?? false
    }

    /// Extract the error message from a result that contains an error
    private func extractErrorFromResult(_ result: QueryResult) -> String? {
        for row in result.rows {
            for cell in row {
                if cell.hasPrefix("ERROR ") { return cell }
            }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            consoleToolbar
            Divider().background(Color.axBorder)

            // Editor
            AXCodeEditor(text: $viewModel.queryText)
                .frame(minHeight: 100, idealHeight: editorHeight, maxHeight: 300)

            // Quick action bar
            quickActionBar
            Divider().background(Color.axBorder)

            // Action bar
            editorActionBar
            Divider().background(Color.axBorder)

            // Results — fills remaining space
            queryResults
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var consoleToolbar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 26, height: 26)
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.purple)
                }
                Text("SQL Console")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }

            // Database indicator
            HStack(spacing: AXSpacing.xxs) {
                Circle()
                    .fill(Color.axSuccess)
                    .frame(width: 5, height: 5)
                Text(viewModel.database.name)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 3)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)

            Spacer()

            // Query templates — AXActionMenu
            AXActionMenu(sections: [
                AXMenuSection("SELECT", items: [
                    AXMenuItem("SELECT * FROM ...", icon: "tablecells", color: .axAccentBlue) { viewModel.queryText = "SELECT * FROM " },
                    AXMenuItem("SELECT COUNT(*) ...", icon: "number", color: .indigo) { viewModel.queryText = "SELECT COUNT(*) FROM " },
                    AXMenuItem("SELECT DISTINCT ...", icon: "line.3.horizontal.decrease", color: .cyan) { viewModel.queryText = "SELECT DISTINCT  FROM " },
                    AXMenuItem("SELECT GROUP BY ...", icon: "chart.bar", color: .teal) { viewModel.queryText = "SELECT , COUNT(*) FROM  GROUP BY " },
                    AXMenuItem("SELECT with JOIN", icon: "arrow.triangle.merge", color: .mint) { viewModel.queryText = "SELECT a.*, b.* FROM  a\nINNER JOIN  b ON a.id = b.id\nWHERE 1=1" },
                    AXMenuItem("SELECT with SUBQUERY", icon: "arrow.turn.down.right", color: .purple) { viewModel.queryText = "SELECT * FROM  WHERE id IN (\n  SELECT id FROM  WHERE \n)" },
                ]),
                AXMenuSection("DDL", items: [
                    AXMenuItem("SHOW TABLES", icon: "list.bullet", color: .mint) { viewModel.queryText = "SHOW TABLES" },
                    AXMenuItem("SHOW DATABASES", icon: "cylinder.split.1x2", color: .orange) { viewModel.queryText = "SHOW DATABASES" },
                    AXMenuItem("DESCRIBE table", icon: "info.circle", color: .axAccentGreen) { viewModel.queryText = "DESCRIBE " },
                    AXMenuItem("SHOW CREATE TABLE", icon: "text.alignleft", color: .cyan) { viewModel.queryText = "SHOW CREATE TABLE " },
                    AXMenuItem("SHOW PROCESSLIST", icon: "person.3", color: .axWarning) { viewModel.queryText = "SHOW PROCESSLIST" },
                    AXMenuItem("SHOW INDEX FROM ...", icon: "key", color: .yellow) { viewModel.queryText = "SHOW INDEX FROM " },
                    AXMenuItem("SHOW TABLE STATUS", icon: "chart.bar.doc.horizontal", color: .teal) { viewModel.queryText = "SHOW TABLE STATUS" },
                    AXMenuItem("SHOW VARIABLES", icon: "gearshape", color: .orange) { viewModel.queryText = "SHOW VARIABLES LIKE '%%'" },
                ]),
                AXMenuSection("DML", items: [
                    AXMenuItem("INSERT INTO ...", icon: "plus.rectangle", color: .axAccentGreen) { viewModel.queryText = "INSERT INTO  (col1, col2) VALUES ('val1', 'val2')" },
                    AXMenuItem("UPDATE ... SET ...", icon: "pencil.circle", color: .axAccentBlue) { viewModel.queryText = "UPDATE  SET col1 = 'value' WHERE id = " },
                    AXMenuItem("DELETE FROM ...", icon: "minus.rectangle", color: .axError) { viewModel.queryText = "DELETE FROM  WHERE id = " },
                    AXMenuItem("REPLACE INTO ...", icon: "arrow.triangle.2.circlepath", color: .purple) { viewModel.queryText = "REPLACE INTO  (col1, col2) VALUES ('val1', 'val2')" },
                ]),
                AXMenuSection("Administration", items: [
                    AXMenuItem("BEGIN / COMMIT", icon: "lock.shield", color: .indigo) { viewModel.queryText = "BEGIN;\n\n-- your queries here\n\nCOMMIT;" },
                    AXMenuItem("EXPLAIN", icon: "gauge.with.dots.needle.33percent", color: .axWarning) { viewModel.queryText = "EXPLAIN SELECT * FROM " },
                    AXMenuItem("OPTIMIZE TABLE", icon: "wand.and.stars", color: .orange) { viewModel.queryText = "OPTIMIZE TABLE " },
                    AXMenuItem("CHECK TABLE", icon: "checkmark.shield", color: .axSuccess) { viewModel.queryText = "CHECK TABLE " },
                    AXMenuItem("REPAIR TABLE", icon: "wrench.and.screwdriver", color: .purple) { viewModel.queryText = "REPAIR TABLE " },
                ]),
            ], triggerIcon: "list.bullet.rectangle", triggerSize: 28)

            // History
            if !viewModel.queryHistory.isEmpty {
                AXActionMenu(sections: [
                    AXMenuSection("Recent", items:
                        viewModel.queryHistory.prefix(20).map { entry in
                            let q = entry.query
                            let label = String(q.prefix(40)) + (q.count > 40 ? "..." : "")
                            return AXMenuItem(label, icon: entry.success ? "checkmark.circle" : "xmark.circle", color: entry.success ? .axSuccess : .axError) {
                                viewModel.queryText = q
                            }
                        }
                    ),
                    AXMenuSection(items: [
                        AXMenuItem("Clear History", icon: "trash", isDestructive: true) {
                            viewModel.queryHistory.removeAll()
                        },
                    ]),
                ], triggerIcon: "clock.arrow.circlepath", triggerSize: 28)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }

    // MARK: - Quick Action Bar

    private var quickActionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                Text("Quick:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextMuted)

                quickChip("SELECT *", icon: "tablecells", color: .axAccentBlue) {
                    if let tbl = viewModel.selectedTable?.name {
                        viewModel.queryText = "SELECT * FROM `\(tbl)` LIMIT 100"
                        Task { await viewModel.executeQuery() }
                    } else {
                        viewModel.queryText = "SELECT * FROM "
                    }
                }

                quickChip("SHOW TABLES", icon: "list.bullet", color: .mint) {
                    viewModel.queryText = "SHOW TABLES"
                    Task { await viewModel.executeQuery() }
                }

                quickChip("DESCRIBE", icon: "info.circle", color: .axAccentGreen) {
                    if let tbl = viewModel.selectedTable?.name {
                        viewModel.queryText = "DESCRIBE `\(tbl)`"
                        Task { await viewModel.executeQuery() }
                    } else {
                        viewModel.queryText = "DESCRIBE "
                    }
                }

                quickChip("PROCESSLIST", icon: "person.3", color: .axWarning) {
                    viewModel.queryText = "SHOW PROCESSLIST"
                    Task { await viewModel.executeQuery() }
                }

                quickChip("COUNT", icon: "number", color: .indigo) {
                    if let tbl = viewModel.selectedTable?.name {
                        viewModel.queryText = "SELECT COUNT(*) as total FROM `\(tbl)`"
                        Task { await viewModel.executeQuery() }
                    } else {
                        viewModel.queryText = "SELECT COUNT(*) FROM "
                    }
                }

                quickChip("DB SIZE", icon: "internaldrive", color: .purple) {
                    viewModel.queryText = "SELECT table_name AS 'Table', ROUND(data_length/1024/1024, 2) AS 'Data (MB)', ROUND(index_length/1024/1024, 2) AS 'Index (MB)', ROUND((data_length+index_length)/1024/1024, 2) AS 'Total (MB)' FROM information_schema.tables WHERE table_schema = '\(viewModel.database.name)' ORDER BY (data_length+index_length) DESC"
                    Task { await viewModel.executeQuery() }
                }

                quickChip("VARIABLES", icon: "gearshape", color: .orange) {
                    viewModel.queryText = "SHOW VARIABLES LIKE '%%'"
                }

                quickChip("STATUS", icon: "chart.bar", color: .teal) {
                    viewModel.queryText = "SHOW GLOBAL STATUS"
                    Task { await viewModel.executeQuery() }
                }

                // SQL keywords for composition
                Rectangle()
                    .fill(Color.axBorder.opacity(0.3))
                    .frame(width: 1, height: 16)

                Text("Insert:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextMuted)

                keywordChip("SELECT") { insertKeyword("SELECT") }
                keywordChip("FROM") { insertKeyword("FROM") }
                keywordChip("WHERE") { insertKeyword("WHERE") }
                keywordChip("JOIN") { insertKeyword("JOIN") }
                keywordChip("GROUP BY") { insertKeyword("GROUP BY") }
                keywordChip("ORDER BY") { insertKeyword("ORDER BY") }
                keywordChip("LIMIT") { insertKeyword("LIMIT") }
                keywordChip("AND") { insertKeyword("AND") }
                keywordChip("OR") { insertKeyword("OR") }
                keywordChip("LIKE") { insertKeyword("LIKE '%%'") }
                keywordChip("IN") { insertKeyword("IN ()") }
                keywordChip("AS") { insertKeyword("AS") }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
        }
        .background(Color.axSurface.opacity(0.2))
    }

    private func quickChip(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 4)
            .background(color.opacity(0.08))
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func keywordChip(_ keyword: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(keyword)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axSurface.opacity(0.6))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private func insertKeyword(_ keyword: String) {
        let trimmed = viewModel.queryText.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        if trimmed.isEmpty {
            viewModel.queryText = keyword
        } else {
            viewModel.queryText = trimmed + " " + keyword
        }
    }

    // MARK: - Editor Action Bar

    private var editorActionBar: some View {
        HStack(spacing: AXSpacing.md) {
            // Line info
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 9))
                    .foregroundColor(.axTextMuted)
                if !viewModel.queryText.isEmpty {
                    Text("\(viewModel.queryText.filter { $0 == "\n" }.count + 1) lines · \(viewModel.queryText.count) chars")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                } else {
                    Text("Empty")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
            }

            Spacer()

            // Format / Beautify
            if !viewModel.queryText.isEmpty {
                Button {
                    viewModel.queryText = formatSQL(viewModel.queryText)
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 9))
                        Text("Format")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.axInfo)
                }
                .buttonStyle(.plain)
                .help("Format & beautify SQL")
            }

            // Explain button
            if !viewModel.queryText.isEmpty {
                Button {
                    let original = viewModel.queryText
                    if !original.uppercased().hasPrefix("EXPLAIN") {
                        viewModel.queryText = "EXPLAIN " + original
                    }
                    Task {
                        await viewModel.executeQuery()
                        viewModel.queryText = original
                    }
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .font(.system(size: 9))
                        Text("Explain")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.axWarning)
                }
                .buttonStyle(.plain)
            }

            // Copy query
            if !viewModel.queryText.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.queryText, forType: .string)
                    GlobalToastManager.shared.showSuccess("Query copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
                .help("Copy query")
            }

            // Clear
            if !viewModel.queryText.isEmpty {
                Button {
                    viewModel.queryText = ""
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                        Text("Clear")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }

            // Execute button
            Button {
                Task { await viewModel.executeQuery() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if viewModel.isExecutingQuery {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                    }
                    Text(viewModel.isExecutingQuery ? "Running..." : "Execute")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    ZStack {
                        if viewModel.queryText.isEmpty || viewModel.isExecutingQuery {
                            Color.axTextMuted.opacity(0.3)
                        } else {
                            LinearGradient(
                                colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.queryText.isEmpty || viewModel.isExecutingQuery)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.3))
    }

    // MARK: - Query Results

    @ViewBuilder
    private var queryResults: some View {
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
                        .font(.system(size: 24))
                        .foregroundColor(.axTextMuted.opacity(0.3))
                }
                VStack(spacing: AXSpacing.xxs) {
                    Text("Press ⌘+Enter to execute")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextMuted)
                    Text("Use quick actions or type your own SQL")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
            }
            .padding(.top, AXSpacing.xxxl)
            .padding(.bottom, AXSpacing.lg)
        }
    }

    // MARK: - Error Panel

    private func errorPanel(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Error header
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.axError.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axError)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Query Error")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.axError)

                    if let codeRange = error.range(of: #"ERROR \d+ \([A-Z0-9]+\)"#, options: .regularExpression) {
                        Text(String(error[codeRange]))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axError.opacity(0.6))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(error, forType: .string)
                    GlobalToastManager.shared.showSuccess("Error copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
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
                        .font(.system(size: 9, weight: .bold))
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
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.axError)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AXSpacing.md)

            Rectangle().fill(Color.axError.opacity(0.15)).frame(height: 1)

            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.axWarning)
                Text("Check your SQL syntax, table names, and column references")
                    .font(.system(size: 10))
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

    private func resultStatusBar(_ result: QueryResult) -> some View {
        HStack(spacing: AXSpacing.md) {
            if result.isSelect {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axSuccess)
                    Text("\(result.rows.count) rows")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.axTextSecondary)
                    Text("×")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text("\(result.columns.count) columns")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
            } else {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axSuccess)
                    Text("Query executed successfully")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.axSuccess)
                    if result.affectedRows > 0 {
                        Text("· \(result.affectedRows) rows affected")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer()

            // Execution time badge
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: "clock")
                    .font(.system(size: 8))
                Text(String(format: "%.3fs", result.executionTime))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            }
            .foregroundColor(.axTextMuted)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 3)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)

            // Copy results
            if result.isSelect && !result.rows.isEmpty {
                AXActionMenu(sections: [
                    AXMenuSection("Data", items: [
                        AXMenuItem("Copy as TSV", icon: "tablecells", color: .axAccentBlue) {
                            let csv = formatAsCSV(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(csv, forType: .string)
                            GlobalToastManager.shared.showSuccess("Copied \(result.rows.count) rows as TSV")
                        },
                        AXMenuItem("Copy as JSON", icon: "curlybraces", color: .orange) {
                            let json = formatAsJSON(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(json, forType: .string)
                            GlobalToastManager.shared.showSuccess("Copied \(result.rows.count) rows as JSON")
                        },
                    ]),
                    AXMenuSection("SQL", items: [
                        AXMenuItem("Copy as INSERT", icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                            let sql = formatAsInsert(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(sql, forType: .string)
                            GlobalToastManager.shared.showSuccess("Copied \(result.rows.count) rows as INSERT")
                        },
                        AXMenuItem("Copy as Markdown", icon: "text.document", color: .purple) {
                            let md = formatAsMarkdown(result)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(md, forType: .string)
                            GlobalToastManager.shared.showSuccess("Copied as Markdown table")
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

    private func queryResultsTable(_ result: QueryResult) -> some View {
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
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.axTextMuted)
                            .frame(width: numW, alignment: .center)
                            .padding(.vertical, AXSpacing.sm)

                        ForEach(result.columns, id: \.self) { col in
                            Text(col)
                                .font(.system(size: 10, weight: .bold))
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
                                        .font(.system(size: 9, design: .monospaced))
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
                                        AXMenuSection("Copy", items: {
                                            var items: [AXMenuItem] = [
                                                AXMenuItem("Copy Row", icon: "doc.on.doc", color: .axAccentBlue) {
                                                    let vals = row.joined(separator: "\t")
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(vals, forType: .string)
                                                    GlobalToastManager.shared.showSuccess("Row copied")
                                                },
                                            ]
                                            if !result.columns.isEmpty {
                                                items.append(AXMenuItem("Copy as INSERT", icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                                                    let insert = generateInsertFromResult(columns: result.columns, row: row)
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(insert, forType: .string)
                                                    GlobalToastManager.shared.showSuccess("INSERT statement copied")
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

    private func resultCellView(value: String, row: Int, col: Int) -> some View {
        let cellId = "\(row)-\(col)"
        let isCopied = copiedResultCell == cellId
        return Group {
            if value.isEmpty || value == "NULL" {
                Text("NULL")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted.opacity(0.4))
                    .italic()
            } else if Int(value) != nil || Double(value) != nil {
                Text(value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
                    .lineLimit(1)
            } else {
                Text(value.count > 60 ? String(value.prefix(60)) + "..." : value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isCopied ? .axSuccess : .axTextPrimary)
                    .lineLimit(1)
            }
        }
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            copiedResultCell = cellId
            GlobalToastManager.shared.showSuccess("Copied: \(String(value.prefix(30)))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if copiedResultCell == cellId { copiedResultCell = nil }
            }
        }
        .help(value)
    }

    // MARK: - SQL Formatter

    private func formatSQL(_ sql: String) -> String {
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

    private func generateInsertFromResult(columns: [String], row: [String]) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let cols = columns.map { "`\($0)`" }.joined(separator: ", ")
        let vals = row.map { v -> String in
            if v.isEmpty || v == "NULL" { return "NULL" }
            return "'\(v.replacingOccurrences(of: "'", with: "''"))'"
        }.joined(separator: ", ")
        return "INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals));"
    }

    private func formatAsCSV(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append(result.columns.joined(separator: "\t"))
        for row in result.rows {
            lines.append(row.map { $0.isEmpty ? "NULL" : $0 }.joined(separator: "\t"))
        }
        return lines.joined(separator: "\n")
    }

    private func formatAsJSON(_ result: QueryResult) -> String {
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

    private func formatAsInsert(_ result: QueryResult) -> String {
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

    private func formatAsMarkdown(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append("| " + result.columns.joined(separator: " | ") + " |")
        lines.append("| " + result.columns.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in result.rows {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }
}
