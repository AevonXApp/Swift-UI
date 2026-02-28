//
//  SecurityTab.swift
//  AevonX
//
//  Premium Security management panel with sidebar navigation.
//  Follows the ModernWebsitePanel architecture (sidebar + content sections).
//

import SwiftUI
import AevonXCore

struct SecurityTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel

    @State private var selectedItem: SecuritySidebarItem = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            // Premium Sidebar
            securitySidebar

            Divider()
                .background(Color.axBorder.opacity(0.5))

            // Main Content Area
            VStack(spacing: 0) {
                sectionHeader

                Divider()
                    .background(Color.axBorder.opacity(0.3))

                // Content
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.axBackground)
            }
        }
        .background(Color.axBackground)
    }

    // MARK: - Security Sidebar

    private var securitySidebar: some View {
        VStack(spacing: 0) {
            // Sidebar Header — Security Info Card
            VStack(spacing: AXSpacing.md) {
                // Shield + Title
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.axAccentBlue, .axAccentBlue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: .axAccentBlue.opacity(0.4), radius: 8, x: 0, y: 2)

                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Security Center")
                            .font(AXTypography.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)

                        Text(server.name)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                    }

                    Spacer()
                }

                // Quick Protection Status
                HStack(spacing: AXSpacing.md) {
                    protectionStat(icon: "flame.fill", label: "Firewall", color: .axAccentBlue)
                    protectionStat(icon: "hand.raised.fill", label: "fail2ban", color: .axAccentGreen)
                }
            }
            .padding(AXSpacing.lg)

            Divider()
                .background(Color.axBorder.opacity(0.3))

            // Navigation Items
            ScrollView(showsIndicators: false) {
                VStack(spacing: AXSpacing.xxs) {
                    ForEach(SecuritySidebarItem.categorizedItems(), id: \.0) { category, items in
                        SidebarCategoryHeader(title: category.rawValue, icon: category.icon)
                        ForEach(items) { item in
                            SecuritySidebarButton(
                                item: item,
                                isSelected: selectedItem == item,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedItem = item
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.lg)
            }

            Spacer()

            // Sidebar Footer
            sidebarFooter
        }
        .frame(width: 260)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.axSurface,
                    Color.axSurface.opacity(0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func protectionStat(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextSecondary)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.axBorder.opacity(0.3))

            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.axAccentBlue.opacity(0.7))

                VStack(alignment: .leading, spacing: 2) {
                    Text("15 Security Sections")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                    Text("144 features available")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextTertiary)
                }

                Spacer()
            }
            .padding(AXSpacing.md)
            .background(Color.axBackground.opacity(0.5))
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            // Section Icon + Title
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(selectedItem.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            // Security Status Badge
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(Color.axSuccess)
                    .frame(width: 8, height: 8)
                    .shadow(color: .axSuccess.opacity(0.5), radius: 4, x: 0, y: 0)

                Text("Protected")
                    .font(AXTypography.caption)
                    .foregroundColor(.axSuccess)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSuccess.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axSuccess.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            Color.axSurface.opacity(0.5)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Content View (Section Router)

    @ViewBuilder
    private var contentView: some View {
        switch selectedItem {
        case .dashboard:
            SecurityOverviewSection(serverId: serverId)
        case .firewallRules:
            FirewallSubTab(serverId: serverId)
        case .ssh:
            SSHSubTab(serverId: serverId)
        case .bruteForce:
            BruteForceSubTab(serverId: serverId)
        case .antiIntrusion:
            AntiIntrusionSubTab(serverId: serverId)
        case .hardening:
            SystemHardeningSubTab(serverId: serverId)
        case .users:
            UsersSection(serverId: serverId)
        case .waf:
            WAFSection(serverId: serverId)
        case .geoip:
            GeoIPSection(serverId: serverId)
        case .malware:
            MalwareSection(serverId: serverId)
        case .fileIntegrity:
            FileIntegritySection(serverId: serverId)
        case .network:
            NetworkSection(serverId: serverId)
        case .auditLog:
            AuditLogSection(serverId: serverId)
        case .certificates:
            CertificatesSection(serverId: serverId)
        case .aiAssistant:
            AISecuritySection(serverId: serverId)
        }
    }
}

#Preview {
    SecurityTab(
        server: Server.placeholder(name: "Preview Server"),
        serverId: "preview-id",
        connectionViewModel: ServerConnectionViewModel(
            server: Server.placeholder(name: "Preview Server"),
            serverId: "preview-id"
        )
    )
    .frame(width: 1200, height: 800)
    .background(Color.axBackground)
}
