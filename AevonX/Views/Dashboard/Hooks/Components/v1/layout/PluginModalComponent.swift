//
//  PluginModalComponent.swift
//  AevonX
//
//  Renders a button that opens a modal sheet with plugin-defined content and action.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Plugin Modal Component

public struct PluginModalComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()

    public var body: some View {
        Button(action: { vm.toggleModal() }) {
            HStack(spacing: 6) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(plugin.label ?? plugin.name)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: Binding(get: { vm.showModal }, set: { _ in vm.toggleModal() })) {
            PluginModalSheet(
                plugin: plugin,
                serverId: serverId,
                context: context,
                vm: vm
            )
            .frame(minWidth: 480, minHeight: 360)
        }
    }
}

// MARK: - Modal Sheet

private struct PluginModalSheet: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]
    @ObservedObject var vm: HookPluginViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.xl)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    if let desc = plugin.description {
                        Text(desc)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                    }

                    if let output = vm.resultOutput {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Output")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextMuted)
                                .textCase(.uppercase)

                            ScrollView {
                                Text(output)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
                            .padding(AXSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axBackground)
                            )
                        }
                    }

                    if let error = vm.errorMessage {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.axError)
                            Text(error)
                                .font(AXTypography.caption)
                                .foregroundColor(.axError)
                        }
                        .padding(AXSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(Color.axError.opacity(0.08))
                        )
                    }
                }
                .padding(AXSpacing.xl)
            }

            Divider()

            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.axTextSecondary)

                Spacer()

                if let command = plugin.command {
                    Button(action: {
                        Task {
                            await vm.execute(
                                command: command,
                                pluginId: plugin.id,
                                serverId: serverId,
                                context: context
                            )
                        }
                    }) {
                        HStack(spacing: AXSpacing.xs) {
                            if vm.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            } else if vm.isSuccess {
                                Image(systemName: "checkmark")
                            } else if let icon = plugin.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 12))
                            }
                            Text(vm.isSuccess ? "Done!" : (plugin.label ?? "Execute"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(vm.isSuccess ? Color.axSuccess : Color.axAccentBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }
}
