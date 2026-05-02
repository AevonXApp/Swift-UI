//
//  AXLogTable.swift
//  AevonX
//
//  Flexible, reusable log table component — UI only.
//  Callers define columns, parse their own data, and pass structured rows.
//
//  Usage:
//    AXLogTable(
//        title: "Auth Log",
//        icon: "shield.fill",
//        columns: [
//            AXLogColumn(id: "time", title: "Time", width: 140),
//            AXLogColumn(id: "message", title: "Message", width: nil),
//        ],
//        rows: myParsedRows,
//        isLoading: isLoading,
//        pageSize: 50,
//        onRefresh: { await reload() }
//    )
//

import SwiftUI
import AevonXCoreBridge

struct AXLogTable: View {
    let title: String
    let icon: String
    let columns: [AXLogColumn]
    let rows: [AXLogRow]
    let isLoading: Bool

    var pageSize: Int = 50
    var accentColor: Color = .axAccentBlue
    var rowActions: [AXLogRowAction] = []
    var onRefresh: (() async -> Void)? = nil
    var onAnalyze: (() -> Void)? = nil

    @State private var searchText = ""
    @State private var levelFilter: AXLogLevel = .all
    @State private var expandedRow: Int? = nil
    @State private var isRefreshing = false
    @State private var currentPage = 1

    // MARK: - Filtering + Pagination

    private var filteredRows: [AXLogRow] {
        var result = rows
        if levelFilter != .all {
            result = result.filter { row in
                switch levelFilter {
                case .all: return true
                case .errors: return row.level == "error" || row.level == "fatal" || row.level == "crit"
                case .warnings: return row.level == "warn" || row.level == "warning" || row.level == "notice"
                case .info: return row.level == "info" || row.level == "debug"
                }
            }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.raw.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var pagedRows: [AXLogRow] {
        Array(filteredRows.prefix(currentPage * pageSize))
    }

    private var hasMorePages: Bool {
        pagedRows.count < filteredRows.count
    }

    private func levelCount(_ level: AXLogLevel) -> Int {
        if level == .all { return rows.count }
        return rows.filter { row in
            switch level {
            case .all: return true
            case .errors: return row.level == "error" || row.level == "fatal" || row.level == "crit"
            case .warnings: return row.level == "warn" || row.level == "warning" || row.level == "notice"
            case .info: return row.level == "info" || row.level == "debug"
            }
        }.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().background(Color.axBorder.opacity(0.3))
            filterBar
            Divider().background(Color.axBorder.opacity(0.3))
            tableContent
            Divider().background(Color.axBorder.opacity(0.3))
            statusBar
        }
        .onChange(of: levelFilter) { _, _ in currentPage = 1 }
        .onChange(of: searchText) { _, _ in currentPage = 1 }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.axTextPrimary)
            }

            Spacer()

            if let onRefresh {
                Button(action: {
                    Task { isRefreshing = true; await onRefresh(); isRefreshing = false }
                }) {
                    HStack(spacing: 4) {
                        if isRefreshing { ProgressView().scaleEffect(0.5) }
                        else { Image(systemName: "arrow.clockwise").font(.system(size: 11)) }
                        Text(L10n.Button.refresh).font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRefreshing)
            }

            if let onAnalyze {
                Button(action: onAnalyze) {
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                        Text(L10n.Dashboard.aiAnalysis)
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: 4) {
                ForEach(AXLogLevel.allCases) { level in
                    levelPill(level)
                }
            }

            Divider().frame(height: 20)

            // Search
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.axSurface)
            .cornerRadius(6)
            .frame(maxWidth: 280)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface.opacity(0.15))
    }

    private func levelPill(_ level: AXLogLevel) -> some View {
        let c = levelCount(level)
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) { levelFilter = level }
        }) {
            HStack(spacing: 3) {
                Text(level.rawValue)
                    .font(.system(size: 10, weight: levelFilter == level ? .bold : .medium))
                if c > 0 {
                    Text("\(c)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(level.color.opacity(levelFilter == level ? 0.3 : 0.1))
                        .cornerRadius(3)
                }
            }
            .foregroundColor(levelFilter == level ? level.color : .axTextMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(levelFilter == level ? level.color.opacity(0.1) : Color.axSurface.opacity(0.5))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(levelFilter == level ? level.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Table Content

    @ViewBuilder
    private var tableContent: some View {
        VStack(spacing: 0) {
            // Dynamic table header from columns
            HStack(spacing: 0) {
                // Row number
                Text("#")
                    .frame(width: 35, alignment: .center)

                // Level badge column (always present)
                Text(L10n.Label.level)
                    .frame(width: 55, alignment: .center)
                    .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }

                // Caller-defined columns
                ForEach(columns) { col in
                    if let w = col.width {
                        Text(col.title)
                            .frame(width: w, alignment: col.alignment)
                            .padding(.leading, 8)
                            .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
                    } else {
                        Text(col.title)
                            .frame(maxWidth: .infinity, alignment: col.alignment)
                            .padding(.leading, 8)
                            .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
                    }
                }
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.axTextMuted)
            .textCase(.uppercase)
            .padding(.vertical, 6)
            .background(Color.axSurface.opacity(0.4))

            Divider().background(Color.axBorder.opacity(0.3))

            // Table body
            if isLoading {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text(L10n.Dashboard.loadingLogs).font(.system(size: 12)).foregroundColor(.axTextMuted)
                }
                .padding(AXSpacing.xl).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRows.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: rows.isEmpty ? "text.badge.checkmark" : "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.axTextMuted.opacity(0.4))
                    Text(rows.isEmpty ? "No log entries found" : "No entries match filter")
                        .font(.system(size: 13))
                        .foregroundColor(.axTextMuted)
                }
                .padding(AXSpacing.xl).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(pagedRows) { row in
                            tableRow(row)
                        }

                        // Load More button
                        if hasMorePages {
                            Button(action: { currentPage += 1 }) {
                                HStack(spacing: AXSpacing.sm) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 12))
                                    Text("Load More (\(filteredRows.count - pagedRows.count) remaining)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(accentColor)
                                .padding(.vertical, AXSpacing.md)
                                .frame(maxWidth: .infinity)
                                .background(accentColor.opacity(0.05))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Table Row

    private func tableRow(_ row: AXLogRow) -> some View {
        let isEven = row.id % 2 == 0
        let isExpanded = expandedRow == row.id

        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    expandedRow = expandedRow == row.id ? nil : row.id
                }
            }) {
                HStack(alignment: .center, spacing: 0) {
                    // #
                    Text("\(row.id + 1)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                        .frame(width: 35, alignment: .center)

                    // Level badge
                    Text(row.level.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(AXLogLevelDetector.color(row.level))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AXLogLevelDetector.color(row.level).opacity(0.12))
                        .cornerRadius(3)
                        .frame(width: 55, alignment: .center)
                        .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }

                    // Dynamic cells from columns
                    ForEach(columns) { col in
                        let value = row.cells[col.id] ?? "—"
                        if let w = col.width {
                            Text(value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .lineLimit(1)
                                .frame(width: w, alignment: col.alignment)
                                .padding(.leading, 8)
                                .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }
                        } else {
                            Text(value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: col.alignment)
                                .padding(.leading, 8)
                                .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }
                        }
                    }

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.axTextMuted.opacity(0.4))
                        .frame(width: 18)
                }
                .padding(.vertical, 4)
                .background(isExpanded ? accentColor.opacity(0.05) :
                           isEven ? Color.clear : Color.axSurface.opacity(0.06))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded details
            if isExpanded {
                rowDetailsView(row)
            }

            Divider().background(Color.axBorder.opacity(0.06))
        }
    }

    // MARK: - Row Details

    private func rowDetailsView(_ row: AXLogRow) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            // Key-value details
            if let details = row.details, !details.isEmpty {
                HStack(spacing: AXSpacing.xl) {
                    ForEach(Array(details.prefix(5).enumerated()), id: \.offset) { _, detail in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(detail.label)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.axTextMuted)
                                .textCase(.uppercase)
                            Text(detail.value.isEmpty ? "—" : detail.value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .textSelection(.enabled)
                        }
                    }

                    Spacer()

                    // Row actions
                    ForEach(Array(rowActions.enumerated()), id: \.offset) { _, action in
                        Button(action: { action.handler(row) }) {
                            HStack(spacing: 4) {
                                Image(systemName: action.icon)
                                Text(action.label)
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(action.color)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Extra details beyond first 5
                if details.count > 5 {
                    ForEach(Array(details.dropFirst(5).enumerated()), id: \.offset) { _, detail in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(detail.label)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.axTextMuted)
                                .textCase(.uppercase)
                            Text(detail.value.isEmpty ? "—" : detail.value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            // Raw log line
            VStack(alignment: .leading, spacing: 2) {
                Text("RAW")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.axTextMuted)
                Text(row.raw)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .padding(.leading, 35)
        .background(accentColor.opacity(0.03))
        .overlay(alignment: .leading) {
            accentColor.opacity(0.3).frame(width: 2)
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: AXSpacing.md) {
            Text("\(pagedRows.count) of \(filteredRows.count) entries")
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)

            if filteredRows.count != rows.count {
                Text("(\(rows.count) total)")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted.opacity(0.6))
            }

            if levelFilter != .all {
                HStack(spacing: 2) {
                    Circle().fill(levelFilter.color).frame(width: 5, height: 5)
                    Text(levelFilter.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(levelFilter.color)
                }
            }

            if !searchText.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "magnifyingglass").font(.system(size: 8))
                    Text("\"\(searchText)\"").font(.system(size: 10))
                }
                .foregroundColor(accentColor)
            }

            Spacer()

            if hasMorePages {
                Text("Page \(currentPage)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, 6)
        .background(Color.axSurface.opacity(0.15))
    }
}
