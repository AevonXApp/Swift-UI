//
//  InstalledPluginsView.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

struct InstalledPluginsView: View {
    let serverId: String?
    @StateObject private var viewModel = PluginsViewModel()
    @State private var selectedPlugin: Plugin?
    @State private var showConfig = false
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            if viewModel.isLoading {
                ProgressView()
                    .padding(AXSpacing.xl)
            } else if viewModel.installedPlugins.isEmpty {
                VStack(spacing: AXSpacing.lg) {
                    Image(systemName: "puzzlepiece")
                        .font(.system(size: 64))
                        .foregroundColor(.axTextMuted)
                    
                    Text("No plugins installed yet")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextSecondary)
                    
                    Text("Browse the marketplace to find and install powerful extensions for your server.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AXSpacing.xxl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.installedPlugins) { plugin in
                        InstalledPluginRow(
                            plugin: plugin,
                            statusLabel: viewModel.statusLabel(for: plugin.slug),
                            statusColor: viewModel.statusColor(for: plugin.slug),
                            onConfigure: {
                                selectedPlugin = plugin
                                showConfig = true
                            },
                            onUninstall: {
                                if let sid = serverId {
                                    Task {
                                        await viewModel.uninstallPlugin(plugin, on: sid)
                                    }
                                }
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $showConfig) {
            if let plugin = selectedPlugin, let sid = serverId {
                PluginConfigurationView(
                    viewModel: PluginConfigurationViewModel(plugin: plugin, serverId: sid),
                    onBack: { showConfig = false }
                )
            }
        }
        .onAppear {
            if let sid = serverId {
                Task {
                    await viewModel.loadInstalledPlugins(on: sid)
                    await viewModel.refreshPluginStatuses(serverID: sid)
                }
            }
        }
    }
}

struct InstalledPluginRow: View {
    let plugin: Plugin
    var statusLabel: String = ""
    var statusColor: Color = .secondary
    let onConfigure: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axBackgroundTertiary)
                    .frame(width: 44, height: 44)

                Image(systemName: "puzzlepiece.fill")
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(plugin.name)
                        .font(AXTypography.body)
                        .fontWeight(.semibold)

                    if !statusLabel.isEmpty {
                        PluginStatusBadge(label: statusLabel, color: statusColor)
                    }
                }

                Text(plugin.activeVersion?.versionNumber ?? "v1.0.0")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()
            
            UninstallButton(onUninstall: onUninstall)
            
            Button(action: onConfigure) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "slider.horizontal.3")
                    Text(L10n.Plugin.configure)
                }
                .font(AXTypography.caption)
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, AXSpacing.sm)
        .padding(.horizontal, AXSpacing.md)
    }
}

private struct PluginStatusBadge: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: AXSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, AXSpacing.xs)
        .padding(.vertical, AXSpacing.xxxs)
        .background(color.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
}

private struct UninstallButton: View {
    let onUninstall: () -> Void
    @State private var showConfirmation = false
    
    var body: some View {
        Button(action: {
            if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmUninstallPlugin) {
                showConfirmation = true
            } else {
                onUninstall()
            }
        }) {
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundColor(.axError)
                .padding(AXSpacing.sm)
                .background(Color.axError.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .help("Uninstall Plugin")
        .overlay {
            if showConfirmation {
                AXDeleteConfirmation(
                    title: "Uninstall Plugin",
                    itemName: "this plugin",
                    icon: "puzzlepiece",
                    warning: "This action cannot be undone.",
                    confirmLabel: "Uninstall",
                    onConfirm: {
                        showConfirmation = false
                        onUninstall()
                    },
                    onCancel: { showConfirmation = false }
                )
            }
        }
    }
}
