//
//  NetworkManagementSection.swift
//  AevonX
//
//  Main network section — composes interfaces, ports, connections, DNS, routes, hosts.
//

import SwiftUI

struct NetworkManagementSection: View {
    @ObservedObject var vm: NetworkManagerVM
    @EnvironmentObject var settings: AppSettingsManager

    /// Whether privacy masking is active for this section.
    var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

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
                        interfacesSection
                        listeningPortsSection
                        activeConnectionsSection
                        routesSection
                        dnsSection
                        hostsSection
                        statsSection
                        saveMessageOverlay
                    }
                }
            }
        }
        .task { await vm.loadAll() }
    }

    // MARK: - Header

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "network", title: L10n.ServerSettings.networkConnections,
            subtitle: L10n.ServerSettings.interfacesPortsSummary(vm.interfaces.count, vm.listeningPorts.count),
            gradient: [.axAccentBlue, .axAccentGreen],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadAll() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }
}
