//
//  SSHeroSection.swift
//  AevonX
//
//  Hero card + quick actions bar for server settings.
//

import SwiftUI

struct SSHeroSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @ObservedObject var connectionVM: ServerConnectionViewModel
    let server: Server
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(spacing: AXSpacing.md) {
            heroCard
            quickActionsBar
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.xl) {
                serverIcon
                serverDetails
                Spacer()
                ipBadge
            }
        }
    }

    private var serverIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(LinearGradient(
                    colors: [.axAccentBlue, .axAccentGreen.opacity(0.6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .shadow(color: .axAccentBlue.opacity(0.3), radius: 12, y: 4)
            Image(systemName: "server.rack")
                .font(AXTypography.title2)
                .foregroundColor(.white)
        }
    }

    private var serverDetails: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(server.name)
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)
            Text(vm.osInfo.isEmpty ? maskedHost : vm.osInfo)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
            HStack(spacing: AXSpacing.md) {
                ServerSettingsBadge(
                    text: connectionVM.isConnected ? L10n.Status.connected : L10n.Status.offline,
                    color: connectionVM.isConnected ? .axSuccess : .axError
                )
                if !vm.serverUptime.isEmpty {
                    ServerSettingsBadge(text: vm.serverUptime, color: .axAccentBlue, icon: "clock")
                }
                if !vm.architecture.isEmpty {
                    ServerSettingsBadge(text: vm.architecture, color: .axTextMuted, icon: "cpu")
                }
            }
        }
    }

    @ViewBuilder
    private var ipBadge: some View {
        if !vm.publicIP.isEmpty {
            VStack(alignment: .trailing, spacing: AXSpacing.xxs) {
                Text(L10n.ServerSettings.publicIP)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
                    .textCase(.uppercase)
                Text(maskedIP(vm.publicIP))
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xxs)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                    .help(settings.showRealOnHover && isMasking ? vm.publicIP : "")
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsBar: some View {
        HStack(spacing: AXSpacing.md) {
            ServerSettingsQuickAction(icon: "arrow.clockwise", title: L10n.Button.refresh, color: .axAccentBlue) {
                await vm.loadAll()
            }
            ServerSettingsQuickAction(icon: "arrow.triangle.2.circlepath", title: L10n.ServerSettings.restartSSH, color: .axWarning) {
                await vm.restartSSH()
            }
            ServerSettingsQuickAction(icon: "arrow.down.circle", title: L10n.ServerSettings.checkUpdates, color: .axAccentGreen) {
                await vm.checkUpdates()
            }
            if vm.updatesAvailable > 0 {
                ServerSettingsQuickAction(icon: "arrow.up.circle.fill", title: L10n.ServerSettings.upgrade(vm.updatesAvailable), color: .axError) {
                    await vm.upgradeSystem()
                }
            }
            Spacer()
        }
    }

    // MARK: - Privacy

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    private var maskedHost: String {
        isMasking && settings.maskIPAddresses ? PrivacyMask.ip(server.host) : server.host
    }

    private func maskedIP(_ ip: String) -> String {
        isMasking && settings.maskIPAddresses ? PrivacyMask.ip(ip) : ip
    }
}
