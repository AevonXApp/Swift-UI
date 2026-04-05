//
//  Fail2BanJailsView.swift
//  AevonX
//
//  Fail2Ban jails list with banned IPs and unban action.
//

import SwiftUI

extension Fail2BanSection {

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var jailsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            ForEach(vm.fail2BanJails) { jail in
                jailCard(jail)
            }

            if vm.fail2BanJails.isEmpty {
                Text(L10n.ServerSettings.noJailsConfigured)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.sm)
            }

            // Message overlay
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).fontWeight(.medium)
                .foregroundColor(ok ? .axSuccess : .axError)
            }
        }
    }

    private func jailCard(_ jail: Fail2BanJail) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            // Jail header
            HStack {
                Image(systemName: "lock.fill")
                    .font(AXTypography.caption2).foregroundColor(.axAccentPurple)
                Text(jail.name)
                    .font(AXTypography.caption).fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                statBadge(L10n.ServerSettings.banned, value: jail.currentlyBanned, color: .axError)
                statBadge(L10n.ServerSettings.totalFailed, value: jail.currentlyFailed, color: .axWarning)
            }

            // Stats row
            HStack(spacing: AXSpacing.lg) {
                statLabel(L10n.ServerSettings.totalBanned, "\(jail.totalBanned)")
                statLabel(L10n.ServerSettings.totalFailed, "\(jail.totalFailed)")
            }

            // Banned IPs
            if !jail.bannedIPs.isEmpty {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(L10n.ServerSettings.currentlyBanned)
                        .font(AXTypography.caption2).fontWeight(.medium)
                        .foregroundColor(.axTextMuted)
                    ForEach(jail.bannedIPs, id: \.self) { ip in
                        HStack {
                            Text(ip)
                                .font(AXTypography.monoXs).foregroundColor(.axError)
                            Spacer()
                            Button(action: { Task { await vm.unbanIP(jail: jail.name, ip: ip) } }) {
                                Text(L10n.ServerSettings.unban)
                                    .font(AXTypography.caption2).fontWeight(.medium)
                                    .foregroundColor(.axAccentBlue)
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func statBadge(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Text("\(value)")
                .font(AXTypography.monoXs).fontWeight(.bold)
                .foregroundColor(value > 0 ? color : .axTextMuted)
            Text(label)
                .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
        }
    }

    private func statLabel(_ label: String, _ value: String) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Text(label).font(AXTypography.caption2).foregroundColor(.axTextMuted)
            Text(value).font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
        }
    }
}
