//
//  SSHLoginsView.swift
//  AevonX
//
//  Failed login attempts and recent SSH logins.
//

import SwiftUI

extension SSHSecurityDetailSection {

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var failedLoginsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                sectionLabel(L10n.ServerSettings.failedLogins(vm.failedLogins.count), icon: "xmark.shield.fill")
                Spacer()
                if vm.failedLogins.count > 10 {
                    Text(L10n.ServerSettings.showingLast10)
                        .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                }
            }

            if vm.failedLogins.isEmpty {
                emptyText(L10n.ServerSettings.noFailedLogins)
            } else {
                ForEach(vm.failedLogins.suffix(10)) { login in
                    HStack(spacing: AXSpacing.sm) {
                        Text(login.timestamp)
                            .font(AXTypography.monoXs).foregroundColor(.axTextTertiary)
                            .frame(width: 110, alignment: .leading)
                        Text(isMasking && settings.maskIPAddresses ? PrivacyMask.ip(login.ip) : login.ip)
                            .font(AXTypography.monoXs).foregroundColor(.axError)
                            .frame(minWidth: 100, alignment: .leading)
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(login.user) : login.user)
                            .font(AXTypography.caption).foregroundColor(.axTextSecondary)
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

    var recentLoginsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.recentLogins, icon: "clock.arrow.circlepath")

            if vm.recentLogins.isEmpty {
                emptyText(L10n.ServerSettings.noRecentLogins)
            } else {
                ForEach(vm.recentLogins.prefix(10)) { login in
                    HStack(spacing: AXSpacing.sm) {
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(login.user) : login.user)
                            .font(AXTypography.monoXs).fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 70, alignment: .leading)
                        Text(isMasking && settings.maskIPAddresses ? PrivacyMask.ip(login.fromIP) : login.fromIP)
                            .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                            .frame(minWidth: 100, alignment: .leading)
                        Text(login.terminal)
                            .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                            .frame(width: 50, alignment: .leading)
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
