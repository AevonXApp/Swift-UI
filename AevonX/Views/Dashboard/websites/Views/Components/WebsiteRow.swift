//
//  WebsiteRow.swift
//  AevonX
//
//  Individual website row component with actions
//

import SwiftUI

// MARK: - Website Row

struct WebsiteRow: View {
    let website: WebsiteInfo
    let onToggle: () -> Void
    let onDeploy: () -> Void
    let onDelete: () -> Void
    let onLogs: () -> Void
    let onConfig: () -> Void
    let onSSL: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Status Indicator & Toggle
            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(website.status == .online ? Color.axSuccess : Color.axError)
                    .frame(width: 8, height: 8)
                    .shadow(color: (website.status == .online ? Color.axSuccess : Color.axError).opacity(0.4), radius: 3)
                
                Toggle("", isOn: Binding(
                    get: { website.status == .online },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                .scaleEffect(0.8)
                .frame(width: 44)
            }
            .frame(width: 70, alignment: .leading)

            // Website Info with Premium Typography
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(website.name)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)

                Text(website.domain)
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
            }
            .frame(width: 200, alignment: .leading)

            // SSL Badge - Premium Look
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: website.sslEnabled ? "shield.fill" : "shield.slash")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(website.sslEnabled ? .axSuccess : .axWarning)

                Text(website.sslEnabled ? "SECURED" : "INSECURE")
                    .font(AXTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(website.sslEnabled ? .axSuccess : .axWarning)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 4)
            .background((website.sslEnabled ? Color.axSuccess : Color.axWarning).opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
            .frame(width: 100, alignment: .center)

            // Runtime Integrated Chip
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: website.runtime.icon)
                    .font(.system(size: 10))
                
                Text(website.phpVersion ?? website.runtime.rawValue)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.axAccentBlue)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 4)
            .background(Color.axAccentBlue.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
            .frame(width: 90, alignment: .center)

            // Active Connections (Zero-Mock Live)
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "bolt.horizontal.fill")
                    .font(.system(size: 8))
                Text("\(website.activeConnections)")
                    .font(AXTypography.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.axAccentGreen)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 4)
            .background(Color.axAccentGreen.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
            .frame(width: 50, alignment: .center)

            // Resource Metrics
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(website.formattedDiskUsage)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .monospaced()
                    
                    Text("Disk")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                .frame(width: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeAgo(from: website.lastDeployed))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    Text("Deployed")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                .frame(width: 80)
            }

            Spacer()

            // Quick Actions & More Menu
            HStack(spacing: AXSpacing.sm) {
                // Quick Deploy
                ActionButton(icon: "arrow.clockwise", color: .axAccentBlue, tooltip: "Deploy Now", action: onDeploy)
                
                // Quick Logs
                ActionButton(icon: "doc.text.fill", color: .axTextSecondary, tooltip: "View Logs", action: onLogs)

                // More Actions
                Menu {
                    Section("Configuration") {
                        Button(action: onConfig) {
                            Label("Edit Config", systemImage: "slider.horizontal.3")
                        }
                        Button(action: onSSL) {
                            Label("SSL Settings", systemImage: "lock.shield")
                        }
                    }
                    
                    Section("Management") {
                        Button(action: {}) {
                            Label("Clone Site", systemImage: "doc.on.doc")
                        }
                        Button(action: {}) {
                            Label("Backup", systemImage: "archivebox")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Website", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                        .symbolRenderingMode(.hierarchical)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 32, height: 32)
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(isHovered ? Color.axSurfaceHover : Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isHovered ? Color.axAccentBlue.opacity(0.3) : Color.axBorder, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private func timeAgo(from date: Date?) -> String {
        guard let date = date else { return "Never" }
        let interval = Date().timeIntervalSince(date)

        if interval < 60 { return "Just now" }
        else if interval < 3600 { return "\(Int(interval / 60))m ago" }
        else if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        else { return "\(Int(interval / 86400))d ago" }
    }
}

// MARK: - Helper UI Components

struct ActionButton: View {
    let icon: String
    let color: Color
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isHovered ? .white : color)
                .frame(width: 30, height: 30)
                .background(isHovered ? color : color.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}
