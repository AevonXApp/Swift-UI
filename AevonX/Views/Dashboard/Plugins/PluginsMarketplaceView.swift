//
//  PluginsMarketplaceView.swift
//  AevonX
//

import SwiftUI
import AevonXCore

struct PluginsMarketplaceView: View {
    let serverId: String?
    var showInstalledOnly: Bool = false
    let onSettings: (Plugin) -> Void
    
    @StateObject private var viewModel = PluginsViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 360, maximum: 480), spacing: AXSpacing.lg)
    ]
    
    @State private var pluginToInstall: Plugin?
    
    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Search & Filter Bar
                HStack(spacing: AXSpacing.md) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.axTextMuted)
                        TextField("Search plugins...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    
                    Button(action: { Task { await viewModel.loadMarketplace() } }) {
                        Text("Search")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.top, AXSpacing.xl)
                
                if viewModel.isLoading {
                    VStack(spacing: AXSpacing.md) {
                        ProgressView()
                        Text("Loading marketplace...")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.axError)
                        Text(error)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task { await viewModel.loadMarketplace() }
                        }
                        .buttonStyle(AXSecondaryButtonStyle())
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    let displayedPlugins = showInstalledOnly ? viewModel.installedPlugins : viewModel.plugins
                    
                    if displayedPlugins.isEmpty {
                        VStack(spacing: AXSpacing.md) {
                            Image(systemName: "puzzlepiece")
                                .font(.system(size: 48))
                                .foregroundColor(.axTextMuted)
                            Text(showInstalledOnly ? "No installed plugins found" : "No plugins found")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        // Grid of Plugins
                        LazyVGrid(columns: columns, spacing: AXSpacing.lg) {
                            ForEach(displayedPlugins) { plugin in
                                let isInstalled = viewModel.installedPlugins.contains(where: { $0.slug == plugin.slug })
                                
                                PluginCard(
                                    plugin: plugin,
                                    isInstalling: viewModel.installationProgress.keys.contains(plugin.id),
                                    isInstalled: isInstalled,
                                    progress: viewModel.installationProgress[plugin.id] ?? 0,
                                    status: viewModel.installationStatus[plugin.id] ?? "",
                                    onInstall: {
                                        if let versions = plugin.versions, !versions.isEmpty {
                                            pluginToInstall = plugin
                                        } else if let sid = serverId {
                                            Task { await viewModel.installPlugin(plugin, on: sid) }
                                        }
                                    },
                                    onSettings: {
                                        onSettings(plugin)
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
                        .padding(.horizontal, AXSpacing.xl)
                        .padding(.bottom, AXSpacing.xl)
                    }
                }
            }
        }
        .sheet(item: $pluginToInstall) { plugin in
            if let sid = serverId {
                PluginVersionPickerView(plugin: plugin, serverId: sid, viewModel: viewModel)
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
                    Button("Close") { pluginToInstall = nil }
                        .buttonStyle(AXSecondaryButtonStyle())
                }
                .padding(AXSpacing.xxl)
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color.axBackground)
            }
        }
        .task {
            await viewModel.loadMarketplace()
            if let sid = serverId {
                await viewModel.loadInstalledPlugins(on: sid)
            }
        }
    }
}

struct PluginCard: View {
    let plugin: Plugin
    let isInstalling: Bool
    let isInstalled: Bool
    let progress: Double
    let status: String
    let onInstall: () -> Void
    let onSettings: () -> Void
    let onUninstall: () -> Void
    
    @State private var isStatsHovered = false
    @State private var showUninstallConfirmation = false
    
    var body: some View {
        AXCard(padding: AXSpacing.md) {
            HStack(alignment: .top, spacing: AXSpacing.md) {
                // Icon on the left
                ZStack {
                    if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.axBackgroundTertiary
                        }
                    } else {
                        Color.axBackgroundTertiary
                        Image(systemName: "puzzlepiece.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.axAccentBlue.opacity(0.3))
                    }
                    
                    if plugin.isOfficial {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axAccentBlue)
                                    .background(Circle().fill(.white).padding(2))
                                    .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: 72, height: 72)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
                .clipped()
                
                // Content on the right
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    HStack {
                        Text(plugin.name)
                            .font(AXTypography.body)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let price = plugin.pricing?.price {
                            Text(price == "0.00" ? "FREE" : "$\(price)")
                                .font(AXTypography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(price == "0.00" ? .axSuccess : .axAccentBlue)
                        }
                    }
                    
                    Text(plugin.user?.name ?? "Community")
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                        .padding(.bottom, 2)
                    
                    Text(plugin.description)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: AXSpacing.xs)
                    
                    HStack(alignment: .bottom) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                            Text("\(plugin.downloadsCount)")
                        }
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                        
                        Spacer()
                        
                        if isInstalling {
                            VStack(alignment: .trailing, spacing: 2) {
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .axAccentBlue))
                                    .frame(width: 60)
                                Text(status)
                                    .font(.system(size: 8))
                                    .foregroundColor(.axAccentBlue)
                            }
                        } else if isInstalled {
                            HStack(spacing: 8) {
                                Button(action: { showUninstallConfirmation = true }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.axError)
                                        .padding(6)
                                        .background(Color.axError.opacity(0.1))
                                        .cornerRadius(AXCornerRadius.xs)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Uninstall Plugin")
                                .alert(isPresented: $showUninstallConfirmation) {
                                    Alert(
                                        title: Text("Uninstall Plugin"),
                                        message: Text("Are you sure you want to uninstall \(plugin.name)? This action cannot be undone."),
                                        primaryButton: .destructive(Text("Uninstall"), action: onUninstall),
                                        secondaryButton: .cancel()
                                    )
                                }
                                
                                Button(action: onSettings) {
                                    Text("Settings")
                                        .font(AXTypography.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.xs)
                                        .background(Color.axBackgroundSecondary)
                                        .cornerRadius(AXCornerRadius.xs)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            Button(action: onInstall) {
                                Text("Install")
                                    .font(AXTypography.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, AXSpacing.xs)
                                    .background(Color.axAccentBlue)
                                    .cornerRadius(AXCornerRadius.xs)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct PluginVersionPickerView: View {
    let plugin: Plugin
    let serverId: String
    @ObservedObject var viewModel: PluginsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Install \(plugin.name)")
                        .font(AXTypography.headline)
                    Text("Select a version to install on your server")
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
            
            // Version List
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    if let versions = plugin.versions, !versions.isEmpty {
                        ForEach(versions) { version in
                            Button(action: {
                                Task {
                                    await viewModel.installPlugin(plugin, version: version, on: serverId)
                                    dismiss()
                                }
                            }) {
                                HStack(spacing: AXSpacing.md) {
                                    // Version Indicator
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("v\(version.versionNumber)")
                                            .font(AXTypography.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.axTextPrimary)
                                        
                                        if version.isActive {
                                            Text("LATEST")
                                                .font(.system(size: 8, weight: .black))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.axSuccess.opacity(0.15))
                                                .foregroundColor(.axSuccess)
                                                .cornerRadius(3)
                                        }
                                    }
                                    .frame(width: 80, alignment: .leading)
                                    
                                    Divider()
                                        .frame(height: 30)
                                    
                                    // Content
                                    VStack(alignment: .leading, spacing: 2) {
                                        if let changelog = version.changelog, !changelog.isEmpty {
                                            Text(changelog)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextSecondary)
                                                .lineLimit(2)
                                        } else {
                                            Text("No changelog provided")
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
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        VStack(spacing: AXSpacing.lg) {
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 48))
                                .foregroundColor(.axTextMuted)
                            Text("No versions found")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
    }
}
