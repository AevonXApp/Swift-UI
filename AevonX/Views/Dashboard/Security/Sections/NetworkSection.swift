//
//  NetworkSection.swift
//  AevonX
//
//  Network Security — port scan, active connections.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

struct NetworkSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var openPorts: [OpenPort] = []
    @State private var activeConnectionCount: Int = 0
    @State private var topConnectors: [NetworkConnection] = []

    private let securityManager = SecurityManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(icon: "antenna.radiowaves.left.and.right", label: "Open Ports", value: "\(openPorts.count)", color: .axAccentBlue)
                    AXStatCard(icon: "link", label: "Active Connections", value: "\(activeConnectionCount)", color: .axAccentGreen)
                    AXStatCard(icon: "person.2.fill", label: "Unique IPs", value: "\(topConnectors.count)", color: .axAccentPurple)
                    Spacer()
                }

                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            AXSectionTitle(title: "Open Ports", icon: "network")
                            AXRefreshButton(isLoading: isLoading) {
                                Task { await loadNetworkData() }
                            }
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)

                        Divider().background(Color.axBorder)

                        if isLoading {
                            AXLoadingState(message: "Scanning network…", style: .inline)
                        } else {
                            ForEach(Array(openPorts.enumerated()), id: \.offset) { index, port in
                                HStack {
                                    Text(port.port)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .frame(width: 80, alignment: .leading)
                                    Text(port.proto)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axTextSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    Text(port.service)
                                        .font(.system(size: 12))
                                        .foregroundColor(.axAccentBlue)
                                    Spacer()
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                            }
                        }
                    }
                }

                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Top Connected IPs")

                        if topConnectors.isEmpty {
                            Text("No connection data available").font(AXTypography.body).foregroundColor(.axTextMuted)
                        } else {
                            ForEach(Array(topConnectors.prefix(10).enumerated()), id: \.offset) { _, connector in
                                HStack {
                                    Text(connector.ip)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                    Spacer()
                                    AXBadge(text: "\(connector.count)", color: .axAccentBlue, style: .filled)
                                }
                            }
                        }
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
