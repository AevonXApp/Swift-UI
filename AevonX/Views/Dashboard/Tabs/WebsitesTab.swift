//
//  WebsitesTab.swift
//  AevonX
//
//  Websites management tab with SSL status and toggle switches
//

import SwiftUI
import AevonXCoreBridge

struct OldWebsitesTab: View {
    @State private var websites: [Website] = [
        Website(
// ... (trimmed for brevity, I'll use the tool properly)
            name: "api.example.com",
            domain: "api.example.com",
            status: .online,
            sslEnabled: true,
            phpVersion: "8.2",
            lastDeployed: Date().addingTimeInterval(-3600),
            diskUsage: 245.5
        ),
        Website(
            name: "dashboard",
            domain: "app.example.com",
            status: .online,
            sslEnabled: true,
            phpVersion: "8.2",
            lastDeployed: Date().addingTimeInterval(-7200),
            diskUsage: 189.2
        ),
        Website(
            name: "blog",
            domain: "blog.example.com",
            status: .maintenance,
            sslEnabled: true,
            phpVersion: "8.1",
            lastDeployed: Date().addingTimeInterval(-86400),
            diskUsage: 67.8
        ),
        Website(
            name: "legacy-app",
            domain: "old.example.com",
            status: .offline,
            sslEnabled: false,
            phpVersion: "7.4",
            lastDeployed: Date().addingTimeInterval(-604800),
            diskUsage: 423.1
        ),
        Website(
            name: "staging-api",
            domain: "staging.example.com",
            status: .online,
            sslEnabled: true,
            phpVersion: "8.3",
            lastDeployed: Date().addingTimeInterval(-1800),
            diskUsage: 156.3
        ),
        Website(
            name: "internal-tools",
            domain: "internal.local",
            status: .online,
            sslEnabled: false,
            phpVersion: "8.2",
            lastDeployed: Date().addingTimeInterval(-172800),
            diskUsage: 89.5
        )
    ]
    
    @State private var searchText = ""
    @State private var showAddWebsite = false
    
    var filteredWebsites: [Website] {
        if searchText.isEmpty { return websites }
        return websites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.domain.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var onlineCount: Int { websites.filter { $0.status == .online }.count }
    var sslCount: Int { websites.filter { $0.sslEnabled }.count }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Stats Bar
            HStack(spacing: AXSpacing.lg) {
                AXStatCard(
                    icon: "globe",
                    label: "Total Sites",
                    value: "\(websites.count)",
                    color: .axAccentBlue,
                    layout: .horizontal
                )
                
                AXStatCard(
                    icon: "checkmark.circle.fill",
                    label: "Online",
                    value: "\(onlineCount)",
                    color: .axSuccess,
                    layout: .horizontal
                )
                
                AXStatCard(
                    icon: "lock.shield.fill",
                    label: "SSL Secured",
                    value: "\(sslCount)",
                    color: .axAccentGreen,
                    layout: .horizontal
                )
                
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // MARK: - Toolbar
            HStack(spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextMuted)
                    
                    TextField("Search websites...", text: $searchText)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
                .frame(width: LayoutConstants.sidebarWidth)
                
                Spacer()
                
                Button(action: { showAddWebsite = true }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "plus")
                        Text(L10n.Websites.addWebsite)
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // MARK: - Websites Table
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    // Table Header
                    HStack(spacing: AXSpacing.md) {
                        Text(L10n.Websites.status)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.smallLabel, alignment: .leading)
                        
                        Text(L10n.Websites.website)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.fullName, alignment: .leading)
                        
                        Text("SSL")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.status, alignment: .center)
                        
                        Text(L10n.Websites.mockPhp)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.status, alignment: .center)
                        
                        Text(L10n.Websites.disk)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.actions, alignment: .trailing)
                        
                        Text(L10n.Websites.deployed)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.medium, alignment: .leading)
                        
                        Spacer()
                        
                        Text(L10n.Websites.actions)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: LayoutConstants.TableColumn.standard, alignment: .center)
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axBackgroundTertiary)
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    // Table Rows
                    ForEach(filteredWebsites) { website in
                        WebsitesTabRow(website: website)
                        
                        if website.id != filteredWebsites.last?.id {
                            Divider()
                                .background(Color.axBorder)
                                .padding(.leading, AXSpacing.lg)
                        }
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            
            Spacer()
        }
        .sheet(isPresented: $showAddWebsite) {
            AddWebsiteView(serverId: nil, onCreated: {})
        }
    }
}

// MARK: - Websites Tab Row
private struct WebsitesTabRow: View {
    @State var website: Website
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Status Toggle
            Toggle("", isOn: Binding(
                get: { website.status == .online },
                set: { isOn in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        website.status = isOn ? .online : .offline
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
            .frame(width: LayoutConstants.TableColumn.narrow)
            .help(website.status == .online ? "Click to stop" : "Click to start")
            
            // Website Info
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(website.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                
                Text(website.domain)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            .frame(width: LayoutConstants.TableColumn.fullName, alignment: .leading)
            
            // SSL Status
            HStack {
                Image(systemName: website.sslEnabled ? "lock.fill" : "lock.open")
                    .font(.system(size: 14))
                    .foregroundColor(website.sslEnabled ? .axSuccess : .axTextMuted)
                
                if website.sslEnabled {
                    Text("ON")
                        .font(AXTypography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.axSuccess)
                } else {
                    Text("OFF")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .frame(width: LayoutConstants.TableColumn.status, alignment: .center)
            
            // PHP Version
            Text(website.phpVersion ?? "-")
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.axTextSecondary)
                .frame(width: LayoutConstants.TableColumn.status, alignment: .center)
                .padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
            
            // Disk Usage
            Text("\(String(format: "%.1f", website.diskUsage)) MB")
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
                .frame(width: LayoutConstants.TableColumn.actions, alignment: .trailing)
                .monospaced()
            
            // Last Deployed
            Text(timeAgo(from: website.lastDeployed))
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
                .frame(width: LayoutConstants.TableColumn.medium, alignment: .leading)
            
            Spacer()
            
            // Actions
            HStack(spacing: AXSpacing.sm) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: LayoutConstants.IconSize.button, height: LayoutConstants.IconSize.button)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Redeploy")
                
                Button(action: {}) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: LayoutConstants.IconSize.button, height: LayoutConstants.IconSize.button)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help("View Logs")
                
                Menu {
                    Button("Edit Configuration") {}
                    Button("SSL Settings") {}
                    Button("PHP Settings") {}
                    Divider()
                    Button("Clone") {}
                    Button("Backup") {}
                    Divider()
                    Button("Delete", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: LayoutConstants.IconSize.button, height: LayoutConstants.IconSize.button)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
            .frame(width: LayoutConstants.TableColumn.standard, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
    }
    
    private func timeAgo(from date: Date?) -> String {
        AXFormatter.formatTimeAgo(date, fallback: "Never")
    }
}

#Preview {
    OldWebsitesTab()
        .padding()
        .background(Color.axBackground)
}
