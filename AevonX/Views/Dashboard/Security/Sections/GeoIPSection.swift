//
//  GeoIPSection.swift
//  AevonX
//
//  GeoIP / Attack Source analysis.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

struct GeoIPSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var attackSources: [AttackSource] = []

    private let securityManager = SecurityManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Stats
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(icon: "globe", label: "Unique IPs", value: "\(attackSources.count)", color: .axAccentBlue)
                    AXStatCard(icon: "exclamationmark.triangle.fill", label: "Total Attempts", value: "\(attackSources.reduce(0) { $0 + $1.count })", color: .axError)
                    Spacer()
                }

                // Attack Sources Table
                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            AXSectionTitle(title: "Top Attack Sources", icon: "map.fill", iconColor: .axError)
                            AXRefreshButton(isLoading: isLoading) {
                                Task { await loadData() }
                            }
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)

                        Divider().background(Color.axBorder)

                        if isLoading {
                            AXLoadingState(message: "Analyzing login sources…", style: .inline)
                        } else if attackSources.isEmpty {
                            AXPlaceholder(
                                icon: "checkmark.shield.fill",
                                title: "No failed login attempts detected"
                            )
                        } else {
                            ForEach(Array(attackSources.enumerated()), id: \.offset) { index, source in
                                HStack {
                                    Text(source.ip)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                    Spacer()
                                    AXBadge(
                                        text: "\(source.count) attempts",
                                        color: source.count > 50 ? .axError : .axWarning,
                                        style: .filled
                                    )
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                            }
                        }
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
