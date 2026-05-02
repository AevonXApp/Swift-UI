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
import AppKit
import UniformTypeIdentifiers
import AevonXCoreBridge

/// Identifiable wrapper for row data — used for .sheet(item:)
private struct IdentifiableRow: Identifiable {
    let id = UUID()
    let data: [String: String]
}

struct PluginDataTableComponent: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = PluginDataTableViewModel()
    @State private var sortColumn: String? = nil
    @State private var sortAscending: Bool = true
    @State private var searchText: String = ""
    @State private var hoveredRow: Int? = nil
    @State private var currentPage: Int = 0
    @State private var selectedRow: [String: String]? = nil
    @State private var selectedDetailRow: IdentifiableRow? = nil
    @State private var pendingAction: PendingRowAction? = nil
    @State private var showConfirmation: Bool = false
    @State private var activeFilters: [String: String] = [:]
    @StateObject private var actionVM = HookPluginViewModel()

    private var columns: [HookColumnDefinition] { plugin.columns ?? [] }
    private var dataSource: HookDataSource? { plugin.dataSource }
    private var rowActions: [HookRowActionButton] { plugin.rowActions ?? [] }
    private var hasRowActions: Bool { !rowActions.isEmpty }
    private var columnFilters: [HookColumnFilter] { plugin.filters ?? [] }

    /// Minimum table width based on column definitions — prevents compression
    private var minTableWidth: CGFloat {
        let indexCol: CGFloat = 40
        let columnsWidth = columns.reduce(CGFloat(0)) { $0 + CGFloat($1.width ?? 140) }
        let actionsWidth = hasRowActions ? CGFloat(rowActions.count) * 80 + 16 : 0
        return indexCol + columnsWidth + actionsWidth + CGFloat(columns.count) * 24  // 24 = horizontal padding per column
    }

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
                VStack(spacing: 0) {
                    toolbar
                    Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1)

                    // Filter bar
                    if !columnFilters.isEmpty && !vm.rows.isEmpty {
                        filterBar
                    }

                    // Column headers
                    HStack(spacing: 0) {
                        Text("#")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.axTextMuted)
                            .frame(width: 40, alignment: .center)
                        ForEach(columns, id: \.key) { col in
                            columnHeaderFlex(col)
                        }
                        if hasRowActions {
                            Text(L10n.Label.actions)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.axTextSecondary)
                                .tracking(0.5)
                                .frame(width: CGFloat(rowActions.count) * 80 + 16, alignment: .center)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.axSurface.opacity(0.6))

                    Rectangle().fill(Color.axAccentBlue.opacity(0.3)).frame(height: 1)

                    // Data rows
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(paginatedRows.enumerated()), id: \.offset) { index, row in
                                dataRowFlex(row: row, index: (currentPage * pageSize) + index)
                                    .onTapGesture {
                                        if plugin.onRowTap != nil {
                                            selectedRow = row
                                            selectedDetailRow = IdentifiableRow(data: row)
                                        }
                                    }
                            }
                        }
                    }
                }
                if pageSize < filteredRows.count { paginationBar }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.axBackground)
        .task(id: plugin.id) {
            // Plugin identity changed → we're looking at a different tab.
            // Clear stale rows BEFORE starting the new fetch so the table
            // shows a clean skeleton instead of the previous tab's rows
            // rendered through the new column schema (all cells resolve
            // to `—` because the keys don't match).
            vm.resetForNewPlugin()
            try? await Task.sleep(nanoseconds: 300_000_000)
            await vm.load(plugin: plugin, serverId: serverId, context: context)
        }
        .onDisappear { vm.cancelRefresh() }
        .sheet(item: $selectedDetailRow) { item in
            rowDetailSheet(item.data)
        }
        .alert("Confirm Action", isPresented: $showConfirmation, presenting: pendingAction) { action in
            Button("Cancel", role: .cancel) { pendingAction = nil }
            Button(action.button.style == .danger ? "Confirm" : "OK", role: action.button.style == .danger ? .destructive : nil) {
                executeRowAction(action.button, row: action.row)
            }
        } message: { action in
            Text(interpolateTemplate(action.button.confirmationMessage ?? "Are you sure?", row: action.row))
        }
    }

    // MARK: - Pagination

    private var pageSize: Int { plugin.dataSource?.pageSize ?? 200 }
    private var totalPages: Int {
        let total = filteredRows.count
        guard pageSize < total else { return 1 }
        return (total + pageSize - 1) / pageSize
    }
    private var paginatedRows: [[String: String]] {
        guard pageSize < filteredRows.count else { return filteredRows }
        let start = currentPage * pageSize
        let end = min(start + pageSize, filteredRows.count)
        guard start < end else { return [] }
        return Array(filteredRows[start..<end])
    }

    private var paginationBar: some View {
        HStack(spacing: AXSpacing.md) {
            Spacer()
            Button(action: { if currentPage > 0 { currentPage -= 1 } }) {
                Image(systemName: "chevron.left").font(.system(size: 11, weight: .medium))
                    .foregroundColor(currentPage > 0 ? .axAccentBlue : .axTextMuted)
            }.buttonStyle(.plain).disabled(currentPage == 0)
            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextSecondary)
            Button(action: { if currentPage < totalPages - 1 { currentPage += 1 } }) {
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium))
                    .foregroundColor(currentPage < totalPages - 1 ? .axAccentBlue : .axTextMuted)
            }.buttonStyle(.plain).disabled(currentPage >= totalPages - 1)
            Text("\(filteredRows.count) total").font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted)
            Spacer()
        }
        .padding(.vertical, AXSpacing.sm).background(Color.axSurface.opacity(0.6))
    }

    // MARK: - Row Detail Sheet

    private func rowDetailSheet(_ row: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.md) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.15)).frame(width: 32, height: 32)
                        Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.onRowTap?.title ?? "Details").font(.system(size: 15, weight: .bold)).foregroundColor(.axTextPrimary)
                    if let ip = row["ip"] ?? row["client_ip"] ?? row["remote_ip"] {
                        Text(ip).font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
                Button(action: { selectedDetailRow = nil }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundColor(.axTextMuted)
                }.buttonStyle(.plain)
            }.padding(AXSpacing.lg)
            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    if let sections = plugin.onRowTap?.sections, !sections.isEmpty {
                        // Render JSON-defined sections
                        ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                            detailSection(title: section.title, icon: section.icon, fields: section.fields, row: row)
                        }
                    } else {
                        // Fallback: show all columns grouped
                        detailSection(title: "Details", icon: "info.circle", fields: columns.map { $0.key }, row: row)
                    }
                }
                .padding(AXSpacing.lg)
                .padding(.bottom, AXSpacing.xl)
            }

            // Action buttons at bottom
            if !rowActions.isEmpty {
                Divider().opacity(0.3)
                HStack(spacing: AXSpacing.sm) {
                    Spacer()
                    ForEach(Array(rowActions.enumerated()), id: \.offset) { _, action in
                        rowActionButton(action, row: row)
                    }
                }.padding(AXSpacing.lg)
            }
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 400, idealHeight: 500)
        .background(Color.axSurface)
    }

    @ViewBuilder
    private func detailSection(title: String, icon: String?, fields: [String], row: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            // Section header
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon).font(.system(size: 12, weight: .medium)).foregroundColor(.axAccentBlue)
                }
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.axTextPrimary)
            }.padding(.bottom, 2)

            VStack(spacing: 1) {
                ForEach(fields, id: \.self) { fieldKey in
                    let value = row[fieldKey] ?? "—"
                    let col = columns.first { $0.key == fieldKey }
                    HStack(alignment: .top, spacing: AXSpacing.md) {
                        HStack(spacing: 4) {
                            if let colIcon = col?.icon {
                                Image(systemName: colIcon).font(.system(size: 9)).foregroundColor(.axTextMuted)
                            }
                            Text(col?.label ?? fieldKey.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextSecondary)
                        }.frame(width: 120, alignment: .trailing)

                        // Styled cell value
                        detailCellValue(value: value, column: col)

                        Spacer()

                        // Copy button
                        if value != "—" {
                            CopyFieldButton(value: value)
                        }
                    }
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, 6)
                    .background(fields.firstIndex(of: fieldKey).map { $0 % 2 != 0 ? Color.axSurface.opacity(0.4) : Color.clear } ?? Color.clear)
                }
            }
            .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axBackground.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        }
    }

    @ViewBuilder
    private func detailCellValue(value: String, column: HookColumnDefinition?) -> some View {
        let colType = column?.type ?? .text
        switch colType {
        case .ip:
            HStack(spacing: 5) {
                Image(systemName: "network").font(.system(size: 9)).foregroundColor(.axTextMuted)
                Text(value).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
            }.padding(.horizontal, 6).padding(.vertical, 2).background(Color.axSurface).cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))
        case .status:
            statusBadge(value)
        case .badge:
            let badgeColor = badgeSeverityColor(value)
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(badgeColor)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(badgeColor.opacity(0.12)).cornerRadius(5)
        case .datetime:
            VStack(alignment: .leading, spacing: 2) {
                Text(relativeTime(value)).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextPrimary)
                Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted)
            }
        case .number:
            Text(formatNumber(value)).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
        case .bytes:
            Text(formatBytes(value)).font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextSecondary)
        default:
            Text(value).font(.system(size: 12)).foregroundColor(.axTextPrimary).textSelection(.enabled)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .medium)).foregroundColor(.axTextMuted)
                TextField("Search...", text: $searchText).font(.system(size: 13)).textFieldStyle(.plain).foregroundColor(.axTextPrimary)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(.axTextMuted)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            .frame(maxWidth: 280)
            Spacer()
            if !vm.rows.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "tablecells").font(.system(size: 10)).foregroundColor(.axTextMuted)
                    Text("\(filteredRows.count)").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.axTextSecondary)
                    Text("rows").font(.system(size: 11)).foregroundColor(.axTextMuted)
                }.padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.axSurface).cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))
            }
            if let interval = dataSource?.refreshInterval, interval > 0 {
                HStack(spacing: 4) {
                    Circle().fill(vm.isRefreshing ? Color.axWarning : Color.axSuccess).frame(width: 5, height: 5)
                        .opacity(vm.isRefreshing ? 0.3 : 1.0)
                        .animation(vm.isRefreshing ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default, value: vm.isRefreshing)
                    Text(vm.isRefreshing ? "Updating..." : "Live · \(Int(interval))s")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(vm.isRefreshing ? .axWarning : .axSuccess)
                }.padding(.horizontal, 8).padding(.vertical, 2)
                .background((vm.isRefreshing ? Color.axWarning : Color.axSuccess).opacity(0.08)).cornerRadius(AXCornerRadius.sm)
            }
            if !vm.rows.isEmpty {
                Menu {
                    Button(action: { exportData(format: .csv) }) { Label("Export CSV", systemImage: "tablecells") }
                    Button(action: { exportData(format: .json) }) { Label("Export JSON", systemImage: "curlybraces") }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 11, weight: .medium))
                        Text(L10n.PluginsUI.export).font(.system(size: 12, weight: .medium))
                    }.foregroundColor(.axTextSecondary).padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))
                }.menuStyle(.borderlessButton)
            }
            Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                        .animation(vm.isLoading ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: vm.isLoading)
                    Text(L10n.PluginsUI.refresh).font(.system(size: 12, weight: .semibold))
                }.foregroundColor(vm.isLoading ? .axTextMuted : .axAccentBlue)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(Color.axAccentBlue.opacity(vm.isLoading ? 0.05 : 0.1)).cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
            }.buttonStyle(.plain).disabled(vm.isLoading)
        }.padding(.horizontal, AXSpacing.xl).padding(.vertical, 4)
        .frame(height: 36)
    }

    private func columnHeaderFlex(_ col: HookColumnDefinition) -> some View {
        Button(action: {
            if sortColumn == col.key { sortAscending.toggle() }
            else { sortColumn = col.key; sortAscending = true }
        }) {
            HStack(spacing: 5) {
                if let icon = col.icon {
                    Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                        .foregroundColor(sortColumn == col.key ? .axAccentBlue : .axTextMuted)
                }
                Text(col.displayLabel.uppercased()).font(.system(size: 11, weight: .bold))
                    .foregroundColor(sortColumn == col.key ? .axAccentBlue : .axTextSecondary).tracking(0.5)
                if sortColumn == col.key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.axAccentBlue)
                }
                Spacer(minLength: 0)
            }.padding(.horizontal, 12)
        }.buttonStyle(.plain).frame(maxWidth: .infinity, maxHeight: 28, alignment: .leading)
        .layoutPriority(Double(col.width ?? 140))
    }

    private func dataRowFlex(row: [String: String], index: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)").font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted)
                .frame(width: 40, alignment: .center).padding(.vertical, 9)
            ForEach(columns, id: \.key) { col in cellView(value: row[col.key] ?? "—", column: col) }
            if hasRowActions {
                HStack(spacing: 6) {
                    ForEach(Array(rowActions.enumerated()), id: \.offset) { _, action in rowActionButton(action, row: row) }
                }.frame(width: CGFloat(rowActions.count) * 80 + 16).padding(.horizontal, 8)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).background(rowBackground(index: index))
        .contentShape(Rectangle()).onHover { hovered in hoveredRow = hovered ? index : nil }
        .overlay(Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1), alignment: .bottom)
    }

    private func rowBackground(index: Int) -> Color {
        if hoveredRow == index { return Color.axAccentBlue.opacity(0.06) }
        return index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.25)
    }

    // MARK: - Cell Views

    @ViewBuilder
    private func cellView(value: String, column: HookColumnDefinition, width: CGFloat? = nil) -> some View {
        let effectiveWidth = width ?? column.width ?? 140
        Group {
            switch column.type {
            case .bytes:
                Text(formatBytes(value)).font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextSecondary)
            case .percent:
                HStack(spacing: 6) {
                    let pct = Double(value) ?? 0
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Color.axBorder.opacity(0.4))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(pct > 80 ? Color.axError : pct > 60 ? Color.axWarning : Color.axSuccess)
                                .frame(width: geo.size.width * min(pct / 100.0, 1.0))
                        }
                    }.frame(width: 50, height: 4)
                    Text(String(format: "%.1f%%", pct)).font(.system(size: 11, design: .monospaced))
                        .foregroundColor(pct > 80 ? .axError : pct > 60 ? .axWarning : .axTextSecondary)
                }
            case .status: statusBadge(value)
            case .badge:
                let badgeColor = badgeSeverityColor(value)
                Text(value).font(.system(size: 10, weight: .semibold)).foregroundColor(badgeColor)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(badgeColor.opacity(0.12)).cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(badgeColor.opacity(0.25), lineWidth: 1))
            case .boolean:
                let isTrue = value.lowercased() == "true" || value == "1" || value.lowercased() == "yes"
                HStack(spacing: 4) {
                    Image(systemName: isTrue ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 13)).foregroundColor(isTrue ? .axSuccess : .axError)
                    Text(isTrue ? "Yes" : "No").font(.system(size: 11)).foregroundColor(isTrue ? .axSuccess : .axError)
                }
            case .ip:
                HStack(spacing: 5) {
                    Image(systemName: "network").font(.system(size: 9)).foregroundColor(.axTextMuted)
                    Text(value).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextPrimary)
                }.padding(.horizontal, 6).padding(.vertical, 3).background(Color.axSurface).cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))
            case .number:
                Text(formatNumber(value)).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
            case .url:
                Text(value).font(.system(size: 12)).foregroundColor(.axAccentBlue).lineLimit(1).truncationMode(.middle)
            default:
                Text(value).font(.system(size: 12)).foregroundColor(.axTextPrimary).lineLimit(1)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).layoutPriority(Double(effectiveWidth))
        .padding(.horizontal, 12).padding(.vertical, 9)
        .lineLimit(1)
    }

    @ViewBuilder
    private func statusBadge(_ value: String) -> some View {
        let httpCode = Int(value) ?? 0
        let (color, icon): (Color, String) = {
            if httpCode >= 500 { return (.axError, "xmark.circle.fill") }
            if httpCode >= 400 { return (.axWarning, "exclamationmark.circle.fill") }
            if httpCode >= 300 { return (.axAccentBlue, "arrow.right.circle.fill") }
            if httpCode >= 200 { return (.axSuccess, "checkmark.circle.fill") }
            switch value.lowercased() {
            case "active", "online", "running", "ok", "success", "enabled": return (.axSuccess, "checkmark.circle.fill")
            case "inactive", "offline", "stopped", "error", "failed", "disabled": return (.axError, "xmark.circle.fill")
            case "warning", "degraded", "pending": return (.axWarning, "exclamationmark.circle.fill")
            default: return (.axTextMuted, "circle.fill")
            }
        }()
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(color)
            Text(value).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundColor(color)
        }.padding(.horizontal, 7).padding(.vertical, 3).background(color.opacity(0.1)).cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle().stroke(Color.axBorder, lineWidth: 2).frame(width: 36, height: 36)
                Circle().trim(from: 0, to: 0.7).stroke(Color.axAccentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 36, height: 36).rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: vm.isLoading)
            }
            Text(L10n.PluginsUI.fetchingDataFromServer).font(.system(size: 13)).foregroundColor(.axTextMuted)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(AXSpacing.xxl)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle().fill(Color.axError.opacity(0.1)).frame(width: 52, height: 52)
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 22)).foregroundColor(.axError)
            }
            VStack(spacing: 6) {
                Text(L10n.PluginsUI.failedToLoadData).font(.system(size: 14, weight: .semibold)).foregroundColor(.axTextPrimary)
                Text(error).font(.system(size: 12)).foregroundColor(.axTextSecondary).multilineTextAlignment(.center).frame(maxWidth: 320)
            }
            Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                HStack(spacing: 5) { Image(systemName: "arrow.clockwise"); Text(L10n.PluginsUI.tryAgain) }
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.axAccentBlue.opacity(0.1)).cornerRadius(AXCornerRadius.md)
            }.buttonStyle(.plain)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(AXSpacing.xxl)
    }

    private var emptyView: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle().fill(Color.axSurface).frame(width: 52, height: 52)
                Image(systemName: "tray").font(.system(size: 22)).foregroundColor(.axTextMuted)
            }
            VStack(spacing: 4) {
                Text(L10n.PluginsUI.noData).font(.system(size: 14, weight: .semibold)).foregroundColor(.axTextSecondary)
                Text(L10n.PluginsUI.theCommandReturnedNoResults).font(.system(size: 12)).foregroundColor(.axTextMuted)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(AXSpacing.xxl)
    }

    // MARK: - Filtering & Sorting

    private var filteredRows: [[String: String]] {
        var rows = vm.rows

        // Apply column filters
        for (key, filterValue) in activeFilters where !filterValue.isEmpty {
            let filterDef = columnFilters.first { $0.key == key }
            if filterDef?.type == .text {
                rows = rows.filter { $0[key]?.localizedCaseInsensitiveContains(filterValue) ?? false }
            } else {
                rows = rows.filter { $0[key] == filterValue }
            }
        }

        // Apply search
        if !searchText.isEmpty {
            let keys = plugin.searchKeys ?? []
            rows = rows.filter { row in
                if keys.isEmpty {
                    return row.values.contains { $0.localizedCaseInsensitiveContains(searchText) }
                } else {
                    return keys.contains { key in row[key]?.localizedCaseInsensitiveContains(searchText) ?? false }
                }
            }
        }
        if let col = sortColumn {
            rows.sort {
                let a = $0[col] ?? ""; let b = $1[col] ?? ""
                if let da = Double(a), let db = Double(b) { return sortAscending ? da < db : da > db }
                return sortAscending ? a < b : a > b
            }
        }
        return rows
    }

    // MARK: - Row Actions

    private struct PendingRowAction {
        let button: HookRowActionButton
        let row: [String: String]
    }

    private func rowActionButton(_ action: HookRowActionButton, row: [String: String]) -> some View {
        let accentColor: Color = {
            switch action.style ?? .primary {
            case .danger: return .axError; case .warning: return .axWarning
            case .success: return .axSuccess; case .primary: return .axAccentBlue
            case .secondary, .ghost: return .axTextSecondary
            }
        }()
        return Button(action: {
            if action.confirmationMessage != nil {
                pendingAction = PendingRowAction(button: action, row: row)
                // Dismiss the detail sheet first, then show confirmation after animation
                if selectedDetailRow != nil {
                    selectedDetailRow = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showConfirmation = true }
                } else {
                    showConfirmation = true
                }
            } else { executeRowAction(action, row: row) }
        }) {
            HStack(spacing: 4) {
                if let icon = action.icon { Image(systemName: icon).font(.system(size: 10, weight: .medium)) }
                Text(action.label).font(.system(size: 10, weight: .semibold))
            }.foregroundColor(accentColor).padding(.horizontal, 8).padding(.vertical, 4)
            .background(accentColor.opacity(0.1)).cornerRadius(AXCornerRadius.sm)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(accentColor.opacity(0.25), lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private func executeRowAction(_ action: HookRowActionButton, row: [String: String]) {
        guard let command = action.command else {
            HookToastManager.shared.error("No command configured for this action")
            return
        }
        var mergedContext = context
        for (key, value) in row { mergedContext[key] = value }
        let interpolatedAction = interpolateTemplate(command.action, row: row)
        let interpolatedPayload = interpolatePayload(command.payload, row: row)
        let interpolatedCommand = HookPluginCommand(
            type: command.type, action: interpolatedAction, payload: interpolatedPayload,
            timeout: command.timeout, retries: command.retries, onSuccess: command.onSuccess, onError: command.onError
        )
        // Capture current table state before refresh
        let savedSort = sortColumn
        let savedSortAsc = sortAscending
        let savedPage = currentPage
        let savedFilters = activeFilters
        Task {
            await actionVM.execute(command: interpolatedCommand, pluginId: plugin.id, serverId: serverId, context: mergedContext, namespace: plugin.namespace)
            if actionVM.isSuccess {
                // HookPluginViewModel already fires onSuccess toast — only send default if not set
                if command.onSuccess == nil || command.onSuccess!.isEmpty {
                    HookToastManager.shared.success(interpolateTemplate("\(action.label) completed", row: row))
                }
                await vm.load(plugin: plugin, serverId: serverId, context: context)
                // Restore table state after reload
                sortColumn = savedSort
                sortAscending = savedSortAsc
                activeFilters = savedFilters
                let totalPages = max(1, Int(ceil(Double(filteredRows.count) / Double(plugin.dataSource?.pageSize ?? 50))))
                currentPage = min(savedPage, totalPages - 1)
            }
        }
    }

    private func interpolateTemplate(_ template: String, row: [String: String]) -> String {
        var result = template
        for (key, value) in row {
            result = result.replacingOccurrences(of: "{{row.\(key)}}", with: value)
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }

    private func interpolatePayload(_ payload: [String: AnyCodable]?, row: [String: String]) -> [String: AnyCodable]? {
        guard let payload = payload else { return nil }
        var result: [String: AnyCodable] = [:]
        for (key, val) in payload {
            if let str = val.value as? String {
                result[key] = AnyCodable(interpolateTemplate(str, row: row))
            } else {
                result[key] = val
            }
        }
        return result
    }

    // MARK: - Formatters

    private func formatBytes(_ value: String) -> String {
        guard let bytes = Double(value) else { return value }
        return AevonXCoreBridge.AXFormatter.formatBytes(bytes)
    }

    private func formatNumber(_ value: String) -> String {
        guard let num = Double(value) else { return value }
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? value
    }

    /// Convert ISO8601 / standard datetime strings to relative time ("5m ago", "2h ago")
    private func relativeTime(_ value: String) -> String {
        let formatters: [DateFormatter] = {
            let iso = DateFormatter(); iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let iso2 = DateFormatter(); iso2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let simple = DateFormatter(); simple.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return [iso, iso2, simple]
        }()
        var date: Date?
        for f in formatters { if let d = f.date(from: value) { date = d; break } }
        guard let d = date else { return value }
        let seconds = Int(Date().timeIntervalSince(d))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }

    /// Map badge values to semantic colors based on severity / status keywords
    private func badgeSeverityColor(_ value: String) -> Color {
        switch value.lowercased() {
        // Severity levels
        case "critical":                                          return .axError
        case "high":                                              return Color(red: 0.96, green: 0.62, blue: 0.04) // orange
        case "medium":                                            return .axWarning
        case "low":                                               return .axSuccess
        case "info", "informational":                             return .axAccentBlue
        // Status words
        case "open", "active", "enabled", "true", "yes", "running", "online":
            return .axSuccess
        case "resolved", "closed", "fixed", "done", "completed":  return Color(red: 0.4, green: 0.7, blue: 0.4)
        case "failed", "error", "disabled", "false", "no", "blocked", "offline":
            return .axError
        case "pending", "warning", "degraded", "skipped":         return .axWarning
        case "dry_run", "dry-run":                                return Color(red: 0.6, green: 0.5, blue: 0.9)
        default:                                                  return .axAccentBlue
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 11, weight: .medium)).foregroundColor(.axTextMuted)
            Text(L10n.PluginsUI.filters).font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextSecondary)

            ForEach(columnFilters, id: \.key) { filter in
                if filter.type == .select {
                    Menu {
                        Button("All") { activeFilters.removeValue(forKey: filter.key) }
                        Divider()
                        ForEach(uniqueValues(for: filter.key), id: \.self) { val in
                            Button(val) { activeFilters[filter.key] = val }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(activeFilters[filter.key] ?? filter.label)
                                .font(.system(size: 11, weight: activeFilters[filter.key] != nil ? .bold : .medium))
                                .foregroundColor(activeFilters[filter.key] != nil ? .axAccentBlue : .axTextSecondary)
                            Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold))
                                .foregroundColor(.axTextMuted)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(activeFilters[filter.key] != nil ? Color.axAccentBlue.opacity(0.1) : Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(activeFilters[filter.key] != nil ? Color.axAccentBlue.opacity(0.3) : Color.axBorder.opacity(0.6), lineWidth: 1))
                    }.menuStyle(.borderlessButton)
                } else {
                    TextField(filter.label, text: Binding(
                        get: { activeFilters[filter.key] ?? "" },
                        set: { activeFilters[filter.key] = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 11)).textFieldStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.axSurface).cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.6), lineWidth: 1))
                    .frame(maxWidth: 120)
                }
            }

            if !activeFilters.isEmpty {
                Button(action: { activeFilters.removeAll() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 10))
                        Text(L10n.PluginsUI.clear).font(.system(size: 10, weight: .medium))
                    }.foregroundColor(.axTextMuted)
                }.buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl).padding(.vertical, 4)
        .background(Color.axSurface.opacity(0.3))
    }

    /// Get unique values for a column (for filter dropdowns)
    private func uniqueValues(for key: String) -> [String] {
        let values = Set(vm.rows.compactMap { $0[key] }.filter { !$0.isEmpty })
        return values.sorted()
    }

    // MARK: - Export

    private enum ExportFormat { case csv, json }

    private func exportData(format: ExportFormat) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(plugin.name.replacingOccurrences(of: " ", with: "_"))_export"
        switch format {
        case .csv: panel.allowedContentTypes = [.commaSeparatedText]; panel.nameFieldStringValue += ".csv"
        case .json: panel.allowedContentTypes = [.json]; panel.nameFieldStringValue += ".json"
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let rows = filteredRows; var content = ""
        switch format {
        case .csv:
            content = columns.map { $0.displayLabel }.joined(separator: ",") + "\n"
            for row in rows {
                let line = columns.map { col in
                    let val = row[col.key] ?? ""
                    return val.contains(",") || val.contains("\"") ? "\"\(val.replacingOccurrences(of: "\"", with: "\"\""))\"" : val
                }.joined(separator: ",")
                content += line + "\n"
            }
        case .json:
            let jsonArray = rows.map { row in
                var dict: [String: String] = [:]
                for col in columns { dict[col.key] = row[col.key] ?? "" }
                return dict
            }
            if let data = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted),
               let json = String(data: data, encoding: .utf8) { content = json }
        }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            HookToastManager.shared.success("Exported \(rows.count) rows to \(url.lastPathComponent)")
        } catch { HookToastManager.shared.error("Export failed: \(error.localizedDescription)") }
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
    private var hasLoadedOnce: Bool = false
    private var refreshTask: Task<Void, Never>? = nil

    /// Wipes all row state so stale data from a previous plugin doesn't
    /// leak into the new tab. Must be called before `load` whenever the
    /// caller is switching to a DIFFERENT plugin (new plugin.id).
    ///
    /// Without this, SwiftUI re-uses the same @StateObject across
    /// sidebar tabs (sidebar_detail keeps one PluginDataTableComponent
    /// instance); the old tab's rows render with the new tab's columns,
    /// producing "3 rows of dashes" flicker before the fetch completes.
    func resetForNewPlugin() {
        refreshTask?.cancel()
        refreshTask = nil
        rows = []
        // Flip isLoading true so the view shows the skeleton/progress state
        // immediately — without this there's a visible "No data" flash while
        // the first fetch for the new plugin is still in flight.
        isLoading = true
        isRefreshing = false
        errorMessage = nil
        lastUpdated = nil
        hasLoadedOnce = false
    }

    func load(plugin: HookPluginDefinition, serverId: String, context: [String: String]) async {
        guard let ds = plugin.dataSource else { return }
        if hasLoadedOnce { isRefreshing = true } else { isLoading = true }
        errorMessage = nil
        do {
            let result = try await HookCommandDispatcher.shared.fetchData(
                action: ds.action, payload: ds.payload, format: ds.format ?? .json, rowsPath: ds.rowsPath,
                serverId: serverId, context: context, type: ds.type, namespace: plugin.namespace, transform: ds.transform, keyColumn: ds.keyColumn
            )
            rows = result; lastUpdated = Date(); hasLoadedOnce = true; errorMessage = nil
        } catch {
            if !hasLoadedOnce {
                errorMessage = error.localizedDescription
            } else {
                HookToastManager.shared.warning("Data refresh failed: \(error.localizedDescription)")
            }
        }
        isLoading = false; isRefreshing = false
        if let interval = ds.refreshInterval, interval > 0 {
            refreshTask?.cancel()
            refreshTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !Task.isCancelled { await load(plugin: plugin, serverId: serverId, context: context) }
            }
        }
    }

    func cancelRefresh() { refreshTask?.cancel(); refreshTask = nil }
}

// MARK: - Copy Button with feedback

private struct CopyFieldButton: View {
    let value: String
    @State private var copied = false

    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            withAnimation(.easeInOut(duration: 0.2)) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) { copied = false }
            }
        }) {
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.system(size: copied ? 12 : 11, weight: .medium))
                .foregroundColor(copied ? .axSuccess : .axTextSecondary)
                .frame(width: 22, height: 22)
                .background(copied ? Color.axSuccess.opacity(0.15) : Color.axTextMuted.opacity(0.08))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }
}
