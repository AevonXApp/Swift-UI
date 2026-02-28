//
//  WAFSection.swift
//  AevonX
//
//  Web Application Firewall section.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

struct WAFSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var wafStatus: WAFStatus?

    private let securityManager = SecurityManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Status Cards
                HStack(spacing: AXSpacing.lg) {
                    statusCard(
                        icon: "shield.checkered",
                        label: "ModSecurity",
                        value: (wafStatus?.installed ?? false) ? "Installed" : "Not Installed",
                        color: (wafStatus?.installed ?? false) ? .axSuccess : .axError
                    )
                    statusCard(
                        icon: "power",
                        label: "WAF Engine",
                        value: (wafStatus?.enabled ?? false) ? "Active" : "Inactive",
                        color: (wafStatus?.enabled ?? false) ? .axSuccess : .axWarning
                    )
                    Spacer()
                }

                // Control Panel
                if wafStatus?.installed == true {
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            Text("WAF Controls")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            HStack(spacing: AXSpacing.md) {
                                Button(action: {
                                    Task { await toggleWAF(enable: !(wafStatus?.enabled ?? false)) }
                                }) {
                                    HStack(spacing: AXSpacing.sm) {
                                        Image(systemName: (wafStatus?.enabled ?? false) ? "pause.circle" : "play.circle")
                                            .font(.system(size: 14))
                                        Text((wafStatus?.enabled ?? false) ? "Disable WAF" : "Enable WAF")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AXSpacing.lg)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background((wafStatus?.enabled ?? false) ? Color.axWarning : Color.axSuccess)
                                    .cornerRadius(AXCornerRadius.md)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()
                            }
                        }
                    }
                }

                if isLoading {
                    VStack(spacing: AXSpacing.md) {
                        ProgressView()
                        Text("Checking WAF status…")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.xxxl)
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadWAFStatus() }
    }

    private func statusCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.axTextPrimary)
                Text(label).font(.system(size: 11)).foregroundColor(.axTextSecondary)
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Data (from Core)

    private func loadWAFStatus() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        let result = await securityManager.wafStatus(serverId: serverId)
        await MainActor.run { wafStatus = result }
    }

    private func toggleWAF(enable: Bool) async {
        let _ = await securityManager.toggleWAF(enabled: enable, serverId: serverId)
        await loadWAFStatus()
    }
}
