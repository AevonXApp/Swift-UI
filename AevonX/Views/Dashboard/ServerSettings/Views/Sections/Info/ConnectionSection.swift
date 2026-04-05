//
//  ConnectionSection.swift
//  AevonX
//
//  SSH connection details + system (swap/updates) card.
//

import SwiftUI

struct ConnectionSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @ObservedObject var connectionVM: ServerConnectionViewModel
    let server: Server
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            connectionCard
            systemCard
        }
    }

    // MARK: - Connection

    private var connectionCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "link", title: L10n.ServerSettings.connection, subtitle: L10n.ServerSettings.sshConnectionDetails, gradient: [.axAccentGreen, .teal])
                Divider().background(Color.axBorder)
                VStack(spacing: AXSpacing.sm) {
                    SettingsInfoRow(icon: "globe", title: L10n.Field.host, value: maskedHost)
                    SettingsInfoRow(icon: "number", title: L10n.Field.port, value: maskedPort)
                    SettingsInfoRow(icon: "person.fill", title: L10n.Field.username, value: maskedUsername)
                    SettingsInfoRow(icon: "circle.fill", title: L10n.ServerSettings.status,
                                   value: connectionVM.isConnected ? L10n.Status.connected : L10n.Status.disconnected,
                                   valueColor: connectionVM.isConnected ? .axSuccess : .axError)
                }
            }
        }
    }

    // MARK: - System

    private var systemCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "gearshape.2.fill", title: L10n.ServerSettings.system, subtitle: L10n.ServerSettings.swapMemory, gradient: [.axWarning, .orange.opacity(0.7)])
                Divider().background(Color.axBorder)
                swapRow
            }
        }
    }

    private var swapRow: some View {
        HStack {
            Image(systemName: "memorychip").font(AXTypography.caption).foregroundColor(.axTextMuted).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.ServerSettings.swapMemory).font(AXTypography.body).foregroundColor(.axTextPrimary)
                if vm.swapEnabled {
                    Text("\(vm.swapUsed) / \(vm.swapTotal)").font(AXTypography.caption).foregroundColor(.axTextTertiary)
                }
            }
            Spacer()
            ServerSettingsBadge(text: vm.swapEnabled ? L10n.Status.active : L10n.Status.disabled, color: vm.swapEnabled ? .axSuccess : .axTextMuted)
        }
    }

    // MARK: - Privacy

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }
    private var maskedHost: String { server.host }
    private var maskedUsername: String { isMasking && settings.maskUsernames ? PrivacyMask.username(server.username) : server.username }
    private var maskedPort: String { isMasking && settings.maskPortNumbers ? PrivacyMask.port(server.port) : "\(server.port)" }
}
