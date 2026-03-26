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
    @State var hoveredResultRow: Int? = nil
    @State var copiedResultCell: String? = nil

    /// Check if a QueryResult contains an error returned as data by MySQL
    func resultContainsError(_ result: QueryResult) -> Bool {
        if result.rows.isEmpty {
            // Check if any column name hints at error
            return result.columns.contains(where: { $0.lowercased().contains("error") })
        }
        // Check first row for error pattern
        return result.rows.first?.contains(where: { $0.hasPrefix("ERROR ") }) ?? false
    }

    /// Extract the error message from a result that contains an error
    func extractErrorFromResult(_ result: QueryResult) -> String? {
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

    var consoleToolbar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 26, height: 26)
                    Image(systemName: "terminal.fill")
                        .font(AXTypography.subheadline)
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
                    .font(AXTypography.monoXs).fontWeight(.medium)
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

    var quickActionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                Text("Quick:")
                    .font(AXTypography.caption).fontWeight(.semibold)
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
                    .font(AXTypography.caption).fontWeight(.semibold)
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

    func quickChip(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(AXTypography.caption2)
                Text(title)
                    .font(AXTypography.caption).fontWeight(.semibold)
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

    func keywordChip(_ keyword: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(keyword)
                .font(AXTypography.monoXxs).fontWeight(.bold)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axSurface.opacity(0.6))
                .cornerRadius(AXCornerRadius.xs)
        }
        .buttonStyle(.plain)
    }

    func insertKeyword(_ keyword: String) {
        let trimmed = viewModel.queryText.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        if trimmed.isEmpty {
            viewModel.queryText = keyword
        } else {
            viewModel.queryText = trimmed + " " + keyword
        }
    }

    // MARK: - Editor Action Bar

    var editorActionBar: some View {
        HStack(spacing: AXSpacing.md) {
            // Line info
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "text.alignleft")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                if !viewModel.queryText.isEmpty {
                    Text("\(viewModel.queryText.filter { $0 == "\n" }.count + 1) lines · \(viewModel.queryText.count) chars")
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextMuted)
                } else {
                    Text("Empty")
                        .font(AXTypography.caption)
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
                            .font(AXTypography.caption2)
                        Text("Format")
                            .font(AXTypography.caption)
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
                            .font(AXTypography.caption2)
                        Text("Explain")
                            .font(AXTypography.caption)
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
                        .font(AXTypography.caption2)
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
                            .font(AXTypography.caption2)
                        Text(L10n.Button.clear)
                            .font(AXTypography.caption)
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
                            .font(AXTypography.caption)
                    }
                    Text(viewModel.isExecutingQuery ? "Running..." : "Execute")
                        .font(AXTypography.footnote).fontWeight(.bold)
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


    // Query results, error panel, results table, SQL formatter,
    // export helpers → DBSQLConsoleSection+Results.swift
}
