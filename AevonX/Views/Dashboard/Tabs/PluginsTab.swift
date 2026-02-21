//
//  PluginsTab.swift
//  AevonX
//

import SwiftUI
import AevonXCore

struct PluginsTab: View {
    let server: Server?
    let serverId: String?
    let connectionViewModel: ServerConnectionViewModel?
    
    @State private var selectedTab: PluginViewType = .marketplace
    @State private var pluginForConfiguration: Plugin?
    
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
                    // Header with Segmented Control
                    HStack {
                        Text("Plugins")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
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
                    
                    // Content
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
                                }
                            )
                        case .installed:
                            PluginsMarketplaceView(
                                serverId: serverId,
                                showInstalledOnly: true,
                                onSettings: { plugin in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        pluginForConfiguration = plugin
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    PluginsTab(server: nil, serverId: nil, connectionViewModel: nil)
        .frame(width: LayoutConstants.Dialog.marketplace.width, height: LayoutConstants.Dialog.marketplace.height)
        .background(Color.axBackground)
}
