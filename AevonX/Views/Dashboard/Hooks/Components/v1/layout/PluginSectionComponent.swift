//
//  PluginSectionComponent.swift
//  AevonX
//
//  Renders a section with a title and a grid of child layout cards.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Plugin Section Component

public struct PluginSectionComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 8))
                    Text(L10n.PluginsUI.plugin)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                )
            }

            if let desc = plugin.description {
                Text(desc)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            if let layout = plugin.layout, let cards = layout.cards {
                let columns = layout.columns ?? 2
                let gridColumns = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: columns)

                LazyVGrid(columns: gridColumns, spacing: AXSpacing.md) {
                    ForEach(cards, id: \.title) { card in
                        SectionCardView(card: card, serverId: serverId, context: context)
                    }
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Section Card View

private struct SectionCardView: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                if let icon = card.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                }
                Text(card.title)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
            }

            if let desc = card.description {
                Text(desc)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)
            }

            if let output = vm.resultOutput {
                Text(output.prefix(80))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)
            }

            if let command = card.command {
                Button(action: {
                    Task {
                        await vm.execute(
                            command: command,
                            pluginId: "section_\(card.title)",
                            serverId: serverId,
                            context: context
                        )
                    }
                }) {
                    HStack(spacing: 4) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                                .scaleEffect(0.6)
                        } else if vm.isSuccess {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.axSuccess)
                        }
                        Text(vm.isSuccess ? "Done" : "Run")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(vm.isSuccess ? .axSuccess : .axAccentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentBlue.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.4), lineWidth: 1)
        )
    }
}
