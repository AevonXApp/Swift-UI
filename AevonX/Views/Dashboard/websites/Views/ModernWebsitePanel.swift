//
//  ModernWebsitePanel.swift
//  AevonX
//
//  Redesigned sidebar-based website management panel.
//  Zero-Mock - All data fetched via SSH.
//

import SwiftUI
import AevonXCore

// MARK: - Sidebar Items

enum ModernSidebarItem: String, CaseIterable, Identifiable {
    case domainManager = "Domain Manager"
    case siteDirectory = "Site Directory"
    case sslTls = "SSL/TLS"
    case phpSettings = "PHP Settings"
    case trafficControl = "Traffic Control"
    case logs = "Detailed Logs"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .domainManager: return "globe"
        case .siteDirectory: return "folder"
        case .sslTls: return "lock.shield"
        case .phpSettings: return "gearshape"
        case .trafficControl: return "chart.bar"
        case .logs: return "doc.text.magnifyingglass"
        }
    }
}

// MARK: - Modern Website Panel

struct ModernWebsitePanel: View {
    @ObservedObject var viewModel: WebsiteDetailViewModel
    var onBack: () -> Void
    
    @State private var selectedItem: ModernSidebarItem = .domainManager
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            VStack(alignment: .leading, spacing: 0) {
                sidebarHeader
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        ForEach(ModernSidebarItem.allCases) { item in
                            SidebarButton(
                                title: item.rawValue,
                                icon: item.icon,
                                isSelected: selectedItem == item,
                                action: { selectedItem = item }
                            )
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.lg)
                }
                
                Spacer()
                
                sidebarFooter
            }
            .frame(width: 220)
            .background(Color.axSurface)
            
            Divider().background(Color.axBorder)
            
            // Main Content Area
            VStack(spacing: 0) {
                contentHeader
                
                Group {
                    switch selectedItem {
                    case .domainManager: domainManagerView
                    case .siteDirectory: siteDirectoryView
                    case .sslTls: sslTlsView
                    case .phpSettings: phpSettingsView
                    case .trafficControl: trafficControlView
                    case .logs: logsView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axBackground)
            }
        }
        .onAppear {
            Task { await viewModel.loadWebsiteDetails() }
        }
    }
    
    // MARK: - UI Components
    
    private var sidebarHeader: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.axAccentBlue)
                    .padding(AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Control Panel")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
        }
        .padding(AXSpacing.lg)
    }
    
    private var sidebarFooter: some View {
        VStack(spacing: AXSpacing.sm) {
            Divider().background(Color.axBorder)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.website.name)
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    Text(viewModel.website.status.rawValue.capitalized)
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.website.status == .online ? .axSuccess : .axTextMuted)
                }
                Spacer()
                
                Circle()
                    .fill(viewModel.website.status == .online ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 8, height: 8)
            }
            .padding(AXSpacing.md)
        }
    }
    
    private var contentHeader: some View {
        HStack {
            Text(selectedItem.rawValue)
                .font(AXTypography.title)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            if viewModel.isLoadingStats {
                ProgressView().scaleEffect(0.6)
            }
            
            Text(viewModel.website.domain)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 4)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.xs)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(Color.axBackground)
    }
    
    // MARK: - Subviews
    
    private var domainManagerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Port Configuration
                SettingsRow(title: "Listening Port", description: "The internal port this website handles. Typically 80 or 443.") {
                    HStack {
                        TextField("Port", value: $viewModel.customPort, formatter: NumberFormatter())
                            .textFieldStyle(AXTextFieldStyle())
                            .frame(width: 100)
                        
                        Button("Update Port") {
                            Task { await viewModel.updatePort() }
                        }
                        .buttonStyle(AXPrimaryButtonStyle())
                        .disabled(viewModel.isUpdatingPort)
                    }
                }
                
                // Domain Aliases
                SettingsRow(title: "Domain Aliases", description: "Secondary domains pointing to this site (fetched from server_name/ServerAlias).") {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        if viewModel.website.aliases.isEmpty {
                            Text("No aliases detected")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        } else {
                            ForEach(viewModel.website.aliases, id: \.self) { alias in
                                HStack {
                                    Image(systemName: "link")
                                        .font(.system(size: 10))
                                    Text(alias)
                                        .font(AXTypography.body)
                                }
                                .padding(AXSpacing.sm)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }
    
    private var siteDirectoryView: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "folder.fill")
                .font(.system(size: 60))
                .foregroundColor(.axAccentBlue.opacity(0.8))
            
            VStack(spacing: AXSpacing.xs) {
                Text("Site Directory")
                    .font(AXTypography.title2)
                Text(viewModel.website.documentRoot ?? "Unknown path")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            
            Button("Open in File Browser") {
                // Future integration
            }
            .buttonStyle(AXHeaderButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sslTlsView: some View {
        ScrollView {
             VStack(alignment: .leading, spacing: AXSpacing.xl) {
                 InfoCard(title: "SSL Status", systemImage: "lock.shield.fill", color: .axSuccess) {
                     VStack(alignment: .leading, spacing: AXSpacing.md) {
                         StatusItem(label: "Enabled", value: viewModel.website.sslEnabled ? "Yes" : "No")
                         StatusItem(label: "Provider", value: viewModel.website.sslInfo?.provider.rawValue ?? "None")
                         StatusItem(label: "Expiry", value: "Real-time verification pending...")
                     }
                 }
                 
                 Button("Renew Certificate Now") {
                     Task { await viewModel.renewSSL() }
                 }
                 .buttonStyle(AXSecondaryButtonStyle())
             }
             .padding(AXSpacing.xl)
        }
    }
    
    private var phpSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                SettingsRow(title: "PHP-FPM Version", description: "Select the PHP version for this site. Updates fastcgi_pass/SetHandler directly.") {
                    Picker("", selection: $viewModel.phpVersion) {
                        ForEach(viewModel.installedPHPVersions, id: \.self) { v in
                            Text("PHP \(v)").tag(v)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button("Verify PHP Socket") {
                    // Test if fpm socket exists via SSH
                }
                .buttonStyle(AXOutlineButtonStyle())
                
                Button("Save Settings") {
                    Task { await viewModel.saveConfiguration() }
                }
                .buttonStyle(AXPrimaryButtonStyle())
            }
            .padding(AXSpacing.xl)
        }
    }
    
    private var trafficControlView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.activeConnections) Active Connections")
                        .font(AXTypography.headline)
                    Text("Live connections to \(viewModel.website.domain) over port \(viewModel.website.port ?? 80)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                
                Button(action: { Task { await viewModel.fetchRealTimeStats() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            
            List {
                ForEach(viewModel.connectionList) { connection in
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.axAccentBlue)
                        Text(connection.ip)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Text("\(connection.count)")
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.axSurface)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var logsView: some View {
        AdvancedLogView(
            logs: viewModel.logs,
            onRefresh: { Task { await viewModel.fetchLogs() } },
            isLoading: viewModel.isLoadingLogs
        )
    }
}

// MARK: - Components

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(title)
                    .font(AXTypography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.axAccentBlue)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text(description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            
            content()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder, lineWidth: 1))
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let systemImage: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Text(title)
                    .font(AXTypography.headline)
                Spacer()
            }
            
            content()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder, lineWidth: 1))
    }
}

struct StatusItem: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
            Text(value)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
        }
    }
}
