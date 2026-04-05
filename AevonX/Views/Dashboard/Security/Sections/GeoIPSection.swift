//
//  GeoIPSection.swift
//  AevonX
//
//  GeoIP / Attack Source analysis.
//  UI only — all data comes from SecurityManager in 
//

import SwiftUI
import AevonXCoreBridge

private struct IndexedAttack: Identifiable {
    let id: Int; let src: AttackSource
    init(_ i: Int, _ s: AttackSource) { self.id = i; self.src = s }
}

struct GeoIPSection: View {
    let serverId: String
    @EnvironmentObject var settings: AppSettingsManager

    @State private var isLoading = true
    @State private var attackSources: [AttackSource] = []
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    private var filteredSources: [AttackSource] {
        if searchText.isEmpty { return attackSources }
        return attackSources.filter { $0.ip.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Stats
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(icon: "globe", label: "Unique IPs", value: "\(attackSources.count)", color: .axAccentBlue)
                    AXStatCard(icon: "exclamationmark.triangle.fill", label: "Total Attempts", value: "\(attackSources.reduce(0) { $0 + $1.count })", color: .axError)
                    Spacer()
                }

                // Search
                AXSearchBar(text: $searchText, placeholder: "Search IP addresses…")

                // Attack Sources Table
                AXDataTable(
                    title: "Top Attack Sources",
                    icon: "map.fill",
                    iconColor: .axError,
                    accentColor: .axError,
                    badgeText: "\(attackSources.count) sources",
                    columns: [
                        AXDataColumn(title: "IP Address", width: nil),
                        AXDataColumn(title: "Attempts", width: 120, alignment: .trailing),
                    ],
                    items: filteredSources.enumerated().map { IndexedAttack($0.offset, $0.element) },
                    totalCount: attackSources.count,
                    isLoading: isLoading,
                    emptyIcon: "checkmark.shield.fill",
                    emptyTitle: "No failed login attempts detected"
                ) { item, _ in
                    HStack(spacing: 0) {
                        Text(item.src.ip)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AXBadge(
                            text: "\(item.src.count) attempts",
                            color: item.src.count > 50 ? .axError : .axWarning,
                            style: .filled
                        )
                        .frame(width: 120, alignment: .trailing)
                    }
                } trailingContent: {
                    AXRefreshButton(isLoading: isLoading) {
                        Task { await loadData() }
                    }
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadData() }
    }

    private func loadData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        let result = await securityManager.topFailedLoginIPs(limit: 20, serverId: serverId)
        await MainActor.run { attackSources = result }
    }
}
