//
//  PluginDataTableComponent.swift
//  AevonX
//
//  Rich data table component driven entirely by JSON.
//  Premium design: sticky header, colored status badges, IP chips,
//  alternating rows, sortable columns, search, auto-refresh.
//

import SwiftUI
import Combine
import AevonXCore

struct PluginDataTableComponent: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = PluginDataTableViewModel()
    @State private var sortColumn: String? = nil
    @State private var sortAscending: Bool = true
    @State private var searchText: String = ""
    @State private var hoveredRow: Int? = nil

    private var columns: [HookColumnDefinition] { plugin.columns ?? [] }
    private var dataSource: HookDataSource? { plugin.dataSource }

    var body: some View {
        VStack(spacing: 0) {
            if vm.isLoading && vm.rows.isEmpty {
                toolbar
                Divider().opacity(0.4)
                loadingView
            } else if let error = vm.errorMessage, vm.rows.isEmpty {
                toolbar
                Divider().opacity(0.4)
                errorView(error)
            } else if vm.rows.isEmpty && !vm.isLoading {
                toolbar
                Divider().opacity(0.4)
                emptyView
            } else {
                // ── Unified header block: toolbar + column headers ──
                VStack(spacing: 0) {
                    toolbar

                    Rectangle()
                        .fill(Color.axBorder.opacity(0.3))
                        .frame(height: 1)

                    // Column header row
                    HStack(spacing: 0) {
                        Text("#")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.axTextMuted)
                            .frame(width: 40, alignment: .center)

                        ForEach(columns, id: \.key) { col in
                            columnHeaderFlex(col)
                        }
                    }
                    .padding(.vertical, 1)
                }
                .background(Color.axSurface.opacity(0.6))

                // Blue accent separator
                Rectangle()
                    .fill(Color.axAccentBlue.opacity(0.3))
                    .frame(height: 1)

                // Scrollable data rows
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredRows.enumerated()), id: \.offset) { index, row in
                            dataRowFlex(row: row, index: index)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.axBackground)
        .task(id: plugin.id) {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await vm.load(plugin: plugin, serverId: serverId, context: context)
        }
        .onDisappear {
            vm.cancelRefresh()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: AXSpacing.md) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextMuted)
                TextField("Search...", text: $searchText)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .foregroundColor(.axTextPrimary)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            .frame(maxWidth: 280)

            Spacer()

            // Stats
            if !vm.rows.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text("\(filteredRows.count)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                    Text("rows")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))
            }

            // Auto-refresh live indicator
            if let interval = dataSource?.refreshInterval, interval > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(vm.isRefreshing ? Color.axWarning : Color.axSuccess)
                        .frame(width: 5, height: 5)
                        .opacity(vm.isRefreshing ? 0.3 : 1.0)
                        .animation(vm.isRefreshing ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default, value: vm.isRefreshing)
                    Text(vm.isRefreshing ? "Updating..." : "Live · \(Int(interval))s")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(vm.isRefreshing ? .axWarning : .axSuccess)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background((vm.isRefreshing ? Color.axWarning : Color.axSuccess).opacity(0.08))
                .cornerRadius(AXCornerRadius.sm)
            }

            // Refresh button
            Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                        .animation(vm.isLoading ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: vm.isLoading)
                    Text("Refresh")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(vm.isLoading ? .axTextMuted : .axAccentBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.axAccentBlue.opacity(vm.isLoading ? 0.05 : 0.1))
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(vm.isLoading)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, 2)
    }



    private func columnHeaderFlex(_ col: HookColumnDefinition) -> some View {
        Button(action: {
            if sortColumn == col.key { sortAscending.toggle() }
            else { sortColumn = col.key; sortAscending = true }
        }) {
            HStack(spacing: 5) {
                if let icon = col.icon {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(sortColumn == col.key ? .axAccentBlue : .axTextMuted)
                }
                Text(col.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(sortColumn == col.key ? .axAccentBlue : .axTextSecondary)
                    .tracking(0.5)
                if sortColumn == col.key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.axAccentBlue)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(Double(col.width ?? 140))
    }

    private func dataRowFlex(row: [String: String], index: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .frame(width: 40, alignment: .center)
                .padding(.vertical, 9)

            ForEach(columns, id: \.key) { col in
                cellView(value: row[col.key] ?? "—", column: col)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground(index: index))
        .contentShape(Rectangle())
        .onHover { hovered in hoveredRow = hovered ? index : nil }
        .overlay(Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1), alignment: .bottom)
    }

    private func rowBackground(index: Int) -> Color {
        if hoveredRow == index {
            return Color.axAccentBlue.opacity(0.06)
        }
        return index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.25)
    }

    // MARK: - Cell Views

    @ViewBuilder
    private func cellView(value: String, column: HookColumnDefinition, width: CGFloat? = nil) -> some View {
        let effectiveWidth = width ?? column.width ?? 140
        Group {
            switch column.type {
            case .bytes:
                Text(formatBytes(value))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextSecondary)

            case .percent:
                HStack(spacing: 6) {
                    let pct = Double(value) ?? 0
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.axBorder.opacity(0.4))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(pct > 80 ? Color.axError : pct > 60 ? Color.axWarning : Color.axSuccess)
                                .frame(width: geo.size.width * min(pct / 100.0, 1.0))
                        }
                    }
                    .frame(width: 50, height: 4)
                    Text(String(format: "%.1f%%", pct))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(pct > 80 ? .axError : pct > 60 ? .axWarning : .axTextSecondary)
                }

            case .status:
                statusBadge(value)

            case .badge:
                Text(value)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.axAccentBlue.opacity(0.12))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))

            case .boolean:
                let isTrue = value.lowercased() == "true" || value == "1" || value.lowercased() == "yes"
                HStack(spacing: 4) {
                    Image(systemName: isTrue ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(isTrue ? .axSuccess : .axError)
                    Text(isTrue ? "Yes" : "No")
                        .font(.system(size: 11))
                        .foregroundColor(isTrue ? .axSuccess : .axError)
                }

            case .ip:
                HStack(spacing: 5) {
                    Image(systemName: "network")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextMuted)
                    Text(value)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axSurface)
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))

            case .number:
                Text(formatNumber(value))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

            case .url:
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.axAccentBlue)
                    .lineLimit(1)
                    .truncationMode(.middle)

            default:
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(Double(effectiveWidth))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    @ViewBuilder
    private func statusBadge(_ value: String) -> some View {
        let httpCode = Int(value) ?? 0
        let (color, icon): (Color, String) = {
            if httpCode >= 500 { return (.axError, "xmark.circle.fill") }
            if httpCode >= 400 { return (.axWarning, "exclamationmark.circle.fill") }
            if httpCode >= 300 { return (.axAccentBlue, "arrow.right.circle.fill") }
            if httpCode >= 200 { return (.axSuccess, "checkmark.circle.fill") }
            // Text-based status
            switch value.lowercased() {
            case "active", "online", "running", "ok", "success", "enabled":
                return (.axSuccess, "checkmark.circle.fill")
            case "inactive", "offline", "stopped", "error", "failed", "disabled":
                return (.axError, "xmark.circle.fill")
            case "warning", "degraded", "pending":
                return (.axWarning, "exclamationmark.circle.fill")
            default:
                return (.axTextMuted, "circle.fill")
            }
        }()

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(Color.axBorder, lineWidth: 2)
                    .frame(width: 36, height: 36)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.axAccentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: vm.isLoading)
            }
            Text("Fetching data from server...")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xxl)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.axError.opacity(0.1))
                    .frame(width: 52, height: 52)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.axError)
            }
            VStack(spacing: 6) {
                Text("Failed to load data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xxl)
    }

    private var emptyView: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.axSurface)
                    .frame(width: 52, height: 52)
                Image(systemName: "tray")
                    .font(.system(size: 22))
                    .foregroundColor(.axTextMuted)
            }
            VStack(spacing: 4) {
                Text("No data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                Text("The command returned no results")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xxl)
    }

    // MARK: - Filtering & Sorting

    private var filteredRows: [[String: String]] {
        var rows = vm.rows
        if !searchText.isEmpty {
            rows = rows.filter { row in
                row.values.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        if let col = sortColumn {
            rows.sort {
                let a = $0[col] ?? ""
                let b = $1[col] ?? ""
                if let da = Double(a), let db = Double(b) {
                    return sortAscending ? da < db : da > db
                }
                return sortAscending ? a < b : a > b
            }
        }
        return rows
    }

    // MARK: - Formatters

    private func formatBytes(_ value: String) -> String {
        guard let bytes = Double(value) else { return value }
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = bytes; var unitIndex = 0
        while size >= 1024 && unitIndex < units.count - 1 { size /= 1024; unitIndex += 1 }
        return String(format: "%.1f %@", size, units[unitIndex])
    }

    private func formatNumber(_ value: String) -> String {
        guard let num = Double(value) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? value
    }
}

// MARK: - ViewModel

@MainActor
final class PluginDataTableViewModel: ObservableObject {
    @Published var rows: [[String: String]] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: Date? = nil

    /// Tracks whether at least one successful load has completed.
    /// Used to distinguish first-time loading from background refreshes.
    private var hasLoadedOnce: Bool = false
    private var refreshTask: Task<Void, Never>? = nil

    func load(plugin: HookPluginDefinition, serverId: String, context: [String: String]) async {
        guard let ds = plugin.dataSource else { return }

        // Show full loading spinner only on the very first fetch.
        // All subsequent calls (auto-refresh or manual retry) do a silent update
        // so existing rows remain visible and the table never flickers.
        if hasLoadedOnce {
            isRefreshing = true
        } else {
            isLoading = true
        }
        errorMessage = nil

        do {
            let result = try await PluginCommandDispatcher.shared.fetchData(
                action: ds.action,
                payload: ds.payload,
                format: ds.format,
                rowsPath: ds.rowsPath,
                serverId: serverId,
                context: context
            )
            rows = result
            lastUpdated = Date()
            hasLoadedOnce = true
        } catch {
            // On refresh failure keep existing rows visible.
            // Only surface the error message on the very first load.
            if !hasLoadedOnce {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
        isRefreshing = false

        // Schedule the next auto-refresh if a refresh interval is configured.
        if let interval = ds.refreshInterval, interval > 0 {
            refreshTask?.cancel()
            refreshTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !Task.isCancelled {
                    await load(plugin: plugin, serverId: serverId, context: context)
                }
            }
        }
    }

    func cancelRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
