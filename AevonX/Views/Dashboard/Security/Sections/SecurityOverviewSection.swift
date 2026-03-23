//
//  SecurityOverviewSection.swift
//  AevonX
//
//  Security Dashboard overview with score, alerts, and protection status.
//  UI only — all data comes from SecurityManager in 
//

import SwiftUI
import AevonXCoreBridge
#if os(macOS)
import AppKit
#endif

struct SecurityOverviewSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var score: SecurityScore?
    @State private var wafActive = false
    @State private var isScanning = false
    @State private var isHardening = false
    @State private var recentEvents: [String] = []
    @State private var hardenResult: String?

    private let securityManager = SecurityManager.shared

    // Parsed recommendations from hardeningData
    private var recommendations: [(icon: String, title: String, severity: String, color: Color)] {
        guard let _ = score?.hardeningData else { return [] }
        var items: [(icon: String, title: String, severity: String, color: Color)] = []

        if !(score?.firewallActive ?? false) {
            items.append((icon: "flame.fill", title: "Enable Firewall", severity: "Critical", color: .axError))
        }
        if !(score?.fail2banActive ?? false) {
            items.append((icon: "hand.raised.fill", title: "Install fail2ban", severity: "Critical", color: .axError))
        }
        if !(score?.sshSecure ?? false) {
            items.append((icon: "terminal.fill", title: "Harden SSH — disable password login", severity: "High", color: .axWarning))
        }
        if !wafActive {
            items.append((icon: "shield.checkered", title: "Install AXCerberus WAF", severity: "Medium", color: .axWarning))
        }
        if (score?.failedLogins ?? 0) > 100 {
            items.append((icon: "exclamationmark.triangle.fill", title: "High number of failed logins detected", severity: "High", color: .axWarning))
        }
        if (score?.bannedIPs ?? 0) > 50 {
            items.append((icon: "xmark.shield.fill", title: "Many IPs banned — review ban list", severity: "Medium", color: .axAccentBlue))
        }

        if items.isEmpty {
            items.append((icon: "checkmark.shield.fill", title: "All security checks passed!", severity: "Good", color: .axSuccess))
        }

        return items
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack(spacing: AXSpacing.lg) {
                    securityScoreCard
                    protectionStatusGrid
                }

                statsRow
                recommendationsCard
                quickActionsCard
                recentEventsCard
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadOverviewData() }
    }

    // MARK: - Security Score Card

    private var securityScoreCard: some View {
        AXCard {
            VStack(spacing: AXSpacing.lg) {
                AXCircularProgress(
                    value: (score?.value ?? 0) / 100,
                    size: 100,
                    lineWidth: 8,
                    color: scoreColor,
                    showValue: true
                )

                VStack(spacing: AXSpacing.xxs) {
                    Text("Security Score")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text(scoreLabel)
                        .font(AXTypography.caption)
                        .foregroundColor(scoreColor)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var scoreColor: Color {
        let v = score?.value ?? 0
        if v >= 80 { return .axSuccess }
        if v >= 60 { return .axWarning }
        return .axError
    }

    private var scoreLabel: String {
        let v = score?.value ?? 0
        if v >= 80 { return "Well Protected" }
        if v >= 60 { return "Needs Attention" }
        return "Critical Issues"
    }

    // MARK: - Protection Status Grid

    private var protectionStatusGrid: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("Protection Status")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: AXSpacing.md) {
                    protectionItem(icon: "flame.fill", label: "Firewall", active: score?.firewallActive ?? false)
                    protectionItem(icon: "hand.raised.fill", label: "fail2ban", active: score?.fail2banActive ?? false)
                    protectionItem(icon: "terminal.fill", label: "SSH Hardened", active: score?.sshSecure ?? false)
                    protectionItem(icon: "shield.lefthalf.filled", label: "WAF", active: wafActive)
                }
            }
        }
    }

    private func protectionItem(icon: String, label: String, active: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(active ? .axSuccess : .axTextMuted)
                .frame(width: 28, height: 28)
                .background(active ? Color.axSuccess.opacity(0.1) : Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                Text(active ? "Active" : "Inactive")
                    .font(.system(size: 10))
                    .foregroundColor(active ? .axSuccess : .axTextMuted)
            }

            Spacer()
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AXSpacing.lg) {
            AXStatCard(icon: "list.bullet.rectangle", label: "Firewall Rules", value: "\(score?.activeRules ?? 0)", color: .axAccentBlue)
            AXStatCard(icon: "nosign", label: "Banned IPs", value: "\(score?.bannedIPs ?? 0)", color: .axError)
            AXStatCard(icon: "xmark.circle", label: "Failed Logins", value: "\(score?.failedLogins ?? 0)", color: .axWarning)
            AXStatCard(icon: "clock.fill", label: "Last Scan", value: "Just now", color: .axAccentPurple)
        }
    }

    // MARK: - Recommendations

    private var recommendationsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionTitle(title: "Recommendations", icon: "lightbulb.fill", iconColor: .axWarning) {
                    Text("\(recommendations.filter { $0.severity != "Good" }.count) items")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                ForEach(Array(recommendations.enumerated()), id: \.offset) { _, rec in
                    HStack(spacing: AXSpacing.md) {
                        Image(systemName: rec.icon)
                            .font(.system(size: 14))
                            .foregroundColor(rec.color)
                            .frame(width: 28, height: 28)
                            .background(rec.color.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rec.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.axTextPrimary)
                            Text(rec.severity)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(rec.color)
                        }

                        Spacer()
                    }
                    .padding(.vertical, AXSpacing.xs)
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionTitle(title: "Quick Actions")

                HStack(spacing: AXSpacing.md) {
                    AXActionButton(label: isScanning ? "Scanning…" : "Full Scan", icon: "arrow.clockwise", style: .ghost, size: .small) {
                        Task {
                            isScanning = true
                            await loadOverviewData()
                            isScanning = false
                        }
                    }
                    AXActionButton(label: isHardening ? "Hardening…" : "One-Click Harden", icon: "lock.shield", style: .ghost, size: .small) {
                        Task { await performOneClickHarden() }
                    }
                    AXActionButton(label: "Copy Report", icon: "doc.on.clipboard", style: .ghost, size: .small) {
                        Task { await generateReport() }
                    }
                }

                if let result = hardenResult {
                    Text(result)
                        .font(.system(size: 11))
                        .foregroundColor(.axSuccess)
                        .padding(.top, AXSpacing.xs)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Recent Events (Real Auth Log)

    private var recentEventsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionTitle(title: "Recent Security Events", icon: "clock.arrow.circlepath", iconColor: .axAccentBlue)

                if isLoading {
                    AXLoadingState(message: "Loading events...", style: .inline)
                } else if recentEvents.isEmpty {
                    AXPlaceholder(
                        icon: "checkmark.shield.fill",
                        title: "No recent security events",
                        iconColor: .axSuccess,
                        iconSize: 24
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(recentEvents.enumerated()), id: \.offset) { index, event in
                            HStack(spacing: AXSpacing.md) {
                                Circle()
                                    .fill(eventColor(event))
                                    .frame(width: 6, height: 6)

                                Text(event)
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

    private func eventColor(_ event: String) -> Color {
        let lower = event.lowercased()
        if lower.contains("failed") || lower.contains("invalid") { return .axError }
        if lower.contains("accepted") || lower.contains("opened") { return .axSuccess }
        if lower.contains("sudo") || lower.contains("session") { return .axWarning }
        return .axAccentBlue
    }

    // MARK: - Actions

    private func performOneClickHarden() async {
        isHardening = true
        defer { Task { @MainActor in isHardening = false } }

        var results: [String] = []

        if !(score?.firewallActive ?? false) {
            let ok = await securityManager.setFirewall(enabled: true, serverId: serverId)
            results.append(ok ? "✅ Firewall enabled" : "❌ Firewall failed")
        }

        if !(score?.fail2banActive ?? false) {
            let ok = await securityManager.installFail2ban(serverId: serverId)
            results.append(ok ? "✅ fail2ban installed" : "❌ fail2ban failed")
        }

        if !(score?.sshSecure ?? false) {
            let ok = await securityManager.setSSHRootLogin(mode: "prohibit-password", serverId: serverId)
            results.append(ok ? "✅ Root login restricted" : "❌ SSH config failed")
        }

        await MainActor.run {
            hardenResult = results.isEmpty ? "✅ Already hardened" : results.joined(separator: " • ")
        }

        await loadOverviewData()

        try? await Task.sleep(nanoseconds: 5_000_000_000)
        await MainActor.run { hardenResult = nil }
    }

    private func generateReport() async {
        let data = await securityManager.gatherSecurityData(serverId: serverId)
        let waf = await securityManager.wafStatus(serverId: serverId)

        let report = """
        === AevonX Security Report ===
        Generated: \(Date().formatted())

        Security Score: \(Int(score?.value ?? 0))%
        Firewall: \(score?.firewallActive ?? false ? "Active" : "Inactive") (\(score?.activeRules ?? 0) rules)
        fail2ban: \(score?.fail2banActive ?? false ? "Active" : "Inactive") (\(score?.bannedIPs ?? 0) banned IPs)
        SSH: \(score?.sshSecure ?? false ? "Hardened" : "Needs Hardening")
        WAF: \(waf.installed ? (waf.enabled ? "Active" : "Installed (Disabled)") : "Not Installed")

        Login Stats:
          Accepted: \(data.acceptedLogins)
          Failed: \(data.failedLogins)
          Top Attackers: \(data.topAttackers.prefix(5).map { "\($0.ip) (\($0.count))" }.joined(separator: ", "))

        SSH Config: \(data.sshConfig.replacingOccurrences(of: "\n", with: " | "))
        """

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        #endif

        await MainActor.run {
            hardenResult = "📋 Report copied to clipboard"
        }
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        await MainActor.run { hardenResult = nil }
    }

    // MARK: - Load Data

    private func loadOverviewData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        let result = await securityManager.hardeningCheck(serverId: serverId)
        await MainActor.run { score = result }

        let waf = await securityManager.wafStatus(serverId: serverId)
        await MainActor.run { wafActive = waf.enabled }

        let events = await securityManager.authLog(lines: 10, serverId: serverId)
        await MainActor.run { recentEvents = events }
    }
}
