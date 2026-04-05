//
//  UserStatusView.swift
//  AevonX
//
//  Password status, disk usage, and login history.
//

import SwiftUI

extension AdvancedUserSection {

    // MARK: - Password Status

    var passwordStatusView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.passwordStatus, icon: "key.fill")

            if vm.passwordStatuses.isEmpty {
                emptyText(L10n.ServerSettings.noPasswordData)
            } else {
                ForEach(vm.passwordStatuses) { status in
                    HStack(spacing: AXSpacing.sm) {
                        Circle()
                            .fill(status.statusColor)
                            .frame(width: 6, height: 6)
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(status.username) : status.username)
                            .font(AXTypography.monoXs).fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 70, alignment: .leading)
                        Text(status.statusLabel)
                            .font(AXTypography.caption2).fontWeight(.medium)
                            .foregroundColor(status.statusColor)
                            .frame(width: 70, alignment: .leading)
                        Text(L10n.ServerSettings.changedDate(status.lastChanged))
                            .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                        Spacer()
                        // Lock/Unlock
                        if status.username != "root" {
                            if status.status == "L" {
                                Button(action: { Task { await vm.unlockUser(status.username) } }) {
                                    Text(L10n.ServerSettings.unlock).font(AXTypography.caption2).foregroundColor(.axSuccess)
                                }.buttonStyle(PlainButtonStyle())
                            } else {
                                Button(action: { Task { await vm.lockUser(status.username) } }) {
                                    Text(L10n.ServerSettings.lock).font(AXTypography.caption2).foregroundColor(.axWarning)
                                }.buttonStyle(PlainButtonStyle())
                            }
                            // Sudo toggle
                            if vm.isSudoUser(status.username) {
                                Button(action: { Task { await vm.revokeSudo(status.username) } }) {
                                    Text(L10n.ServerSettings.revokeSudo).font(AXTypography.caption2).foregroundColor(.axError)
                                }.buttonStyle(PlainButtonStyle())
                            } else {
                                Button(action: { Task { await vm.grantSudo(status.username) } }) {
                                    Text(L10n.ServerSettings.grantSudo).font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Disk Usage

    var diskUsageView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.diskUsagePerUser, icon: "externaldrive.fill")

            if vm.diskUsages.isEmpty {
                emptyText(L10n.ServerSettings.noDiskUsageData)
            } else {
                ForEach(vm.diskUsages) { usage in
                    HStack {
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(usage.username) : usage.username)
                            .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                            .frame(width: 80, alignment: .leading)
                        Text(usage.size)
                            .font(AXTypography.monoXs).fontWeight(.medium)
                            .foregroundColor(.axAccentBlue)
                        Spacer()
                        Text(usage.path)
                            .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Login History

    var loginHistoryView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.loginHistory, icon: "clock.arrow.circlepath")

            if vm.loginHistory.isEmpty {
                emptyText(L10n.ServerSettings.noLoginHistory)
            } else {
                ForEach(vm.loginHistory.prefix(15)) { login in
                    HStack(spacing: AXSpacing.sm) {
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(login.user) : login.user)
                            .font(AXTypography.monoXs).fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 70, alignment: .leading)
                        Text(login.fromIP)
                            .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                            .frame(minWidth: 100, alignment: .leading)
                        Text(login.terminal)
                            .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                            .frame(width: 50)
                        Text(login.dateRange)
                            .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
}
