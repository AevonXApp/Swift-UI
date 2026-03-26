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
    
    let columns = [
        GridItem(.adaptive(minimum: 340, maximum: 480), spacing: AXSpacing.md)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Search + Filter bar
                searchAndFilterBar
                
                if !showInstalledOnly {
                    // Category pills
                    categoryFilterBar
                        .padding(.top, AXSpacing.sm)
                    
                    // Pricing pills
                    pricingFilterBar
                        .padding(.top, AXSpacing.sm)
                }
                
                Divider()
                    .background(Color.axBorder)
                    .padding(.top, AXSpacing.md)
                
                // Content
                contentArea
                    .padding(.top, AXSpacing.lg)
            }
        }
        .sheet(item: $pluginToInstall) { plugin in
            if let sid = serverId {
                PluginVersionPickerView(plugin: plugin, serverId: sid, serverIP: serverIP, viewModel: viewModel)
            } else {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.axError)
                    Text("No Server Context")
                        .font(AXTypography.title3)
                    Text("Please select a server first.")
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
        }
        .task {
            await viewModel.loadCategories()
            await viewModel.loadMarketplace()
            if let sid = serverId {
                await viewModel.loadInstalledPlugins(on: sid)
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchAndFilterBar: some View {
        HStack(spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextMuted)
                TextField("Search plugins...", text: $viewModel.searchQuery)
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
                    label: "All",
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
                    ("All", nil, "square.grid.2x2", .axTextSecondary),
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
                Text("Loading marketplace...")
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
            let displayedPlugins = showInstalledOnly ? viewModel.installedPlugins : viewModel.plugins
            
            if displayedPlugins.isEmpty {
                AXEmptyState(
                    icon: "puzzlepiece.extension",
                    title: showInstalledOnly ? "No plugins installed" : "No plugins found",
                    description: showInstalledOnly
                        ? "Browse the marketplace to find powerful extensions."
                        : "Try adjusting your search or filters."
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
                            onInstall: {
                                // Paid plugins not yet purchased → open web checkout
                                if plugin.pricing?.isPaid == true && !plugin.isPurchased {
                                    let slug = plugin.slug
                                    let config = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration
                                    let scheme = config.useHTTPS ? "https" : "http"
                                    if let url = URL(string: "\(scheme)://\(config.baseURL)/marketplace/\(slug)/checkout") {
                                        #if os(macOS)
                                        NSWorkspace.shared.open(url)
                                        #endif
                                    }
                                } else if let versions = plugin.versions, !versions.isEmpty {
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
                            }
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

/// Maps Lucide icon names (from API) to SF Symbol equivalents.
private func sfSymbol(for lucideIcon: String) -> String {
    switch lucideIcon {
    case "shield-check": return "shield.checkmark"
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
    default: return lucideIcon  // pass through if already SF Symbol
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

// MARK: - Plugin Card (Premium Redesign)

struct PluginCard: View {
    let plugin: Plugin
    let isInstalling: Bool
    let isInstalled: Bool
    let progress: Double
    let status: String
    var installSource: InstallSource? = nil
    var isInMarketplace: Bool = true
    let onInstall: () -> Void
    let onSettings: () -> Void
    let onUninstall: () -> Void

    /// True = dev-build but NOT in marketplace (brand new plugin by owner)
    private var isDevOnly: Bool {
        installSource == .devBuild && !isInMarketplace
    }

    /// True = marketplace plugin that was re-installed via Upload Build
    private var isUploadBuild: Bool {
        installSource == .devBuild && isInMarketplace
    }

    /// Paid plugin that requires purchase before install
    private var requiresPurchase: Bool {
        plugin.pricing?.isPaid == true && !isInstalled && !plugin.isPurchased
    }

    /// Subscribers-only plugin
    private var requiresSubscription: Bool {
        plugin.pricing?.isSubscribers == true && !isInstalled
    }

    @State private var isHovered = false
    @State private var showUninstallConfirmation = false

    private var accentColor: Color {
        if isDevOnly    { return .purple }
        if isUploadBuild { return .orange }
        return .axAccentBlue
    }

    var body: some View {
        AXGlassCard(padding: 0, cornerRadius: AXCornerRadius.lg, accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 0) {
                // Top — Icon + Info
                HStack(alignment: .top, spacing: AXSpacing.lg) {
                    pluginIcon

                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        // Name + badges
                        HStack(spacing: AXSpacing.xs) {
                            Text(plugin.name)
                                .font(.system(size: 14, weight: .bold))
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
                                installBadge(icon: "person.circle.fill", label: "By You", color: .purple)
                            } else if isUploadBuild {
                                installBadge(icon: "arrow.up.circle.fill", label: "Upload Build", color: .orange)
                            }

                            Spacer()

                            pricingBadge
                        }

                        // Developer
                        Text(plugin.user?.name ?? "Community")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.axAccentBlue.opacity(0.8))

                        // Description
                        Text(plugin.description)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AXSpacing.lg)

                // Bottom — Stats + Actions
                HStack(alignment: .center, spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.lg) {
                        statItem(icon: "arrow.down.circle", value: formatCount(plugin.downloadsCount), color: .axSuccess)

                        if let rating = plugin.rating, !rating.isEmpty {
                            statItem(icon: "star.fill", value: rating, color: .yellow)
                        }

                        if let cat = plugin.category {
                            HStack(spacing: 3) {
                                Image(systemName: sfSymbol(for: cat.icon ?? "folder"))
                                    .font(.system(size: 9))
                                Text(cat.name)
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(.axTextMuted)
                        }

                        if plugin.pricing?.isPaid == true, let limit = plugin.pricing?.serverLimit {
                            statItem(icon: "server.rack", value: "\(limit)", color: .axAccentBlue)
                        }
                    }

                    Spacer()

                    actionButtons
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm + 2)
                .background(Color.axSurface.opacity(0.3))
            }
        }
        .onHover { isHovered = $0 }
    }

    // MARK: - Sub-views

    private var pluginIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            if isDevOnly {
                #if os(macOS)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                    .cornerRadius(AXCornerRadius.md)
                #else
                Image(systemName: "hammer.fill")
                    .font(.system(size: 22))
                    .foregroundColor(accentColor.opacity(0.7))
                #endif
            } else if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 22))
                        .foregroundColor(accentColor.opacity(0.4))
                }
                .frame(width: 52, height: 52)
                .cornerRadius(AXCornerRadius.lg)
                .clipped()
            } else {
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 22))
                    .foregroundColor(accentColor.opacity(0.4))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(accentColor.opacity(isHovered ? 0.3 : 0.12), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(isHovered ? 0.25 : 0.05), radius: isHovered ? 12 : 6)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .overlay {
            if showUninstallConfirmation {
                AXDeleteConfirmation(
                    title: "Uninstall Plugin",
                    itemName: plugin.name,
                    icon: "puzzlepiece",
                    warning: "This will remove the plugin from your server.",
                    confirmLabel: "Uninstall",
                    onConfirm: {
                        showUninstallConfirmation = false
                        onUninstall()
                    },
                    onCancel: { showUninstallConfirmation = false }
                )
            }
        }
    }

    private func installBadge(icon: String, label: String, color: Color) -> some View {
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
            HStack(spacing: 3) {
                Image(systemName: pricing.badgeIcon)
                    .font(.system(size: 9, weight: .bold))
                Text(pricing.displayLabel)
                    .font(.system(size: 9, weight: .black))
                    .textCase(.uppercase)
            }
            .foregroundColor(pricing.badgeColor)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 3)
            .background(pricing.badgeColor.opacity(0.12))
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(pricing.badgeColor.opacity(0.2), lineWidth: 0.5)
            )
        }
    }

    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.axTextMuted)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if isInstalling {
            HStack(spacing: AXSpacing.xs) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
                    .frame(width: 50)
                Text(status)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(accentColor)
                    .lineLimit(1)
            }
        } else if isInstalled {
            HStack(spacing: AXSpacing.xs) {
                Button(action: {
                    if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmUninstallPlugin) {
                        showUninstallConfirmation = true
                    } else {
                        onUninstall()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.axError)
                        .padding(AXSpacing.xs + 2)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help(L10n.Plugin.uninstall)

                Button(action: onSettings) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10))
                        Text(L10n.Plugin.configure)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.axTextPrimary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs + 2)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else if requiresPurchase {
            // Paid plugin — show Buy button
            Button(action: onInstall) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 10))
                    Text("Buy \(plugin.pricing?.displayLabel ?? "")")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs + 2)
                .background(
                    LinearGradient(
                        colors: [.axAccentBlue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.sm)
                .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 4, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        } else if requiresSubscription {
            // Subscribers-only — show Pro badge
            Button(action: onInstall) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                    Text("Pro Only")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.axWarning)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs + 2)
                .background(Color.axWarning.opacity(0.12))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axWarning.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // Free plugin — Install
            Button(action: onInstall) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 11))
                    Text(L10n.Plugin.install)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs + 2)
                .background(
                    LinearGradient(
                        colors: [.axSuccess, .axSuccess.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.sm)
                .shadow(color: Color.axSuccess.opacity(0.3), radius: 4, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Helpers

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
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
    
    private var accentColor: Color {
        .axAccentBlue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "puzzlepiece.fill")
                                .foregroundColor(accentColor.opacity(0.4))
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(AXCornerRadius.sm)
                        .clipped()
                    } else {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(accentColor.opacity(0.4))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install \(plugin.name)")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("Select a version to install")
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
            
            Divider()
                .background(Color.axBorder)
            
            // Version List
            ScrollView {
                VStack(spacing: AXSpacing.sm) {
                    if let versions = plugin.versions, !versions.isEmpty {
                        ForEach(versions) { version in
                            Button(action: {
                                dismiss()
                                Task {
                                    await viewModel.installPlugin(plugin, version: version, on: serverId, serverIP: serverIP)
                                }
                            }) {
                                HStack(spacing: AXSpacing.md) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: AXSpacing.xs) {
                                            Text("v\(version.versionNumber)")
                                                .font(AXTypography.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.axTextPrimary)
                                            
                                            if version.isActive {
                                                Text("LATEST")
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
                                            Text("No changelog")
                                                .font(AXTypography.caption)
                                                .italic()
                                                .foregroundColor(.axTextMuted)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(accentColor)
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
                    } else {
                        AXEmptyState(
                            icon: "tray.and.arrow.down",
                            title: "No versions",
                            description: "No versions are available for this plugin."
                        )
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(width: 540)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
    }
}
