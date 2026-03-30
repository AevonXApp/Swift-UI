//
//  UserSessionsView.swift
//  AevonX
//
//  Active sessions (who) with kill session action.
//

import SwiftUI

extension AdvancedUserSection {

    var sessionsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.activeSessions(vm.activeSessions.count), icon: "person.badge.clock")

            if vm.activeSessions.isEmpty {
                emptyText(L10n.ServerSettings.noActiveSessions)
            } else {
                ForEach(vm.activeSessions) { session in
                    HStack(spacing: AXSpacing.sm) {
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(session.user) : session.user)
                            .font(AXTypography.monoXs).fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 70, alignment: .leading)
                        Text(session.terminal)
                            .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                            .frame(width: 55, alignment: .leading)
                        Text(isMasking && settings.maskIPAddresses ? PrivacyMask.ip(session.fromIP) : session.fromIP)
                            .font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                            .frame(minWidth: 100, alignment: .leading)
                        Text(session.loginTime)
                            .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                        Spacer()
                        Button(action: { Task { await vm.killSession(session.terminal) } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(AXTypography.caption).foregroundColor(.axError)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: icon).font(AXTypography.caption2).foregroundColor(.axAccentBlue)
            Text(title).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
        }
    }

    func emptyText(_ text: String) -> some View {
        Text(text)
            .font(AXTypography.caption).foregroundColor(.axTextMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AXSpacing.xs)
    }
}
