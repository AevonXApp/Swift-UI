//
//  PluginPageComponent.swift
//  AevonX
//
//  Full-page plugin renderer.
//  Handles: data_table, chart, and layout-based (cards, overview, grid, dashboard, split) plugins.
//

import SwiftUI
import AevonXCore

// MARK: - Notifications
extension Notification.Name {
    static let pluginScanCompleted = Notification.Name("pluginScanCompleted")
}

// MARK: - Plugin Page Component

public struct PluginPageComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @State private var selectedTabIndex: Int = 0

    /// Components that manage their own toolbar/header and should not receive
    /// an additional page header from this wrapper.
    private var isSelfContained: Bool {
        plugin.component == .dataTable || plugin.component == .chart
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !isSelfContained {
                pageHeader
                Divider()
            }
            pageContent
        }
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack(spacing: AXSpacing.md) {
            if let icon = plugin.icon {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axAccentBlue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                if let desc = plugin.description {
                    Text(desc)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                }
            }

            Spacer()

            // Plugin badge
            pluginBadge
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.lg)
        .background(Color.axSurface.opacity(0.4))
    }

    private var pluginBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 9))
            Text("Plugin")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.axTextMuted)
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
        )
    }

    // MARK: - Content Router

    @ViewBuilder
    private var pageContent: some View {
        switch plugin.component {
        case .dataTable:
            // Full-page data table — fills the entire content area
            PluginDataTableComponent(plugin: plugin, serverId: serverId, context: context)

        case .chart:
            // Full-page chart
            PluginChartComponent(plugin: plugin, serverId: serverId, context: context)

        default:
            // Layout-based rendering (cards, overview, grid, dashboard, split)
            if let layout = plugin.layout {
                ScrollView {
                    layoutContent(layout)
                        .padding(.bottom, AXSpacing.xl)
                }
            } else {
                emptyState
            }
        }
    }

    // MARK: - Layout Renderers

    @ViewBuilder
    private func layoutContent(_ layout: HookPluginLayout) -> some View {
        switch layout.type {
        case .overview:
            overviewLayout(layout)
        case .table:
            tableLayout(layout)
        case .grid, .cardsDetails:
            gridLayout(layout)
        case .split:
            splitLayout(layout)
        case .dashboard:
            dashboardLayout(layout)
        case .tabs:
            tabsLayout(layout)
        }
    }

    // Tabs: segmented tab bar + per-tab content
    @ViewBuilder
    private func tabsLayout(_ layout: HookPluginLayout) -> some View {
        let tabs = layout.tabs ?? []
        guard !tabs.isEmpty else { return }

        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 2) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTabIndex = index
                        }
                    }) {
                        HStack(spacing: 6) {
                            if let icon = tab.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            Text(tab.title)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(selectedTabIndex == index ? .axAccentBlue : .axTextMuted)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            Group {
                                if selectedTabIndex == index {
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .fill(Color.axAccentBlue.opacity(0.1))
                                }
                            }
                        )
                        .overlay(
                            VStack {
                                Spacer()
                                if selectedTabIndex == index {
                                    Rectangle()
                                        .fill(Color.axAccentBlue)
                                        .frame(height: 2)
                                        .cornerRadius(1)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.top, AXSpacing.md)
            .background(Color.axSurface.opacity(0.4))

            Divider().opacity(0.3)

            // Tab content
            let safeIndex = min(selectedTabIndex, tabs.count - 1)
            let activeTab = tabs[max(0, safeIndex)]

            ScrollView {
                dashboardCardsContent(
                    cards: activeTab.cards ?? [],
                    columns: activeTab.columns ?? layout.columns ?? 2
                )
                .padding(.bottom, AXSpacing.xl)
            }
        }
    }

    /// Reusable card rendering for both dashboard and tabs
    @ViewBuilder
    private func dashboardCardsContent(cards: [HookLayoutCard], columns: Int) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // 1. Stats row
            let statCards = cards.filter {
                $0.component == .statsCard || ($0.command == nil && $0.component != .dataTable && $0.component != .form)
            }.prefix(4)
            if !statCards.isEmpty {
                HStack(spacing: AXSpacing.md) {
                    ForEach(Array(statCards), id: \.title) { card in
                        DashboardStatPill(card: card, serverId: serverId, context: context, namespace: plugin.namespace)
                    }
                }
                .padding(.horizontal, AXSpacing.xxl)
                .padding(.top, AXSpacing.lg)
            }

            // 2. Action cards grid
            let actionCards = cards.filter { $0.command != nil }
            if !actionCards.isEmpty {
                let cols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: columns)
                LazyVGrid(columns: cols, spacing: AXSpacing.lg) {
                    ForEach(actionCards, id: \.title) { card in
                        PluginLayoutCardView(card: card, serverId: serverId, context: context, namespace: plugin.namespace)
                    }
                }
                .padding(.horizontal, AXSpacing.xxl)
            }

            // 3. Data tables
            let tableCards = cards.filter { $0.component == .dataTable }
            if !tableCards.isEmpty {
                ForEach(tableCards, id: \.title) { card in
                    DashboardDataTableCard(card: card, serverId: serverId, context: context, namespace: plugin.namespace)
                }
            }

            // 4. Form cards
            let formCards = cards.filter { $0.component == .form }
            if !formCards.isEmpty {
                ForEach(formCards, id: \.title) { card in
                    PluginFormComponent(
                        plugin: cardToPlugin(card),
                        serverId: serverId,
                        context: context
                    )
                    .padding(.horizontal, AXSpacing.xxl)
                }
            }
        }
    }

    /// Convert a layout card to a minimal HookPluginDefinition for embedded components
    private func cardToPlugin(_ card: HookLayoutCard) -> HookPluginDefinition {
        HookPluginDefinition(
            id: "card_\(card.title.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: card.title,
            description: card.description,
            hook: .sidebarTabs,
            component: card.component ?? .form,
            icon: card.icon,
            command: card.command,
            fields: card.fields,
            namespace: plugin.namespace
        )
    }

    // Dashboard: delegates to shared dashboardCardsContent
    @ViewBuilder
    private func dashboardLayout(_ layout: HookPluginLayout) -> some View {
        dashboardCardsContent(cards: layout.cards ?? [], columns: layout.columns ?? 2)
    }

    @ViewBuilder
    private func gridLayout(_ layout: HookPluginLayout) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: layout.columns ?? 2)
        LazyVGrid(columns: cols, spacing: AXSpacing.lg) {
            ForEach(layout.cards ?? [], id: \.title) { card in
                PluginLayoutCardView(card: card, serverId: serverId, context: context)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.top, AXSpacing.lg)
    }

    @ViewBuilder
    private func overviewLayout(_ layout: HookPluginLayout) -> some View {
        VStack(spacing: AXSpacing.lg) {
            ForEach(layout.cards ?? [], id: \.title) { card in
                PluginLayoutCardView(card: card, serverId: serverId, context: context)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.top, AXSpacing.lg)
    }

    @ViewBuilder
    private func tableLayout(_ layout: HookPluginLayout) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            ForEach(layout.cards ?? [], id: \.title) { card in
                PluginLayoutCardView(card: card, serverId: serverId, context: context)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.top, AXSpacing.lg)
    }

    @ViewBuilder
    private func splitLayout(_ layout: HookPluginLayout) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.lg) {
            let cards = layout.cards ?? []
            let mid = cards.count / 2
            VStack(spacing: AXSpacing.md) {
                ForEach(cards.prefix(mid), id: \.title) { card in
                    PluginLayoutCardView(card: card, serverId: serverId, context: context)
                }
            }
            VStack(spacing: AXSpacing.md) {
                ForEach(cards.dropFirst(mid), id: \.title) { card in
                    PluginLayoutCardView(card: card, serverId: serverId, context: context)
                }
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.top, AXSpacing.lg)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: plugin.icon ?? "puzzlepiece")
                .font(.system(size: 40))
                .foregroundColor(.axTextMuted)
            Text("No layout defined for this plugin")
                .font(AXTypography.body)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xxl)
    }
}

// MARK: - Dashboard Stat Pill

private struct DashboardStatPill: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil
    @StateObject private var vm = HookPluginViewModel()
    @State private var displayValue: String?
    @State private var statusColor: Color = .axAccentBlue

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                if let icon = card.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor)
                }
                Text(card.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            if let value = displayValue, !value.isEmpty {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            } else if vm.isLoading {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
                        .scaleEffect(0.6)
                    Text("Loading…")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            } else {
                Text("—")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.axTextMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(statusColor.opacity(0.3), lineWidth: 1))
        )
        .task {
            await loadStatData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginScanCompleted)) { _ in
            Task {
                displayValue = nil
                await loadStatData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadStatData() async {
        guard let ds = card.dataSource else { return }

        // Build a HookPluginCommand from the data_source
        let command = HookPluginCommand(
            type: ds.type ?? .coreCmd,
            action: ds.action,
            payload: ds.payload,
            timeout: 15
        )

        await vm.execute(
            command: command,
            pluginId: "stat_\(card.title)",
            serverId: serverId,
            context: context,
            namespace: namespace
        )

        // Parse the JSON output to extract a display-friendly value
        guard let output = vm.resultOutput,
              let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        parseStatValue(from: json)
    }

    private func parseStatValue(from json: [String: Any]) {
        let title = card.title.lowercased()

        if title.contains("service") || title.contains("status") {
            // Service Status card
            let statusText = json["status_text"] as? String ?? "Unknown"
            let status = json["status"] as? String ?? ""
            let version = json["version"] as? String ?? ""

            if status == "active" {
                statusColor = .axSuccess
                displayValue = "✓ \(statusText)"
                if !version.isEmpty && version != "unknown" {
                    let cleanVersion = version.hasPrefix("v") ? String(version.dropFirst()) : version
                    displayValue = "✓ \(statusText) · v\(cleanVersion)"
                }
            } else {
                statusColor = .axError
                displayValue = "✗ \(statusText)"
            }

        } else if title.contains("scan") || title.contains("summary") {
            // Last Scan Summary card
            let totalFindings = json["total_findings"] as? Int ?? 0
            let filesScanned = json["files_scanned"] as? Int ?? 0

            statusColor = totalFindings > 0 ? .axWarning : .axSuccess
            if filesScanned > 0 {
                displayValue = "\(totalFindings) findings · \(filesScanned) files"
            } else {
                let msg = json["message"] as? String ?? "No scans yet"
                displayValue = msg
            }

        } else if title.contains("policy") || title.contains("gate") {
            // Policy Gate card
            let policyPass = json["policy_pass"] as? Bool ?? true
            let riskScore = json["risk_score"] as? Int ?? 0

            if policyPass {
                statusColor = .axSuccess
                displayValue = "✓ PASS"
                if riskScore > 0 { displayValue = "✓ PASS · Risk \(riskScore)" }
            } else {
                statusColor = .axError
                displayValue = "✗ FAIL · Risk \(riskScore)"
            }

        } else if title.contains("severity") || title.contains("distribution") {
            // Severity Distribution card
            if let bySeverity = json["by_severity"] as? [[String: Any]], !bySeverity.isEmpty {
                let parts = bySeverity.compactMap { item -> String? in
                    guard let label = item["label"] as? String,
                          let value = item["value"] else { return nil }
                    return "\(value) \(label)"
                }
                displayValue = parts.joined(separator: " · ")
                statusColor = .axAccentBlue
            } else {
                let totalFindings = json["total_findings"] as? Int ?? 0
                displayValue = totalFindings > 0 ? "\(totalFindings) total" : "No findings"
                statusColor = totalFindings > 0 ? .axWarning : .axSuccess
            }

        } else {
            // Generic fallback — show first meaningful value
            if let msg = json["message"] as? String {
                displayValue = msg
            } else {
                let values = json.values.compactMap { "\($0)" }.prefix(2).joined(separator: " · ")
                displayValue = values
            }
            statusColor = .axAccentBlue
        }
    }
}

// MARK: - Dashboard Data Table Card

/// Wraps a HookLayoutCard with component == data_table into a full-width PluginDataTableComponent
private struct DashboardDataTableCard: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil
    @State private var refreshID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: AXSpacing.sm) {
                if let icon = card.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentBlue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    if let desc = card.description {
                        Text(desc)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.vertical, AXSpacing.md)

            // Data table — build a plugin definition from the card's data
            PluginDataTableComponent(
                plugin: buildPluginDefinition(),
                serverId: serverId,
                context: context
            )
            .id(refreshID) // Force reload on scan completion
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginScanCompleted)) { _ in
            refreshID = UUID()
        }
    }

    /// Convert the card into a HookPluginDefinition so PluginDataTableComponent can consume it
    private func buildPluginDefinition() -> HookPluginDefinition {
        HookPluginDefinition(
            id: "dashboard_table_\(card.title.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: card.title,
            description: card.description,
            version: nil,
            enabled: true,
            hook: .sidebarTabs,
            component: .dataTable,
            label: nil,
            icon: card.icon,
            style: nil,
            command: nil,
            layout: nil,
            dataSource: card.dataSource,
            columns: card.columns,
            conditions: nil,
            permissions: nil,
            confirmationMessage: nil,
            chartType: nil,
            dependencies: nil,
            namespace: namespace
        )
    }
}

// MARK: - Layout Card View

struct PluginLayoutCardView: View {

    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil

    @StateObject private var vm = HookPluginViewModel()
    @State private var showProgress = false
    @State private var progressData: ScanProgressData?
    @State private var pollingTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Card header
            HStack(spacing: AXSpacing.sm) {
                if let icon = card.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentBlue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    if let desc = card.description {
                        Text(desc)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer()

                // Status indicator
                if vm.isSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.axSuccess)
                        .font(.system(size: 14))
                }

                // Toggle progress visibility
                if progressData != nil {
                    Button(action: { withAnimation { showProgress.toggle() } }) {
                        Image(systemName: showProgress ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Progress section (toggleable)
            if showProgress, let progress = progressData {
                scanProgressView(progress)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Output area (when no progress is shown)
            if !showProgress, let output = vm.resultOutput, !output.isEmpty {
                ScrollView {
                    Text(output)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
                .padding(AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axBackground)
                )
            }

            if let error = vm.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(error)
                        .font(AXTypography.caption2)
                }
                .foregroundColor(.axError)
            }

            // Action button
            if let command = card.command {
                Button(action: {
                    Task {
                        await vm.execute(
                            command: command,
                            pluginId: "card_\(card.title)",
                            serverId: serverId,
                            context: context,
                            namespace: namespace
                        )
                        // Start polling progress if this is a scan command
                        if command.action.contains("scan") {
                            startProgressPolling()
                            // Post refresh notification after delay for stats + table to reload
                            Task {
                                try? await Task.sleep(nanoseconds: 4_000_000_000)
                                NotificationCenter.default.post(name: .pluginScanCompleted, object: nil)
                            }
                        }
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                                .scaleEffect(0.65)
                        } else if vm.isSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.axSuccess)
                        } else if let icon = card.icon {
                            Image(systemName: icon)
                                .font(.system(size: 11))
                        }
                        Text(vm.isSuccess ? "Done" : "Run")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(vm.isSuccess ? .axSuccess : .axAccentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(vm.isSuccess ? Color.axSuccess.opacity(0.08) : Color.axAccentBlue.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(vm.isSuccess ? Color.axSuccess.opacity(0.3) : Color.axAccentBlue.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .onDisappear {
            pollingTask?.cancel()
        }
    }

    // MARK: - Progress View

    @ViewBuilder
    private func scanProgressView(_ progress: ScanProgressData) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Scanning…")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    Text("\(Int(progress.progress))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(progress.status == "done" ? .axSuccess : .axAccentBlue)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.axBackground)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress.status == "done" ? Color.axSuccess : Color.axAccentBlue)
                            .frame(width: geometry.size.width * CGFloat(progress.progress / 100), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress.progress)
                    }
                }
                .frame(height: 8)
            }

            // Stats row
            HStack(spacing: AXSpacing.lg) {
                statLabel(icon: "doc.fill", value: "\(progress.filesScanned)/\(progress.filesTotal)", label: "Files")
                statLabel(icon: "exclamationmark.triangle.fill", value: "\(progress.findingsSoFar)", label: "Findings")
                if progress.status == "done" {
                    statLabel(icon: "checkmark.circle.fill", value: "Complete", label: "Status")
                }
            }

            // Current file
            if !progress.currentFile.isEmpty && progress.status != "done" {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.axAccentBlue)
                    Text(progress.currentFile.components(separatedBy: "/").suffix(3).joined(separator: "/"))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axBackground)
        )
    }

    private func statLabel(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.axTextMuted)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
        }
    }

    // MARK: - Progress Polling

    private func startProgressPolling() {
        showProgress = true
        pollingTask?.cancel()

        pollingTask = Task {
            // Use plugin_cmd with 'progress' action if namespace is available
            let cmdType: HookCommandType = namespace != nil ? .pluginCmd : .coreCmd
            let actionName = namespace != nil ? "progress" : "phpscan.scan.progress"

            let progressCmd = HookPluginCommand(
                type: cmdType,
                action: actionName
            )
            let progressVM = HookPluginViewModel()

            while !Task.isCancelled {
                // First poll quickly, then slow down
                let delay: UInt64 = progressData == nil ? 500_000_000 : 2_000_000_000
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { break }

                await progressVM.execute(
                    command: progressCmd,
                    pluginId: "progress_poll",
                    serverId: serverId,
                    context: context,
                    namespace: namespace
                )

                if let output = progressVM.resultOutput,
                   let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    await MainActor.run {
                        progressData = ScanProgressData(
                            status: json["status"] as? String ?? "idle",
                            progress: json["progress"] as? Double ?? 0,
                            filesTotal: json["files_total"] as? Int ?? 0,
                            filesScanned: json["files_scanned"] as? Int ?? 0,
                            currentFile: json["current_file"] as? String ?? "",
                            findingsSoFar: json["findings_so_far"] as? Int ?? 0
                        )
                    }

                    let status = json["status"] as? String ?? ""
                    if status == "done" || status == "idle" {
                        break // Stop polling when done
                    }
                }
            }
        }
    }
}

// MARK: - Scan Progress Data

struct ScanProgressData {
    let status: String
    let progress: Double
    let filesTotal: Int
    let filesScanned: Int
    let currentFile: String
    let findingsSoFar: Int
}
