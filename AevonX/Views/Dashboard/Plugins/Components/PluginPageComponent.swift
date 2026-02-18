//
//  PluginPageComponent.swift
//  AevonX
//
//  Full-page plugin renderer.
//  Handles: data_table, chart, and layout-based (cards, overview, grid, dashboard, split) plugins.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Page Component

public struct PluginPageComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

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
        }
    }

    // Dashboard: stats row + cards grid
    @ViewBuilder
    private func dashboardLayout(_ layout: HookPluginLayout) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            let cards = layout.cards ?? []

            // Stats row (first 4 cards without commands become stat pills)
            let statCards = cards.filter { $0.command == nil }.prefix(4)
            if !statCards.isEmpty {
                HStack(spacing: AXSpacing.md) {
                    ForEach(Array(statCards), id: \.title) { card in
                        DashboardStatPill(card: card, serverId: serverId, context: context)
                    }
                }
                .padding(.horizontal, AXSpacing.xxl)
                .padding(.top, AXSpacing.lg)
            }

            // Action cards grid
            let actionCards = cards.filter { $0.command != nil }
            if !actionCards.isEmpty {
                let cols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: layout.columns ?? 2)
                LazyVGrid(columns: cols, spacing: AXSpacing.lg) {
                    ForEach(actionCards, id: \.title) { card in
                        PluginLayoutCardView(card: card, serverId: serverId, context: context)
                    }
                }
                .padding(.horizontal, AXSpacing.xxl)
            }
        }
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
    @StateObject private var vm = HookPluginViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = card.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(card.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            if let output = vm.resultOutput, !output.isEmpty {
                Text(output.prefix(40))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            } else if vm.isLoading {
                ProgressView().scaleEffect(0.6)
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
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        )
    }
}

// MARK: - Layout Card View

struct PluginLayoutCardView: View {

    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()

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
            }

            // Output area
            if let output = vm.resultOutput, !output.isEmpty {
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
                            context: context
                        )
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
    }
}
