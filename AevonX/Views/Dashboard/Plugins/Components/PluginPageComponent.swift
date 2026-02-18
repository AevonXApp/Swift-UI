//
//  PluginPageComponent.swift
//  AevonX
//
//  Renders a full page layout for plugin-defined sidebar tabs.
//  Supports: cards_details, overview, table, grid layouts.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Page Component

public struct PluginPageComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Page header
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.md) {
                        if let icon = plugin.icon {
                            ZStack {
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axAccentBlue.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: icon)
                                    .font(.system(size: 20, weight: .medium))
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, AXSpacing.xxl)
                .padding(.top, AXSpacing.xl)

                Divider()
                    .padding(.horizontal, AXSpacing.xxl)

                // Layout content
                if let layout = plugin.layout {
                    layoutContent(layout)
                } else {
                    // Fallback: show plugin info
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: plugin.icon ?? "puzzlepiece")
                            .font(.system(size: 40))
                            .foregroundColor(.axTextMuted)
                        Text("No layout defined for this plugin")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AXSpacing.xxl)
                }
            }
        }
        .background(Color.axBackground)
    }

    // MARK: - Layout Renderers

    @ViewBuilder
    private func layoutContent(_ layout: HookPluginLayout) -> some View {
        switch layout.type {
        case .cardsDetails:
            cardsDetailsLayout(layout)
        case .overview:
            overviewLayout(layout)
        case .table:
            tableLayout(layout)
        case .grid:
            gridLayout(layout)
        case .split, .dashboard:
            // dashboard and split use the same cards grid layout
            cardsDetailsLayout(layout)
        }
    }

    @ViewBuilder
    private func cardsDetailsLayout(_ layout: HookPluginLayout) -> some View {
        let columns = layout.columns ?? 2
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: columns)

        LazyVGrid(columns: gridColumns, spacing: AXSpacing.lg) {
            ForEach(layout.cards ?? [], id: \.title) { card in
                PluginLayoutCardView(card: card, serverId: serverId, context: context)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.bottom, AXSpacing.xl)
    }

    @ViewBuilder
    private func overviewLayout(_ layout: HookPluginLayout) -> some View {
        VStack(spacing: AXSpacing.lg) {
            if let cards = layout.cards {
                ForEach(cards, id: \.title) { card in
                    PluginLayoutCardView(card: card, serverId: serverId, context: context)
                }
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.bottom, AXSpacing.xl)
    }

    @ViewBuilder
    private func tableLayout(_ layout: HookPluginLayout) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            if let cards = layout.cards {
                ForEach(cards, id: \.title) { card in
                    PluginLayoutCardView(card: card, serverId: serverId, context: context)
                }
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.bottom, AXSpacing.xl)
    }

    @ViewBuilder
    private func gridLayout(_ layout: HookPluginLayout) -> some View {
        cardsDetailsLayout(layout)
    }
}

// MARK: - Layout Card View

private struct PluginLayoutCardView: View {

    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
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
            }

            // Output
            if let output = vm.resultOutput, !output.isEmpty {
                Text(output.prefix(200))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .padding(AXSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axBackground)
                    )
                    .lineLimit(5)
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axError)
            }

            // Action button
            if let command = card.command {
                Button(action: {
                    Task {
                        await vm.execute(
                            command: command,
                            pluginId: "layout_card_\(card.title)",
                            serverId: serverId,
                            context: context
                        )
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                                .scaleEffect(0.7)
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
                            .fill(Color.axAccentBlue.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
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
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}
