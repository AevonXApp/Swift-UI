//
//  WebsiteRow.swift
//  AevonX
//
//  Premium website card component with site logo, status, and quick actions
//

import SwiftUI

// MARK: - Website Card

struct WebsiteCard: View {
    let website: WebsiteInfo
    let onToggle: () -> Void
    let onDeploy: () -> Void
    let onDelete: () -> Void
    let onLogs: () -> Void
    let onConfig: () -> Void
    let onSSL: () -> Void
    let onClone: () -> Void
    let onBackup: () -> Void
    let onSelect: () -> Void

    @State private var isHovered = false
    
    private func openInBrowser() {
        let scheme = website.sslEnabled ? "https" : "http"
        if let url = URL(string: "\(scheme)://\(website.domain)") {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: Logo + Domain + Status
            HStack(spacing: AXSpacing.sm) {
                ZStack(alignment: .bottomTrailing) {
                    SiteLogo(domain: website.domain, sslEnabled: website.sslEnabled)
                    
                    Circle()
                        .fill(website.status == .online ? Color.axSuccess : Color.axError)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.axSurface, lineWidth: 2))
                        .shadow(color: (website.status == .online ? Color.axSuccess : Color.axError).opacity(0.5), radius: 3)
                        .offset(x: 2, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(website.name)
                        .font(AXTypography.callout).fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    Text(website.domain)
                        .font(AXTypography.monoXs).fontWeight(.medium)
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: Binding(
                    get: { website.status == .online },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                .scaleEffect(0.7)
                .frame(width: 36)
            }
            .padding(AXSpacing.md)
            
            // Divider
            Rectangle()
                .fill(Color.axBorder.opacity(0.3))
                .frame(height: 1)
            
            // Middle: Chips
            HStack(spacing: 6) {
                ChipBadge(
                    icon: website.sslEnabled ? "lock.fill" : "lock.open.fill",
                    text: website.sslEnabled ? "SSL" : "HTTP",
                    color: website.sslEnabled ? .axSuccess : .axWarning
                )

                ChipBadge(
                    icon: website.runtime.icon,
                    text: website.phpVersion != nil ? "PHP \(website.phpVersion!)" : website.runtime.rawValue,
                    color: .axAccentBlue
                )

                ChipBadge(
                    icon: "internaldrive",
                    text: website.formattedDiskUsage,
                    color: .axTextSecondary
                )

                if let engine = website.webServerEngine {
                    ChipBadge(
                        icon: engine == "apache" ? "flame.fill" : "bolt.fill",
                        text: engine.capitalized,
                        color: engine == "apache" ? .orange : .blue
                    )
                }

                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            
            // Divider
            Rectangle()
                .fill(Color.axBorder.opacity(0.3))
                .frame(height: 1)
            
            // Bottom: Actions
            HStack(spacing: 6) {
                // Open in browser
                Button(action: openInBrowser) {
                    HStack(spacing: 4) {
                        Image(systemName: "safari")
                            .font(AXTypography.caption2).fontWeight(.bold)
                        Text("Visit")
                            .font(AXTypography.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                ActionButton(icon: "arrow.clockwise", color: .axAccentBlue, tooltip: "Reload", action: onDeploy)
                ActionButton(icon: "doc.text.fill", color: .axTextSecondary, tooltip: "Logs", action: onLogs)
                
                Spacer()
                
                AXActionMenu.websiteActions(
                    onConfig: onConfig,
                    onSSL: onSSL,
                    onClone: onClone,
                    onBackup: onBackup,
                    onDelete: onDelete
                )
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.axSurfaceHover : Color.axSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.axAccentBlue.opacity(0.3) : Color.axBorder.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 12 : 4, y: isHovered ? 6 : 2)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Site Logo

struct SiteLogo: View {
    let domain: String
    var sslEnabled: Bool = false
    var size: CGFloat = 36

    var logoURL: URL? {
        let scheme = sslEnabled ? "https" : "http"
        return URL(string: "\(scheme)://\(domain)/logo.png")
    }
    
    var body: some View {
        AsyncImage(url: logoURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
            case .failure, .empty:
                fallbackIcon
            @unknown default:
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
    }
    
    private var fallbackIcon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.25)
                    .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Chip Badge

struct ChipBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(AXTypography.caption2).fontWeight(.bold)
            Text(text)
                .font(AXTypography.caption).fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let color: Color
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(AXTypography.caption).fontWeight(.bold)
                .foregroundColor(isHovered ? .white : color)
                .frame(width: 26, height: 26)
                .background(isHovered ? color : color.opacity(0.08))
                .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25)) {
                isHovered = hovering
            }
        }
    }
}
