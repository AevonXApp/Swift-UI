//
//  SecurityTab.swift
//  AevonX
//
//  Security management with sub-tabs for Firewall, SSH,
//  Brute Force Protection, Anti-Intrusion, and System Hardening
//

import SwiftUI
import AevonXCore

struct SecurityTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel

    @State private var selectedSubTab: Int = 0

    private let subTabs = ["Firewall", "SSH", "Brute Force", "Anti-Intrusion", "Hardening"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.axAccentBlue)
                            .shadow(color: .axAccentBlue.opacity(0.4), radius: 6, x: 0, y: 0)

                        Text("Security")
                            .font(AXTypography.title)
                            .foregroundColor(.axTextPrimary)
                    }

                    Text("Firewall, SSH, and server hardening management")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                // Overall security status badge
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
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.top, AXSpacing.xxl)
            .padding(.bottom, AXSpacing.lg)

            // Sub-tab bar
            AXTabs(tabs: subTabs, selectedTab: $selectedSubTab)
                .padding(.horizontal, AXSpacing.xxl)

            Divider()
                .background(Color.axBorder)
                .padding(.top, AXSpacing.xs)

            // Content
            Group {
                switch selectedSubTab {
                case 0:
                    FirewallSubTab(serverId: serverId)
                case 1:
                    SSHSubTab(serverId: serverId)
                case 2:
                    BruteForceSubTab(serverId: serverId)
                case 3:
                    AntiIntrusionSubTab(serverId: serverId)
                case 4:
                    SystemHardeningSubTab(serverId: serverId)
                default:
                    FirewallSubTab(serverId: serverId)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.axBackground)
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
    .frame(width: 900, height: 700)
    .background(Color.axBackground)
}
