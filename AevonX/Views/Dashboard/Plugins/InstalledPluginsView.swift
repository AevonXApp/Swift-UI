//
//  InstalledPluginsView.swift
//  AevonX
//
//  Installed plugins management with card-based layout
//

import SwiftUI
import AevonXCoreBridge

struct InstalledPluginsView: View {
    let serverId: String?
    @StateObject private var viewModel = PluginsViewModel()
    @State private var selectedPlugin: Plugin?
    @State private var showConfig = false
    @State private var detailPlugin: Plugin?

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.availableUpdates.isEmpty {
                updateBanner
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.top, AXSpacing.lg)
            }

            if viewModel.isLoading {
                loadingState
            } else if viewModel.installedPlugins.isEmpty {
                emptyState
            } else {
                pluginsList
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
        .sheet(item: $detailPlugin) { plugin in
            PluginDetailSheet(
                plugin: plugin,
                serverId: serverId,
                isInstalled: true,
                installSource: viewModel.installSources[plugin.slug],
                updateInfo: viewModel.updateInfo(for: plugin.slug),
                viewModel: viewModel
            )
        }
        .onAppear {
            if let sid = serverId {
                Task {
                    await viewModel.loadInstalledPlugins(on: sid)
                    await viewModel.refreshPluginStatuses(serverID: sid)
                    await viewModel.checkForUpdates(on: sid)
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text(L10n.Plugin.loading)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        AXEmptyState(
            icon: "puzzlepiece.extension",
            title: L10n.Plugin.noInstalled,
            description: L10n.Plugin.browseHint
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Plugins List

    private var pluginsList: some View {
        ScrollView {
            LazyVStack(spacing: AXSpacing.sm) {
                ForEach(viewModel.installedPlugins) { plugin in
                    InstalledPluginCard(
                        plugin: plugin,
                        statusLabel: viewModel.statusLabel(for: plugin.slug),
                        statusColor: viewModel.statusColor(for: plugin.slug),
                        updateInfo: viewModel.updateInfo(for: plugin.slug),
                        updateProgress: viewModel.updateProgress[plugin.slug],
                        updateStatus: viewModel.updateStatus[plugin.slug],
                        onTap: { detailPlugin = plugin },
                        onConfigure: {
                            selectedPlugin = plugin
                            showConfig = true
                        },
                        onUninstall: {
                            if let sid = serverId {
                                Task { await viewModel.uninstallPlugin(plugin, on: sid) }
                            }
                        },
                        onUpdate: {
                            if let sid = serverId {
                                Task { await viewModel.updatePlugin(plugin, on: sid) }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.lg)
        }
    }

    // MARK: - Update Banner

    private var updateBanner: some View {
        AXCard(padding: AXSpacing.md, accentColor: .axAccentBlue) {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.axAccentBlue.opacity(0.2), .cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.axAccentBlue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text("\(viewModel.availableUpdates.count) \(L10n.Plugin.Update.available)")
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Text(viewModel.availableUpdates.map(\.pluginName).joined(separator: ", "))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if viewModel.availableUpdates.count > 1 {
                    Button(action: {
                        if let sid = serverId {
                            Task {
                                for plugin in viewModel.installedPlugins where viewModel.hasUpdate(for: plugin.slug) {
                                    await viewModel.updatePlugin(plugin, on: sid)
                                }
                            }
                        }
                    }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 11))
                            Text(L10n.Plugin.Update.updateAll)
                                .font(AXTypography.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            LinearGradient(colors: [.axAccentBlue, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .shadow(color: .axAccentBlue.opacity(0.2), radius: 4, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Installed Plugin Card

private struct InstalledPluginCard: View {
    let plugin: Plugin
    var statusLabel: String = ""
    var statusColor: Color = .secondary
    var updateInfo: PluginUpdateInfo?
    var updateProgress: Double?
    var updateStatus: String?
    let onTap: () -> Void
    let onConfigure: () -> Void
    let onUninstall: () -> Void
    var onUpdate: (() -> Void)?

    @State private var isHovered = false

    private var ratingValue: Double { Double(plugin.rating ?? "0") ?? 0 }

    var body: some View {
        AXCard(padding: 0, accentColor: .axAccentBlue) {
            VStack(spacing: 0) {
                cardBody
                if updateProgress != nil || updateInfo != nil {
                    Divider().background(Color.axBorder.opacity(0.5))
                    cardUpdateBar
                }
            }
        }
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    // MARK: - Card Body

    private var cardBody: some View {
        HStack(spacing: AXSpacing.md) {
            pluginIcon
            pluginInfo
            Spacer()
            actionColumn
        }
        .padding(AXSpacing.lg)
    }

    private var pluginIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.axAccentBlue.opacity(0.12), Color.axAccentGreen.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)

            if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axAccentBlue.opacity(0.4))
                }
                .frame(width: 48, height: 48)
                .cornerRadius(AXCornerRadius.lg)
                .clipped()
            } else {
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.axAccentBlue.opacity(0.4))
            }

            // Update dot
            if updateInfo != nil && updateProgress == nil {
                Circle()
                    .fill(Color.axAccentBlue)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(Color.axBackground, lineWidth: 2)
                    )
                    .offset(x: 18, y: -18)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(isHovered ? 0.6 : 0.3), lineWidth: 1)
        )
    }

    private var pluginInfo: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            // Name row
            HStack(spacing: AXSpacing.sm) {
                Text(plugin.name)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if plugin.isOfficial {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.axAccentBlue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                if !statusLabel.isEmpty {
                    PluginStatusChip(label: statusLabel, color: statusColor)
                }
            }

            // Developer + version
            HStack(spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 9))
                    Text(plugin.user?.name ?? L10n.Plugin.community)
                        .font(AXTypography.caption)
                        .fontWeight(.medium)

                    if plugin.user?.isVerifiedDeveloper == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.axAccentGreen, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .foregroundColor(.axAccentBlue.opacity(0.8))

                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "tag")
                        .font(.system(size: 8))
                    Text("v\(plugin.activeVersion?.versionNumber ?? "1.0.0")")
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.axTextMuted)
            }

            // Rating + downloads
            HStack(spacing: AXSpacing.md) {
                if ratingValue > 0 {
                    HStack(spacing: 2) {
                        StarRatingView(rating: ratingValue, size: 9)
                        Text(String(format: "%.1f", ratingValue))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.axTextMuted)
                    }
                }

                HStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 8))
                    Text(formatCount(plugin.downloadsCount))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.axTextMuted)
            }
        }
    }

    // MARK: - Action Column

    @ViewBuilder
    private var actionColumn: some View {
        if updateProgress == nil {
            HStack(spacing: AXSpacing.sm) {
                UninstallIconButton(onUninstall: onUninstall)

                Button(action: onConfigure) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11))
                        Text(L10n.Plugin.configure)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Update Bar

    @ViewBuilder
    private var cardUpdateBar: some View {
        if let progress = updateProgress, let status = updateStatus {
            HStack(spacing: AXSpacing.md) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .axAccentBlue))
                    .frame(maxWidth: 160)
                Text(status)
                    .font(AXTypography.caption)
                    .foregroundColor(.axAccentBlue)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.03))
        } else if let info = updateInfo {
            HStack(spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                    Text(L10n.Plugin.Update.newVersion(info.latestVersion))
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axAccentBlue)
                }

                if let changelog = info.changelog, !changelog.isEmpty {
                    Text(changelog)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: { onUpdate?() }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 10))
                        Text(L10n.Plugin.Update.update)
                            .font(AXTypography.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs + 2)
                    .background(
                        LinearGradient(colors: [.axAccentBlue, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(AXCornerRadius.sm)
                    .shadow(color: .axAccentBlue.opacity(0.2), radius: 3, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.03))
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

// MARK: - Status Chip

private struct PluginStatusChip: View {
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

// MARK: - Uninstall Icon Button

private struct UninstallIconButton: View {
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
                .font(.system(size: 12))
                .foregroundColor(.axError)
                .padding(AXSpacing.sm)
                .background(Color.axError.opacity(0.08))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axError.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(L10n.Plugin.uninstall)
        .overlay {
            if showConfirmation {
                AXDeleteConfirmation(
                    title: L10n.Plugin.uninstall,
                    itemName: "this plugin",
                    icon: "puzzlepiece",
                    warning: "This action cannot be undone.",
                    confirmLabel: L10n.Plugin.uninstall,
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
