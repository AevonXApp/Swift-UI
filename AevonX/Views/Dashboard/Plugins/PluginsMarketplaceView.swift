//
//  PluginsMarketplaceView.swift
//  AevonX
//
//  Premium Plugin Marketplace with Glassmorphism
//

import SwiftUI
import AevonXCoreBridge

private extension PluginPricing {
    var badgeColor: Color {
        switch type {
        case .free: return .axSuccess
        case .paid: return .axAccentBlue
        case .subscribers: return .axWarning
        }
    }

    var badgeIcon: String {
        switch type {
        case .free: return "gift.fill"
        case .paid: return "dollarsign.circle.fill"
        case .subscribers: return "crown.fill"
        }
    }
}

// MARK: - Main Marketplace View

struct PluginsMarketplaceView: View {
    let serverId: String?
    var serverIP: String = ""
    var showInstalledOnly: Bool = false
    let onSettings: (Plugin) -> Void

    @ObservedObject var viewModel: PluginsViewModel
    @State private var pluginToInstall: Plugin?
    @State private var selectedPlugin: Plugin?

    let columns = [
        GridItem(.adaptive(minimum: 340, maximum: 480), spacing: AXSpacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                searchAndFilterBar

                if !showInstalledOnly {
                    categoryFilterBar
                        .padding(.top, AXSpacing.sm)
                    pricingFilterBar
                        .padding(.top, AXSpacing.sm)
                }

                Divider()
                    .background(Color.axBorder)
                    .padding(.top, AXSpacing.md)

                contentArea
                    .padding(.top, AXSpacing.lg)
            }
        }
        .sheet(item: $pluginToInstall) { plugin in
            if let sid = serverId {
                PluginVersionPickerView(plugin: plugin, serverId: sid, serverIP: serverIP, viewModel: viewModel)
            } else {
                noServerSheet
            }
        }
        .sheet(item: $selectedPlugin) { plugin in
            PluginDetailSheet(
                plugin: plugin,
                serverId: serverId,
                serverIP: serverIP,
                isInstalled: viewModel.installedPlugins.contains(where: { $0.slug == plugin.slug }),
                installSource: viewModel.installSources[plugin.slug],
                updateInfo: viewModel.updateInfo(for: plugin.slug),
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.loadCategories()
            await viewModel.loadMarketplace()
            if let sid = serverId {
                await viewModel.loadInstalledPlugins(on: sid)
                await viewModel.checkForUpdates(on: sid)
            }
        }
    }

    private var noServerSheet: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.axError)
            Text(L10n.PluginsUI.noServerContext)
                .font(AXTypography.title3)
            Text(L10n.PluginsUI.pleaseSelectAServerFirst)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Button(L10n.Button.close) { pluginToInstall = nil }
                .buttonStyle(AXSecondaryButtonStyle())
        }
        .padding(AXSpacing.xxl)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }

    // MARK: - Search Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextMuted)
                TextField(L10n.Plugin.search, text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AXTypography.body)

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                        Task { await viewModel.loadMarketplace() }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm + 2)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )

            Button(action: { Task { await viewModel.loadMarketplace() } }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L10n.Button.search)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm + 2)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.lg)
    }

    // MARK: - Category Filter

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                FilterChip(
                    label: L10n.Plugin.all,
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil,
                    color: .axAccentBlue
                ) {
                    viewModel.selectedCategory = nil
                    Task { await viewModel.loadMarketplace() }
                }

                ForEach(viewModel.categories) { category in
                    FilterChip(
                        label: category.name,
                        icon: sfSymbol(for: category.icon ?? "folder"),
                        isSelected: viewModel.selectedCategory == category.slug,
                        color: .axAccentBlue,
                        count: category.pluginsCount
                    ) {
                        viewModel.selectedCategory = category.slug
                        Task { await viewModel.loadMarketplace() }
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
        }
    }

    // MARK: - Pricing Filter

    private var pricingFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                let options: [(label: String, value: String?, icon: String, color: Color)] = [
                    (L10n.Plugin.all, nil, "square.grid.2x2", .axTextSecondary),
                    ("Free", "free", "gift.fill", .axSuccess),
                    ("Paid", "paid", "dollarsign.circle.fill", .axAccentBlue),
                    ("Pro", "subscribers", "crown.fill", .axWarning),
                ]

                ForEach(options, id: \.label) { option in
                    FilterChip(
                        label: option.label,
                        icon: option.icon,
                        isSelected: viewModel.selectedPricing == option.value,
                        color: option.color
                    ) {
                        viewModel.selectedPricing = option.value
                        Task { await viewModel.loadMarketplace() }
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            VStack(spacing: AXSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(L10n.Plugin.loading)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
        } else if let error = viewModel.errorMessage {
            AXEmptyState(
                icon: "exclamationmark.triangle",
                title: "Something went wrong",
                description: error,
                actionLabel: L10n.Button.retry,
                action: { Task { await viewModel.loadMarketplace() } }
            )
        } else {
            pluginGrid
        }
    }

    private var pluginGrid: some View {
        Group {
            let displayedPlugins = showInstalledOnly ? viewModel.installedPlugins : viewModel.plugins
            if displayedPlugins.isEmpty {
                AXEmptyState(
                    icon: "puzzlepiece.extension",
                    title: showInstalledOnly ? L10n.Plugin.noInstalled : L10n.Plugin.noPlugins,
                    description: showInstalledOnly ? L10n.Plugin.browseHint : L10n.Plugin.adjustFilters
                )
            } else {
                LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                    ForEach(displayedPlugins) { plugin in
                        let isInstalled = viewModel.installedPlugins.contains(where: { $0.slug == plugin.slug })
                        let source = viewModel.installSources[plugin.slug]

                        PluginCard(
                            plugin: plugin,
                            isInstalling: viewModel.installationProgress.keys.contains(plugin.id),
                            isInstalled: isInstalled,
                            progress: viewModel.installationProgress[plugin.id] ?? 0,
                            status: viewModel.installationStatus[plugin.id] ?? "",
                            installSource: source,
                            isInMarketplace: viewModel.plugins.contains(where: { $0.slug == plugin.slug }),
                            updateInfo: viewModel.updateInfo(for: plugin.slug),
                            onTap: { selectedPlugin = plugin },
                            onInstall: {
                                // No client-side pricing gates — backend decides authorization.
                                if let versions = plugin.versions, !versions.isEmpty {
                                    pluginToInstall = plugin
                                } else if let sid = serverId {
                                    Task { await viewModel.installPlugin(plugin, on: sid, serverIP: serverIP) }
                                }
                            },
                            onSettings: { onSettings(plugin) },
                            onUninstall: {
                                if let sid = serverId {
                                    Task { await viewModel.uninstallPlugin(plugin, on: sid) }
                                }
                            },
                            onUpdate: isInstalled && viewModel.updateInfo(for: plugin.slug) != nil ? {
                                if let sid = serverId {
                                    Task { await viewModel.updatePlugin(plugin, on: sid) }
                                }
                            } : nil,
                            onChangeVersion: isInstalled && (plugin.versions?.count ?? 0) > 1 ? {
                                pluginToInstall = plugin
                            } : nil
                        )
                    }
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.bottom, AXSpacing.xxl)
            }
        }
    }

}

// MARK: - Filter Chip

private func sfSymbol(for lucideIcon: String) -> String {
    switch lucideIcon {
    case "shield-check": return "checkmark.shield"
    case "activity": return "waveform.path.ecg"
    case "rocket": return "paperplane.fill"
    case "database": return "cylinder"
    case "code": return "chevron.left.forwardslash.chevron.right"
    case "zap": return "bolt.fill"
    case "monitor": return "desktopcomputer"
    case "gauge": return "speedometer"
    case "wrench": return "wrench"
    case "server": return "server.rack"
    case "lock": return "lock"
    case "globe": return "globe"
    case "terminal": return "terminal"
    case "cpu": return "cpu"
    case "layers": return "square.3.layers.3d"
    case "box": return "shippingbox"
    default: return lucideIcon
    }
}

private struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    var count: Int? = nil
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))

                Text(label)
                    .font(.system(size: 11, weight: .bold))

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? color : .axTextMuted)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background((isSelected ? color : Color.axTextMuted).opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .foregroundColor(isSelected ? color : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? color.opacity(0.12) : (isHovered ? Color.axSurface : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? color.opacity(0.3) : Color.axBorder.opacity(isHovered ? 1 : 0), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }
}

// MARK: - Plugin Card (Premium Redesign v2)

struct PluginCard: View {
    let plugin: Plugin
    let isInstalling: Bool
    let isInstalled: Bool
    let progress: Double
    let status: String
    var installSource: InstallSource? = nil
    var isInMarketplace: Bool = true
    var updateInfo: PluginUpdateInfo? = nil
    let onTap: () -> Void
    let onInstall: () -> Void
    let onSettings: () -> Void
    let onUninstall: () -> Void
    var onUpdate: (() -> Void)? = nil
    var onChangeVersion: (() -> Void)? = nil

    private var isDevOnly: Bool { installSource == .devBuild && !isInMarketplace }
    private var isUploadBuild: Bool { installSource == .devBuild && isInMarketplace }
    // Pricing decisions are made by the backend — no client-side gates.

    @State private var isHovered = false
    @State private var showUninstallConfirmation = false

    private var accentColor: Color {
        if isDevOnly { return .purple }
        if isUploadBuild { return .orange }
        if isInstalled { return .axAccentGreen }
        return .axAccentBlue
    }

    private var ratingValue: Double { Double(plugin.rating ?? "0") ?? 0 }

    var body: some View {
        cardShell {
            VStack(alignment: .leading, spacing: 0) {
                cardHeader
                cardBody
                Spacer(minLength: 0)
                cardFooter
            }
        }
        .onHover { h in withAnimation(.easeOut(duration: 0.2)) { isHovered = h } }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .overlay {
            if showUninstallConfirmation {
                AXDeleteConfirmation(
                    title: L10n.Plugin.uninstall,
                    itemName: plugin.name,
                    icon: "puzzlepiece",
                    warning: "This will remove the plugin from your server.",
                    confirmLabel: L10n.Plugin.uninstall,
                    onConfirm: { showUninstallConfirmation = false; onUninstall() },
                    onCancel: { showUninstallConfirmation = false }
                )
            }
        }
    }

    // MARK: - Shell

    @ViewBuilder
    private func cardShell<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .fill(Color.axGlassBackground)
                    // Subtle top-edge accent glow
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: accentColor.opacity(isHovered ? 0.08 : 0.03), location: 0),
                                    .init(color: .clear, location: 0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(isHovered ? 0.35 : 0.12),
                                Color.axBorder.opacity(isHovered ? 0.5 : 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: accentColor.opacity(isHovered ? 0.15 : 0), radius: 20, y: 8)
            .scaleEffect(isHovered ? 1.005 : 1)
    }

    // MARK: - Header (Icon + Name + Badge)

    private var cardHeader: some View {
        HStack(spacing: AXSpacing.md) {
            pluginIcon

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                headerNameRow
                developerRow
            }

            Spacer(minLength: 0)

            pricingBadge
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.top, AXSpacing.lg)
        .padding(.bottom, AXSpacing.sm)
    }

    private var headerNameRow: some View {
        HStack(spacing: AXSpacing.xs) {
            Text(plugin.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)

            if plugin.isOfficial {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.axAccentBlue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .help(L10n.Plugin.official)
            }

            if isDevOnly {
                sourceBadge(icon: "person.circle.fill", label: "By You", color: .purple)
            } else if isUploadBuild {
                sourceBadge(icon: "arrow.up.circle.fill", label: "Upload", color: .orange)
            }
        }
    }

    private var developerRow: some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: "person.circle")
                .font(.system(size: 9))
            Text(plugin.user?.name ?? L10n.Plugin.community)
                .font(.system(size: 11, weight: .medium))

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
                    .help(L10n.Plugin.Detail.verifiedDeveloper)
            }
        }
        .foregroundColor(.axTextSecondary)
    }

    // MARK: - Body (Description + Meta chips)

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(plugin.description)
                .font(.system(size: 11.5))
                .foregroundColor(.axTextTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            metaChips

            // Update banner
            if let update = updateInfo, !isInstalling {
                updateBanner(update)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.bottom, AXSpacing.md)
    }

    private var metaChips: some View {
        HStack(spacing: AXSpacing.sm) {
            // Rating / New
            if ratingValue > 0 {
                metaChip {
                    StarRatingView(rating: ratingValue, size: 8)
                    Text(String(format: "%.1f", ratingValue))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow.opacity(0.9))
                }
            } else {
                metaChip {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.axAccentPurple)
                    Text(L10n.Plugin.Detail.newPlugin)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.axAccentPurple)
                }
            }

            // Downloads
            metaChip {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.axSuccess.opacity(0.8))
                Text(formatCount(plugin.downloadsCount))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.axTextMuted)
            }

            // Version
            if let version = plugin.activeVersion {
                metaChip {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.axTextMuted.opacity(0.7))
                    Text("v\(version.versionNumber)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.axTextMuted)
                }
            }

            // Category
            if let cat = plugin.category {
                metaChip {
                    Image(systemName: sfSymbol(for: cat.icon ?? "folder"))
                        .font(.system(size: 7))
                        .foregroundColor(.axTextMuted.opacity(0.7))
                    Text(cat.name)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                }
            }
        }
    }

    private func metaChip<C: View>(@ViewBuilder content: () -> C) -> some View {
        HStack(spacing: 3) { content() }
            .padding(.horizontal, AXSpacing.xs + 1)
            .padding(.vertical, 3)
            .background(Color.axSurface.opacity(0.6))
            .cornerRadius(AXCornerRadius.sm)
    }

    private func updateBanner(_ update: PluginUpdateInfo) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 10))
            Text(L10n.Plugin.Update.newVersion(update.latestVersion))
                .font(.system(size: 10, weight: .bold))
            Spacer()
        }
        .foregroundColor(.axAccentBlue)
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axAccentBlue.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(Color.axAccentBlue.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Footer (Actions)

    private var cardFooter: some View {
        HStack(spacing: AXSpacing.sm) {
            // Server limit
            if plugin.pricing?.isPaid == true, let limit = plugin.pricing?.serverLimit {
                HStack(spacing: 3) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 8))
                    Text("\(limit)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.axTextMuted)
            }

            Spacer()

            actionButtons
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm + 2)
        .background(
            LinearGradient(
                colors: [Color.axSurface.opacity(0.4), Color.axSurface.opacity(0.15)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    // MARK: - Plugin Icon

    private var pluginIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.18), accentColor.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            if isDevOnly {
                #if os(macOS)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(AXCornerRadius.md)
                #else
                Image(systemName: "hammer.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor.opacity(0.7))
                #endif
            } else if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor.opacity(0.35))
                }
                .frame(width: 56, height: 56)
                .cornerRadius(AXCornerRadius.lg)
                .clipped()
            } else {
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor.opacity(0.35))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(accentColor.opacity(isHovered ? 0.35 : 0.15), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(isHovered ? 0.3 : 0.08), radius: isHovered ? 12 : 4)
    }

    // MARK: - Badges

    private func sourceBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(label)
                .font(.system(size: 8, weight: .black))
                .textCase(.uppercase)
        }
        .foregroundColor(color)
        .padding(.horizontal, AXSpacing.xs + 2)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .cornerRadius(AXCornerRadius.xs + 1)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xs + 1)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var pricingBadge: some View {
        if let pricing = plugin.pricing {
            HStack(spacing: 4) {
                Image(systemName: pricing.badgeIcon)
                    .font(.system(size: 10, weight: .bold))
                Text(pricing.displayLabel)
                    .font(.system(size: 10, weight: .black))
                    .textCase(.uppercase)
            }
            .foregroundColor(pricing.badgeColor)
            .padding(.horizontal, AXSpacing.sm + 2)
            .padding(.vertical, AXSpacing.xxs + 2)
            .background(pricing.badgeColor.opacity(0.12))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(pricing.badgeColor.opacity(0.2), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isInstalling {
            installingView
        } else if isInstalled {
            installedButtons
        } else {
            installButton
        }
    }

    private var installingView: some View {
        HStack(spacing: AXSpacing.sm) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
                .frame(width: 60)
            Text(status)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(accentColor)
                .lineLimit(1)
        }
    }

    private var installedButtons: some View {
        HStack(spacing: AXSpacing.sm) {
            // Uninstall
            Button(action: {
                if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmUninstallPlugin) {
                    showUninstallConfirmation = true
                } else { onUninstall() }
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axError.opacity(0.9))
                    .frame(width: 30, height: 28)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axError.opacity(0.15), lineWidth: 0.5)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help(L10n.Plugin.uninstall)

            // Change version
            if let changeVersion = onChangeVersion {
                Button(action: changeVersion) {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 30, height: 28)
                        .background(Color.axSurface.opacity(0.8))
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 0.5)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help(L10n.Plugin.Detail.showAllVersions)
            }

            // Update button (when update available)
            if let update = updateInfo, let doUpdate = onUpdate {
                Button(action: doUpdate) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(L10n.Plugin.Update.update)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .frame(height: 28)
                    .background(
                        LinearGradient(colors: [.axAccentBlue, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 6, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .help(L10n.Plugin.Update.newVersion(update.latestVersion))
            } else {
                // Configure (only when no update)
                Button(action: onSettings) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10, weight: .medium))
                        Text(L10n.Plugin.configure)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.axTextPrimary)
                    .padding(.horizontal, AXSpacing.md)
                    .frame(height: 28)
                    .background(Color.axSurface.opacity(0.8))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var installButton: some View {
        Button(action: onInstall) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(L10n.Plugin.install)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.axBackground)
            .padding(.horizontal, AXSpacing.xl)
            .frame(height: 32)
            .background(
                LinearGradient(
                    colors: [.axSuccess, .axSuccess.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AXCornerRadius.md)
            .shadow(color: Color.axSuccess.opacity(0.3), radius: 8, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

// MARK: - Version Picker

struct PluginVersionPickerView: View {
    let plugin: Plugin
    let serverId: String
    var serverIP: String = ""
    @ObservedObject var viewModel: PluginsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            pickerHeader
            Divider().background(Color.axBorder)
            pickerContent
        }
        .frame(width: 540)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
    }

    private var pickerHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axAccentBlue.opacity(0.1))
                    .frame(width: 40, height: 40)

                if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(.axAccentBlue.opacity(0.4))
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(AXCornerRadius.sm)
                    .clipped()
                } else {
                    Image(systemName: "puzzlepiece.fill")
                        .foregroundColor(.axAccentBlue.opacity(0.4))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(L10n.Plugin.install) \(plugin.name)")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Plugin.Detail.versions)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackgroundSecondary)
    }

    private var pickerContent: some View {
        ScrollView {
            VStack(spacing: AXSpacing.sm) {
                if let versions = plugin.versions, !versions.isEmpty {
                    ForEach(versions) { version in
                        versionPickerRow(version)
                    }
                } else {
                    AXEmptyState(
                        icon: "tray.and.arrow.down",
                        title: L10n.Plugin.Detail.noVersions,
                        description: L10n.Plugin.Detail.noVersions
                    )
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func versionPickerRow(_ version: PluginVersion) -> some View {
        Button(action: {
            dismiss()
            Task { await viewModel.installPlugin(plugin, version: version, on: serverId, serverIP: serverIP) }
        }) {
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: AXSpacing.xs) {
                        Text("v\(version.versionNumber)")
                            .font(AXTypography.body)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)

                        if version.isActive {
                            Text(L10n.Plugin.Detail.latest.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.axSuccess.opacity(0.15))
                                .foregroundColor(.axSuccess)
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(width: 100, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    if let changelog = version.changelog, !changelog.isEmpty {
                        Text(changelog)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(2)
                    } else {
                        Text(L10n.Plugin.Detail.noChangelog)
                            .font(AXTypography.caption)
                            .italic()
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.axAccentBlue)
                    .font(.title3)
            }
            .padding(AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
