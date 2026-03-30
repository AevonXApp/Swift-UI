//
//  SSHSecurityDetailSection.swift
//  AevonX
//
//  Enhanced SSH security — score, keys, fingerprints, logins.
//

import SwiftUI

struct SSHSecurityDetailSection: View {
    @ObservedObject var vm: SecurityVM
    @EnvironmentObject var settings: AppSettingsManager
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoading {
                        AXSkeletonBlock(lines: 8)
                    } else {
                        scoreCard
                        hostKeysSection
                        authorizedKeysSection
                        failedLoginsSection
                        recentLoginsSection
                        msgOverlay
                    }
                }
            }
        }
        .task { await vm.loadSSHSecurity() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "shield.checkered", title: L10n.ServerSettings.sshSecurityAudit,
            subtitle: L10n.ServerSettings.keysLoginsHardening,
            gradient: [.axError, .axAccentPurple],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadSSHSecurity() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }
}
