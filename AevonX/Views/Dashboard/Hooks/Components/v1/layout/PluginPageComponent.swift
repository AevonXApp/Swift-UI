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

    @ObservedObject private var registry = HookRegistry.shared

    private var hasTabs: Bool { if let tabs = plugin.tabs, !tabs.isEmpty { return true }; return false }
    private var isSelfContained: Bool { plugin.component == .dataTable || plugin.component == .chart }

    /// Build a HookNamespace from the plugin's namespace string — used to feed PluginControlBar
    private var hookNamespace: HookNamespace? {
        guard let ns = plugin.namespace else { return nil }
        let manifest = registry.manifests[ns]
        let plugins = registry.plugins(inNamespace: ns)
        return HookNamespace(id: ns, manifest: manifest, plugins: plugins)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if hasTabs { tabbedPageContent }
            else {
                if !isSelfContained { pageHeader; Divider() }
                pageContent
            }
        }.background(Color.axBackground)
    }

    // MARK: - Tabbed Page

    @ViewBuilder
    private var tabbedPageContent: some View {
        let tabs = plugin.tabs ?? []
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axAccentBlue.opacity(0.15)).frame(width: 40, height: 40)
                        Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name).font(AXTypography.title2).fontWeight(.bold).foregroundColor(.axTextPrimary)
                    if let desc = plugin.description { Text(desc).font(AXTypography.subheadline).foregroundColor(.axTextSecondary) }
                }
                Spacer(); pluginBadge
            }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.lg).padding(.bottom, AXSpacing.sm)

            // Service control bar — shown when the namespace has a health_check in its manifest
            if let ns = hookNamespace, ns.manifest?.healthCheck != nil {
                PluginControlBar(namespace: ns, serverId: serverId)
                    .padding(.horizontal, AXSpacing.xxl).padding(.bottom, AXSpacing.sm)
            }

            HStack(spacing: 2) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTabIndex = index } }) {
                        HStack(spacing: 6) {
                            if let icon = tab.icon { Image(systemName: icon).font(.system(size: 11, weight: .medium)) }
                            Text(tab.name).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(selectedTabIndex == index ? .axAccentBlue : .axTextMuted)
                        .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)
                        .background(Group { if selectedTabIndex == index { RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.1)) } })
                        .overlay(VStack { Spacer(); if selectedTabIndex == index { Rectangle().fill(Color.axAccentBlue).frame(height: 2).cornerRadius(1) } })
                    }.buttonStyle(.plain)
                }
                Spacer()
            }.padding(.horizontal, AXSpacing.xxl).background(Color.axSurface.opacity(0.4))
            Divider().opacity(0.3)
            activeTabContent(from: tabs)
        }
    }

    private func activeTabContent(from tabs: [HookPluginDefinition]) -> some View {
        let safeIndex = min(max(0, selectedTabIndex), tabs.count - 1)
        var activeTab = tabs[safeIndex]; activeTab.namespace = plugin.namespace
        return PluginPageComponent(plugin: activeTab, serverId: serverId, context: context)
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack(spacing: AXSpacing.md) {
            if let icon = plugin.icon {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axAccentBlue.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(.axAccentBlue)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name).font(AXTypography.title2).fontWeight(.bold).foregroundColor(.axTextPrimary)
                if let desc = plugin.description { Text(desc).font(AXTypography.subheadline).foregroundColor(.axTextSecondary) }
            }
            Spacer(); pluginBadge
        }.padding(.horizontal, AXSpacing.xxl).padding(.vertical, AXSpacing.lg).background(Color.axSurface.opacity(0.4))
    }

    private var pluginBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "puzzlepiece.fill").font(.system(size: 9))
            Text("Plugin").font(.system(size: 10, weight: .semibold))
        }.foregroundColor(.axTextMuted).padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1)))
    }

    // MARK: - Content Router

    @ViewBuilder
    private var pageContent: some View {
        switch plugin.component {
        case .dataTable: PluginDataTableComponent(plugin: plugin, serverId: serverId, context: context)
        case .chart: PluginChartComponent(plugin: plugin, serverId: serverId, context: context)
        default:
            if let layout = plugin.layout {
                ScrollView { layoutContent(layout).padding(.bottom, AXSpacing.xl) }
            } else { emptyState }
        }
    }

    // MARK: - Layout Renderers

    @ViewBuilder
    private func layoutContent(_ layout: HookPluginLayout) -> some View {
        switch layout.type {
        case .overview: overviewLayout(layout)
        case .table: tableLayout(layout)
        case .grid, .cardsDetails: gridLayout(layout)
        case .split: splitLayout(layout)
        case .dashboard: dashboardLayout(layout)
        case .tabs: tabsLayout(layout)
        }
    }

    @ViewBuilder
    private func tabsLayout(_ layout: HookPluginLayout) -> some View {
        let tabs = layout.tabs ?? []
        if tabs.isEmpty { EmptyView() }
        else {
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTabIndex = index } }) {
                            HStack(spacing: 6) {
                                if let icon = tab.icon { Image(systemName: icon).font(.system(size: 11, weight: .medium)) }
                                Text(tab.title).font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(selectedTabIndex == index ? .axAccentBlue : .axTextMuted)
                            .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)
                            .background(Group { if selectedTabIndex == index { RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.1)) } })
                            .overlay(VStack { Spacer(); if selectedTabIndex == index { Rectangle().fill(Color.axAccentBlue).frame(height: 2).cornerRadius(1) } })
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.md).background(Color.axSurface.opacity(0.4))
                Divider().opacity(0.3)
                let safeIndex = min(selectedTabIndex, tabs.count - 1)
                let activeTab = tabs[max(0, safeIndex)]
                ScrollView {
                    dashboardCardsContent(cards: activeTab.cards ?? [], columns: activeTab.columns ?? layout.columns ?? 2)
                        .padding(.bottom, AXSpacing.xl)
                }
            }
        }
    }

    @ViewBuilder
    private func dashboardCardsContent(cards: [HookLayoutCard], columns: Int) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            let statCards = cards.filter { $0.component == .statsCard || ($0.command == nil && $0.component != .dataTable && $0.component != .form && $0.component != .chart) }
            if !statCards.isEmpty {
                let chunkedStats = stride(from: 0, to: statCards.count, by: 4).map { Array(statCards[$0..<min($0 + 4, statCards.count)]) }
                ForEach(Array(chunkedStats.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: AXSpacing.md) {
                        ForEach(Array(row), id: \.title) { card in
                            DashboardStatPill(card: card, serverId: serverId, context: context, namespace: plugin.namespace)
                        }
                    }
                }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.lg)
            }
            let chartCards = cards.filter { $0.component == .chart }
            if !chartCards.isEmpty {
                let chartCols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: min(chartCards.count, 2))
                LazyVGrid(columns: chartCols, spacing: AXSpacing.lg) {
                    ForEach(chartCards, id: \.title) { card in DashboardChartCard(card: card, serverId: serverId, context: context, namespace: plugin.namespace) }
                }.padding(.horizontal, AXSpacing.xxl)
            }
            let actionCards = cards.filter { $0.command != nil && $0.component != .form }
            if !actionCards.isEmpty {
                let cols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: columns)
                LazyVGrid(columns: cols, spacing: AXSpacing.lg) {
                    ForEach(actionCards, id: \.title) { card in PluginLayoutCardView(card: card, serverId: serverId, context: context, namespace: plugin.namespace) }
                }.padding(.horizontal, AXSpacing.xxl)
            }
            let tableCards = cards.filter { $0.component == .dataTable }
            if !tableCards.isEmpty {
                ForEach(tableCards, id: \.title) { card in DashboardDataTableCard(card: card, serverId: serverId, context: context, namespace: plugin.namespace) }
            }
            let formCards = cards.filter { $0.component == .form }
            if !formCards.isEmpty {
                ForEach(formCards, id: \.title) { card in
                    PluginFormComponent(plugin: cardToPlugin(card), serverId: serverId, context: context).padding(.horizontal, AXSpacing.xxl)
                }
            }
        }
    }

    private func cardToPlugin(_ card: HookLayoutCard) -> HookPluginDefinition {
        HookPluginDefinition(id: "card_\(card.title.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: card.title, description: card.description, hook: .sidebarTabs,
            component: card.component ?? .form, icon: card.icon, command: card.command,
            namespace: plugin.namespace, fields: card.fields)
    }

    @ViewBuilder private func dashboardLayout(_ layout: HookPluginLayout) -> some View {
        dashboardCardsContent(cards: layout.cards ?? [], columns: layout.columns ?? 2)
    }

    @ViewBuilder private func gridLayout(_ layout: HookPluginLayout) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: layout.columns ?? 2)
        LazyVGrid(columns: cols, spacing: AXSpacing.lg) {
            ForEach(layout.cards ?? [], id: \.title) { card in PluginLayoutCardView(card: card, serverId: serverId, context: context) }
        }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.lg)
    }

    @ViewBuilder private func overviewLayout(_ layout: HookPluginLayout) -> some View {
        VStack(spacing: AXSpacing.lg) {
            ForEach(layout.cards ?? [], id: \.title) { card in PluginLayoutCardView(card: card, serverId: serverId, context: context) }
        }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.lg)
    }

    @ViewBuilder private func tableLayout(_ layout: HookPluginLayout) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            ForEach(layout.cards ?? [], id: \.title) { card in PluginLayoutCardView(card: card, serverId: serverId, context: context) }
        }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.lg)
    }

    @ViewBuilder private func splitLayout(_ layout: HookPluginLayout) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.lg) {
            let cards = layout.cards ?? []; let mid = cards.count / 2
            VStack(spacing: AXSpacing.md) { ForEach(cards.prefix(mid), id: \.title) { card in PluginLayoutCardView(card: card, serverId: serverId, context: context) } }
            VStack(spacing: AXSpacing.md) { ForEach(cards.dropFirst(mid), id: \.title) { card in PluginLayoutCardView(card: card, serverId: serverId, context: context) } }
        }.padding(.horizontal, AXSpacing.xxl).padding(.top, AXSpacing.lg)
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: plugin.icon ?? "puzzlepiece").font(.system(size: 40)).foregroundColor(.axTextMuted)
            Text("No layout defined for this plugin").font(AXTypography.body).foregroundColor(.axTextMuted)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(AXSpacing.xxl)
    }
}
