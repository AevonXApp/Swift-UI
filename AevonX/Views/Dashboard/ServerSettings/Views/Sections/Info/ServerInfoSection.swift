//
//  ServerInfoSection.swift
//  AevonX
//
//  Server information + network + disk cards.
//

import SwiftUI

struct ServerInfoSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            serverInfoCard
            networkCard
            diskStorageCard
        }
    }

    // MARK: - Server Info

    private var serverInfoCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "server.rack", title: L10n.ServerSettings.serverInfo, subtitle: L10n.ServerSettings.systemDetails, gradient: [.axAccentBlue, .axAccentBlue.opacity(0.7)])
                Divider().background(Color.axBorder)

                if vm.isLoadingInfo {
                    AXSkeletonBlock(lines: 7)
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        ServerSettingsHostnameRow(vm: vm)
                        SettingsInfoRow(icon: "desktopcomputer", title: L10n.ServerSettings.os, value: vm.osInfo)
                        SettingsInfoRow(icon: "cpu", title: L10n.ServerSettings.kernel, value: vm.kernelVersion)
                        SettingsInfoRow(icon: "memorychip", title: L10n.ServerSettings.architecture, value: vm.architecture)
                        SettingsInfoRow(icon: "bolt.fill", title: L10n.ServerSettings.cpu, value: vm.cpuModel)
                        SettingsInfoRow(icon: "memorychip.fill", title: L10n.ServerSettings.totalRAM, value: vm.totalRAM)
                        SettingsInfoRow(icon: "clock", title: L10n.ServerSettings.uptime, value: vm.serverUptime)
                        ServerSettingsTimezoneRow(vm: vm)
                    }
                    if let msg = vm.hostnameMsg { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }
                }
            }
        }
    }

    // MARK: - Network

    private var networkCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "network", title: L10n.ServerSettings.network, subtitle: L10n.ServerSettings.ipDNSConfig, gradient: [.axAccentGreen, .axAccentGreen.opacity(0.7)])
                Divider().background(Color.axBorder)

                if vm.isLoadingInfo {
                    AXSkeletonBlock(lines: 4)
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        SettingsInfoRow(icon: "globe", title: L10n.ServerSettings.publicIP, value: maskedIP(vm.publicIP), valueColor: .axAccentBlue)
                        SettingsInfoRow(icon: "network", title: L10n.ServerSettings.privateIP, value: maskedIP(vm.privateIP))
                        SettingsInfoRow(icon: "arrow.triangle.branch", title: L10n.ServerSettings.gateway, value: vm.defaultGateway)
                        SettingsInfoRow(icon: "magnifyingglass", title: L10n.ServerSettings.dnsServers, value: vm.dnsServers)
                    }
                }
            }
        }
    }

    // MARK: - Disk

    private var diskStorageCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "internaldrive", title: L10n.ServerSettings.diskStorage, subtitle: L10n.ServerSettings.partitionUsage, gradient: [.purple, .purple.opacity(0.6)])
                Divider().background(Color.axBorder)

                if vm.isLoadingDisk {
                    AXSkeletonBlock(lines: 3)
                } else if vm.diskPartitions.isEmpty {
                    Text(L10n.ServerSettings.noPartitions).font(AXTypography.caption).foregroundColor(.axTextTertiary)
                } else {
                    ForEach(Array(vm.diskPartitions.enumerated()), id: \.offset) { _, part in
                        DiskPartitionRow(mount: part.mount, size: part.size, used: part.used, percent: part.percent)
                    }
                }
            }
        }
    }

    // MARK: - Privacy

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    private func maskedIP(_ ip: String) -> String {
        ip
    }
}
