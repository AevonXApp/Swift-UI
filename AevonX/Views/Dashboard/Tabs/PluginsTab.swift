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
    
    enum PluginViewType: String, CaseIterable, Identifiable {
        case marketplace = "Marketplace"
        case installed = "Installed"
        var id: String { rawValue }
    }
    
    var body: some View {
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
                .frame(width: 200)
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
                    PluginsMarketplaceView(serverId: serverId, showInstalledOnly: false)
                case .installed:
                    PluginsMarketplaceView(serverId: serverId, showInstalledOnly: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    PluginsTab(server: nil, serverId: nil, connectionViewModel: nil)
        .frame(width: 800, height: 600)
        .background(Color.axBackground)
}
