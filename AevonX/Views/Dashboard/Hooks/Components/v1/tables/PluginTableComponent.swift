//
//  PluginTableComponent.swift
//  AevonX
//
//  Renders a table from plugin command output data.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Plugin Table Component

public struct PluginTableComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var hasLoaded = false

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
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

                Button(action: { Task { await loadData() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }

            Divider()

            if vm.isLoading && !hasLoaded {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(AXSpacing.lg)
            } else if let output = vm.resultOutput, !output.isEmpty {
                let rows = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            Text(row)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(index == 0 ? .axTextPrimary : .axTextSecondary)
                                .fontWeight(index == 0 ? .semibold : .regular)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(index % 2 == 0 ? Color.clear : Color.axBackground.opacity(0.5))
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axBackground)
                )
            } else if let error = vm.errorMessage {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axError)
                        .font(.system(size: 12))
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                }
            } else {
                Text("No data")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(AXSpacing.lg)
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
}
