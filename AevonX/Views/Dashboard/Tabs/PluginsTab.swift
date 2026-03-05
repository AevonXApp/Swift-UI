//
//  PluginsTab.swift
//  AevonX
//

import SwiftUI
import AevonXCore
import UniformTypeIdentifiers

struct PluginsTab: View {
    let server: Server?
    let serverId: String?
    let connectionViewModel: ServerConnectionViewModel?
    
    @State private var selectedTab: PluginViewType = .marketplace
    @State private var pluginForConfiguration: Plugin?
    @StateObject private var viewModel = PluginsViewModel()
    
    // Dev build sheet
    @State private var showDevBuildSheet: Bool = false
    
    enum PluginViewType: String, CaseIterable, Identifiable {
        case marketplace = "Marketplace"
        case installed = "Installed"
        var id: String { rawValue }
    }
    
    var body: some View {
        Group {
            if let plugin = pluginForConfiguration {
                if let sid = serverId {
                    PluginConfigurationView(
                        viewModel: PluginConfigurationViewModel(plugin: plugin, serverId: sid),
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                pluginForConfiguration = nil
                            }
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            } else {
                VStack(spacing: 0) {
                    // Header with Segmented Control + Developer Buttons
                    HStack(spacing: AXSpacing.md) {
                        Text("Plugins")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        // Upload Build Button → opens terminal sheet
                        Button(action: { showDevBuildSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Upload Build")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axAccentBlue)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(serverId == nil)
                        .help("Upload a dev plugin build (.zip) to test on this server")
                        
                        // Join Developers Button
                        Button(action: { openDeveloperPage() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Join Developers")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axAccentBlue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Apply to become an AevonX plugin developer")
                        
                        Picker("", selection: $selectedTab) {
                            ForEach(PluginViewType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: LayoutConstants.Input.medium)
                    }
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.lg)
                    .background(Color.axBackgroundTertiary)
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    // Content — both tabs share the same viewModel
                    Group {
                        switch selectedTab {
                        case .marketplace:
                            PluginsMarketplaceView(
                                serverId: serverId,
                                showInstalledOnly: false,
                                onSettings: { plugin in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        pluginForConfiguration = plugin
                                    }
                                },
                                viewModel: viewModel
                            )
                        case .installed:
                            PluginsMarketplaceView(
                                serverId: serverId,
                                showInstalledOnly: true,
                                onSettings: { plugin in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        pluginForConfiguration = plugin
                                    }
                                },
                                viewModel: viewModel
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showDevBuildSheet) {
            if let sid = serverId {
                DevBuildLogSheet(serverId: sid)
            }
        }
    }
    
    // MARK: - Developer Page
    
    private func openDeveloperPage() {
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let urlString = "\(baseURL)/apply-developer"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    PluginsTab(server: nil, serverId: nil, connectionViewModel: nil)
        .frame(width: LayoutConstants.Dialog.marketplace.width, height: LayoutConstants.Dialog.marketplace.height)
        .background(Color.axBackground)
}
