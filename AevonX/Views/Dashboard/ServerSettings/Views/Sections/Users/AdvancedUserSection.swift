//
//  AdvancedUserSection.swift
//  AevonX
//
//  Advanced user management — sessions, groups, sudo, lock/unlock, disk usage.
//

import SwiftUI

struct AdvancedUserSection: View {
    @ObservedObject var vm: UserManagementVM
    @EnvironmentObject var settings: AppSettingsManager
    @State private var isExpanded = true

    var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoading {
                        AXSkeletonBlock(lines: 8)
                    } else {
                        sessionsView
                        groupsView
                        passwordStatusView
                        diskUsageView
                        loginHistoryView
                        msgOverlay
                    }
                }
            }
        }
        .task { await vm.loadAll() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "person.3.fill", title: L10n.ServerSettings.advancedUsers,
            subtitle: L10n.ServerSettings.sessionsGroupsSummary(vm.activeSessions.count, vm.groups.count),
            gradient: [.cyan, .axAccentBlue],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadAll() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }

    var msgOverlay: some View {
        Group {
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).fontWeight(.medium)
                .foregroundColor(ok ? .axSuccess : .axError)
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                .background((ok ? Color.axSuccess : Color.axError).opacity(0.12))
                .cornerRadius(AXCornerRadius.sm)
                .transition(.opacity)
            }
        }
    }
}
