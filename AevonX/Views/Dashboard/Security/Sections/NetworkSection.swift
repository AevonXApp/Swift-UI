//
//  NetworkSection.swift
//  AevonX
//
//  Network Security — port scan, active connections.
//  UI only — all data comes from SecurityManager in 
//

import SwiftUI
import AevonXCoreBridge

private struct IndexedPort: Identifiable {
    let id: Int
    let port: OpenPort
    init(_ index: Int, _ port: OpenPort) { self.id = index; self.port = port }
}

private struct IndexedConnection: Identifiable {
    let id: Int
    let connection: NetworkConnection
    init(_ index: Int, _ connection: NetworkConnection) { self.id = index; self.connection = connection }
}

struct NetworkSection: View {
    let serverId: String
    @EnvironmentObject var settings: AppSettingsManager

    @State private var isLoading = true
    @State private var openPorts: [OpenPort] = []
    @State private var activeConnectionCount: Int = 0
    @State private var topConnectors: [NetworkConnection] = []
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    private var filteredPorts: [OpenPort] {
        if searchText.isEmpty { return openPorts }
        return openPorts.filter {
            $0.port.localizedCaseInsensitiveContains(searchText) ||
            $0.service.localizedCaseInsensitiveContains(searchText) ||
            $0.proto.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredConnections: [NetworkConnection] {
        if searchText.isEmpty { return topConnectors }
        return topConnectors.filter { $0.ip.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(icon: "antenna.radiowaves.left.and.right", label: "Open Ports", value: "\(openPorts.count)", color: .axAccentBlue)
                    AXStatCard(icon: "link", label: "Active Connections", value: "\(activeConnectionCount)", color: .axAccentGreen)
                    AXStatCard(icon: "person.2.fill", label: "Unique IPs", value: "\(topConnectors.count)", color: .axAccentPurple)
                    Spacer()
                }

                // Search
                AXSearchBar(text: $searchText, placeholder: "Search ports, services, IPs…")

                AXDataTable(
                    title: "Open Ports",
                    icon: "network",
                    accentColor: .axAccentBlue,
                    badgeText: "\(openPorts.count) ports",
                    columns: [
                        AXDataColumn(title: "Port", width: 80),
                        AXDataColumn(title: "Proto", width: 60),
                        AXDataColumn(title: "Service", width: nil),
                    ],
                    items: filteredPorts.enumerated().map { IndexedPort($0.offset, $0.element) },
                    totalCount: openPorts.count,
                    isLoading: isLoading,
                    emptyIcon: "network.slash",
                    emptyTitle: "No open ports found"
                ) { item, _ in
                    HStack(spacing: 0) {
                        Text(item.port.port)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 80, alignment: .leading)
                        Text(item.port.proto)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 60, alignment: .leading)
                        Text(item.port.service)
                            .font(.system(size: 12))
                            .foregroundColor(.axAccentBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } trailingContent: {
                    AXRefreshButton(isLoading: isLoading) {
                        Task { await loadNetworkData() }
                    }
                }

                AXDataTable(
                    title: "Top Connected IPs",
                    icon: "person.2.fill",
                    accentColor: .axAccentPurple,
                    badgeText: "\(topConnectors.count) IPs",
                    columns: [
                        AXDataColumn(title: "IP Address", width: nil),
                        AXDataColumn(title: "Connections", width: 100, alignment: .trailing),
                    ],
                    items: filteredConnections.prefix(10).enumerated().map { IndexedConnection($0.offset, $0.element) },
                    totalCount: topConnectors.count,
                    emptyIcon: "link.badge.plus",
                    emptyTitle: "No connection data available"
                ) { item, _ in
                    HStack(spacing: 0) {
                        Text(item.connection.ip)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AXBadge(text: "\(item.connection.count)", color: .axAccentBlue, style: .filled)
                            .frame(width: 100, alignment: .trailing)
                    }
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadNetworkData() }
    }

    // MARK: - Data (from Core)

    private func loadNetworkData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        async let ports = securityManager.openPorts(serverId: serverId)
        async let conns = securityManager.activeConnections(serverId: serverId)

        let (p, c) = await (ports, conns)
        await MainActor.run {
            openPorts = p
            activeConnectionCount = c.total
            topConnectors = c.connections
        }
    }
}
