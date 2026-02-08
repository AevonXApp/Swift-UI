//
//  WebsitesTab.swift
//  AevonX
//
//  Websites management tab with SSL status and toggle switches
//

import SwiftUI

struct WebsitesTab: View {
    @State private var websites: [Website] = [
        Website(
            name: "api.aevonx.io",
            domain: "api.aevonx.io",
            status: .online,
            sslEnabled: true,
            phpVersion: "8.2",
            lastDeployed: Date().addingTimeInterval(-3600),
            diskUsage: 245.5
        ),
        Website(
            name: "dashboard",
            domain: "app.aevonx.io",
            status: .online,
            sslEnabled: true,
            phpVersion: "8.2",
            lastDeployed: Date().addingTimeInterval(-7200),
            diskUsage: 189.2
        ),
        Website(
            name: "blog",
            domain: "blog.aevonx.io",
            status: .maintenance,
            sslEnabled: true,
            phpVersion: "8.1",
            lastDeployed: Date().addingTimeInterval(-86400),
            diskUsage: 67.8
        ),
        Website(
            name: "legacy-app",
            domain: "old.aevonx.io",
            status: .offline,
            sslEnabled: false,
            phpVersion: "7.4",
            lastDeployed: Date().addingTimeInterval(-604800),
            diskUsage: 423.1
        ),
        Website(
            name: "staging-api",
            domain: "staging-api.aevonx.io",
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
                WebsiteStatCard(
                    title: "Total Sites",
                    value: "\(websites.count)",
                    icon: "globe",
                    color: .axAccentBlue
                )
                
                WebsiteStatCard(
                    title: "Online",
                    value: "\(onlineCount)",
                    icon: "checkmark.circle.fill",
                    color: .axSuccess
                )
                
                WebsiteStatCard(
                    title: "SSL Secured",
                    value: "\(sslCount)",
                    icon: "lock.shield.fill",
                    color: .axAccentGreen
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
                .frame(width: 280)
                
                Spacer()
                
                Button(action: { showAddWebsite = true }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "plus")
                        Text("Add Website")
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
                        Text("Status")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 70, alignment: .leading)
                        
                        Text("Website")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 200, alignment: .leading)
                        
                        Text("SSL")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 60, alignment: .center)
                        
                        Text("PHP")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 60, alignment: .center)
                        
                        Text("Disk")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 80, alignment: .trailing)
                        
                        Text("Deployed")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                        
                        Text("Actions")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 120, alignment: .center)
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axBackgroundTertiary)
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    // Table Rows
                    ForEach(filteredWebsites) { website in
                        WebsiteRow(website: website)
                        
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
            AddWebsiteView()
        }
    }
}

// MARK: - Website Stat Card
struct WebsiteStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .cornerRadius(AXCornerRadius.md)
    }
}

// MARK: - Website Row
struct WebsiteRow: View {
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
            .frame(width: 50)
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
            .frame(width: 200, alignment: .leading)
            
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
            .frame(width: 60, alignment: .center)
            
            // PHP Version
            Text(website.phpVersion ?? "-")
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.axTextSecondary)
                .frame(width: 60, alignment: .center)
                .padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
            
            // Disk Usage
            Text("\(String(format: "%.1f", website.diskUsage)) MB")
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
                .frame(width: 80, alignment: .trailing)
                .monospaced()
            
            // Last Deployed
            Text(timeAgo(from: website.lastDeployed))
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            // Actions
            HStack(spacing: AXSpacing.sm) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 28, height: 28)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Redeploy")
                
                Button(action: {}) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
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
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
            .frame(width: 120, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
    }
    
    private func timeAgo(from date: Date?) -> String {
        guard let date = date else { return "Never" }
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Add Website View
struct AddWebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var domain = ""
    @State private var phpVersion = "8.2"
    @State private var enableSSL = true
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Header
            HStack {
                Text("Add New Website")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(Color.axBorder)
            
            // Form
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Domain Name")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("example.com", text: $domain)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("PHP Version")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    Picker("", selection: $phpVersion) {
                        Text("8.3").tag("8.3")
                        Text("8.2").tag("8.2")
                        Text("8.1").tag("8.1")
                        Text("8.0").tag("8.0")
                        Text("7.4").tag("7.4")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text("Enable SSL")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("Auto-generate Let's Encrypt certificate")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $enableSSL)
                        .toggleStyle(SwitchToggleStyle(tint: .axAccentGreen))
                        .frame(width: 40)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: AXSpacing.md) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { dismiss() }) {
                    Text("Create Website")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 450, height: 400)
        .background(Color.axBackground)
    }
}

#Preview {
    WebsitesTab()
        .padding()
        .background(Color.axBackground)
}
