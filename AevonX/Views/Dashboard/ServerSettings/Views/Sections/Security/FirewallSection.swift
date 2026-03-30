//
//  FirewallSection.swift
//  AevonX
//
//  Firewall management — detect type, toggle, add/delete rules, block IPs.
//

import SwiftUI

struct FirewallSection: View {
    @ObservedObject var vm: SecurityVM
    @EnvironmentObject var settings: AppSettingsManager
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoadingFirewall {
                        AXSkeletonBlock(lines: 6)
                    } else if vm.firewallType == "none" {
                        noFirewallView
                    } else {
                        statusRow
                        addRuleRow
                        blockIPRow
                        rulesTable
                    }
                }
            }
        }
        .task { await vm.loadFirewall() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "flame.fill", title: L10n.ServerSettings.firewall,
            subtitle: vm.firewallType == "none" ? L10n.ServerSettings.notDetected : vm.firewallType.uppercased(),
            gradient: [.orange, .axWarning],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadFirewall() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }

    private var noFirewallView: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "shield.slash")
                .font(.title2).foregroundColor(.axTextMuted)
            Text(L10n.ServerSettings.noFirewallDetected)
                .font(AXTypography.caption).foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.lg)
    }
}
