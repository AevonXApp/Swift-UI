//
//  PluginDataTableComponent.swift
//  AevonX
//
//  Rich data table component driven entirely by JSON:
//  - Fetches data via data_source (action + format)
//  - Parses output (JSON, CSV, TSV, lines, key_value)
//  - Renders columns defined in JSON (text, number, bytes, percent, status, badge, url, ip, boolean)
//  - Supports sorting, auto-refresh, and search
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

    private var columns: [HookColumnDefinition] {
        plugin.columns ?? []
    }

    private var dataSource: HookDataSource? {
        plugin.dataSource
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                // Search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                    TextField("Search...", text: $searchText)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                .frame(maxWidth: 260)

                Spacer()

                // Row count
                if !vm.rows.isEmpty {
                    Text("\(filteredRows.count) rows")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }

                // Refresh button
                Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                    HStack(spacing: 4) {
                        Image(systemName: vm.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                            .font(.system(size: 12))
                            .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                            .animation(vm.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: vm.isLoading)
                        Text("Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider()

            // Content
            if vm.isLoading && vm.rows.isEmpty {
                loadingView
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if vm.rows.isEmpty {
                emptyView
            } else {
                tableView
            }
        }
        .task {
            await vm.load(plugin: plugin, serverId: serverId, context: context)
        }
        .onReceive(vm.$rows) { _ in
            // Auto-refresh handled by vm
        }
    }

    // MARK: - Table View

    private var tableView: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    ForEach(columns, id: \.key) { col in
                        columnHeader(col)
                    }
                }
                .background(Color.axSurface)

                Divider()

                // Data rows
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredRows.enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            ForEach(columns, id: \.key) { col in
                                cellView(value: row[col.key] ?? "—", column: col)
                            }
                        }
                        .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))

                        if index < filteredRows.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func columnHeader(_ col: HookColumnDefinition) -> some View {
        Button(action: {
            if sortColumn == col.key {
                sortAscending.toggle()
            } else {
                sortColumn = col.key
                sortAscending = true
            }
        }) {
            HStack(spacing: 4) {
                if let icon = col.icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                Text(col.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)

                if sortColumn == col.key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.axAccentBlue)
                }
            }
            .frame(width: col.width ?? 140, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cellView(value: String, column: HookColumnDefinition) -> some View {
        Group {
            switch column.type {
            case .bytes:
                Text(formatBytes(value))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

            case .percent:
                HStack(spacing: 6) {
                    let pct = Double(value) ?? 0
                    ProgressView(value: min(pct / 100.0, 1.0))
                        .progressViewStyle(.linear)
                        .tint(pct > 80 ? .axError : pct > 60 ? .axWarning : .axSuccess)
                        .frame(width: 60)
                    Text(String(format: "%.1f%%", pct))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                }

            case .status:
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(for: value))
                        .frame(width: 6, height: 6)
                    Text(value)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor(for: value))
                }

            case .badge:
                Text(value)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.axAccentBlue.opacity(0.12))
                    .cornerRadius(4)

            case .boolean:
                Image(systemName: (value.lowercased() == "true" || value == "1" || value.lowercased() == "yes") ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor((value.lowercased() == "true" || value == "1") ? .axSuccess : .axError)

            case .ip:
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

            case .number:
                Text(formatNumber(value))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

            case .url:
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.axAccentBlue)
                    .underline()
                    .lineLimit(1)

            default:
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
        }
        .frame(width: column.width ?? 140, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading data...")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(.axWarning)
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await vm.load(plugin: plugin, serverId: serverId, context: context) }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.axAccentBlue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }

    private var emptyView: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(.axTextMuted)
            Text("No data")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }

    // MARK: - Helpers

    private var filteredRows: [[String: String]] {
        var rows = vm.rows

        // Search filter
        if !searchText.isEmpty {
            rows = rows.filter { row in
                row.values.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Sort
        if let col = sortColumn {
            rows.sort {
                let a = $0[col] ?? ""
                let b = $1[col] ?? ""
                // Try numeric sort first
                if let da = Double(a), let db = Double(b) {
                    return sortAscending ? da < db : da > db
                }
                return sortAscending ? a < b : a > b
            }
        }

        return rows
    }

    private func statusColor(for value: String) -> Color {
        switch value.lowercased() {
        case "active", "online", "running", "ok", "success", "enabled": return .axSuccess
        case "inactive", "offline", "stopped", "error", "failed", "disabled": return .axError
        case "warning", "degraded", "pending": return .axWarning
        default: return .axTextMuted
        }
    }

    private func formatBytes(_ value: String) -> String {
        guard let bytes = Double(value) else { return value }
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = bytes
        var unitIndex = 0
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
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
    @Published var errorMessage: String? = nil

    private var refreshTask: Task<Void, Never>? = nil

    func load(plugin: HookPluginDefinition, serverId: String, context: [String: String]) async {
        guard let ds = plugin.dataSource else { return }
        isLoading = true
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
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false

        // Schedule auto-refresh
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
}
