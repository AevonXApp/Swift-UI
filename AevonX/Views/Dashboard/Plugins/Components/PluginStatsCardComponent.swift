//
//  PluginStatsCardComponent.swift
//  AevonX
//
//  Renders a stats card that executes a command and displays the result as a metric.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Stats Card Component

public struct PluginStatsCardComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var hasLoaded = false

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            // Label row
            HStack(spacing: AXSpacing.xs) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
                Text(plugin.label ?? plugin.name)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)

                Spacer()

                // Refresh button
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }

            // Metric value
            if vm.isLoading && !hasLoaded {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                        .scaleEffect(0.6)
                    Text("Loading...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            } else if let output = vm.resultOutput {
                Text(output.prefix(100))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(3)
            } else if vm.errorMessage != nil {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axError)
                    Text("Error")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axError)
                }
            } else {
                Text("—")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .task {
            if !hasLoaded {
                await loadData()
                hasLoaded = true
            }
        }
    }

    private func loadData() async {
        guard let command = plugin.command else { return }
        await vm.execute(
            command: command,
            pluginId: plugin.id,
            serverId: serverId,
            context: context
        )
    }

    private func refresh() {
        Task { await loadData() }
    }

    private var accentColor: Color {
        switch plugin.style ?? .primary {
        case .primary:   return .axAccentBlue
        case .danger:    return .axError
        case .warning:   return .axWarning
        case .success:   return .axSuccess
        case .secondary, .ghost: return .axAccentBlue
        }
    }
}
