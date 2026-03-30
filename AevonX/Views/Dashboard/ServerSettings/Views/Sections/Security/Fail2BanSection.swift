//
//  Fail2BanSection.swift
//  AevonX
//
//  Fail2Ban management — jails, banned IPs, unban, logs.
//

import SwiftUI

struct Fail2BanSection: View {
    @ObservedObject var vm: SecurityVM
    @EnvironmentObject var settings: AppSettingsManager
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoadingFail2Ban {
                        AXSkeletonBlock(lines: 5)
                    } else if !vm.fail2BanInstalled {
                        notInstalledView
                    } else {
                        jailsSection
                        logsSection
                    }
                }
            }
        }
        .task { await vm.loadFail2Ban() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "lock.trianglebadge.exclamationmark.fill",
            title: L10n.ServerSettings.fail2ban,
            subtitle: vm.fail2BanInstalled ? L10n.ServerSettings.jailsCount(vm.fail2BanJails.count) : L10n.ServerSettings.notInstalled,
            gradient: [.axAccentPurple, .axAccentBlue],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadFail2Ban() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }

    private var notInstalledView: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "shield.slash")
                .font(.title2).foregroundColor(.axTextMuted)
            Text(L10n.ServerSettings.fail2banNotInstalled)
                .font(AXTypography.caption).foregroundColor(.axTextMuted)
            Text(L10n.ServerSettings.installFail2banDesc)
                .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.lg)
    }
}
