//
//  WAFSection.swift
//  AevonX
//
//  Web Application Firewall section.
//  UI only — all data comes from SecurityManager in 
//

import SwiftUI
import AevonXCoreBridge

struct WAFSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var wafStatus: WAFStatus?
    @State private var ruleCount = 0
    @State private var auditLines: [String] = []
    @State private var isInstalling = false

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
                    statusCard(
                        icon: "list.bullet.rectangle",
                        label: "Active Rules",
                        value: "\(ruleCount)",
                        color: .axAccentPurple
                    )
                    Spacer()
                }

                // Control Panel
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("WAF Controls")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        HStack(spacing: AXSpacing.md) {
                            if wafStatus?.installed == true {
                                AXActionButton(
                                    label: (wafStatus?.enabled ?? false) ? "Disable WAF" : "Enable WAF",
                                    icon: (wafStatus?.enabled ?? false) ? "pause.circle" : "play.circle",
                                    style: (wafStatus?.enabled ?? false) ? .warning : .success,
                                    size: .small
                                ) {
                                    Task { await toggleWAF(enable: !(wafStatus?.enabled ?? false)) }
                                }
                            } else {
                                AXActionButton(
                                    label: isInstalling ? "Installing…" : "Install ModSecurity",
                                    icon: "arrow.down.circle",
                                    style: .primary,
                                    size: .small
                                ) {
                                    Task { await installModSecurity() }
                                }
                            }

                            AXActionButton(
                                label: "Refresh",
                                icon: "arrow.clockwise",
                                style: .ghost,
                                size: .small
                            ) {
                                Task { await loadWAFStatus() }
                            }
                        }
                    }
                }

                // Audit Log
                if wafStatus?.installed == true {
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            AXSectionTitle(title: "Recent WAF Events", icon: "doc.text.fill", iconColor: .axAccentBlue)

                            if auditLines.isEmpty {
                                AXPlaceholder(
                                    icon: "checkmark.shield.fill",
                                    title: "No WAF events recorded",
                                    iconColor: .axSuccess,
                                    iconSize: 24
                                )
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(auditLines.prefix(20).enumerated()), id: \.offset) { index, line in
                                        HStack(spacing: AXSpacing.md) {
                                            Circle()
                                                .fill(wafEventColor(line))
                                                .frame(width: 6, height: 6)
                                            Text(line)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.axTextSecondary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.sm)
                                        .background(index % 2 == 0 ? Color.clear : Color.axBackgroundTertiary.opacity(0.3))
                                    }
                                }
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                                )
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

    private func wafEventColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("blocked") || lower.contains("denied") || lower.contains("attack") { return .axError }
        if lower.contains("warning") { return .axWarning }
        return .axAccentBlue
    }

    // MARK: - Data (from Core)

    private func loadWAFStatus() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        let result = await securityManager.wafStatus(serverId: serverId)
        await MainActor.run { wafStatus = result }

        if result.installed {
            let count = await securityManager.wafRuleCount(serverId: serverId)
            await MainActor.run { ruleCount = count }

            let logs = await securityManager.wafAuditLog(lines: 30, serverId: serverId)
            await MainActor.run { auditLines = logs }
        }
    }

    private func toggleWAF(enable: Bool) async {
        let _ = await securityManager.toggleWAF(enabled: enable, serverId: serverId)
        await loadWAFStatus()
    }

    private func installModSecurity() async {
        isInstalling = true
        defer { Task { @MainActor in isInstalling = false } }

        let _ = await securityManager.installWAF(serverId: serverId)
        await loadWAFStatus()
    }
}
