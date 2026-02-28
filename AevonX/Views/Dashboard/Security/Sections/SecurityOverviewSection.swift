//
//  SecurityOverviewSection.swift
//  AevonX
//
//  Security Dashboard overview with score, alerts, and protection status.
//  UI only — all data comes from SecurityManager in AevonXCore.
//  Phase 2: Dynamic protection status, recommendations, wired quick actions.
//

import SwiftUI
import AevonXCore

struct SecurityOverviewSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var score: SecurityScore?
    @State private var wafActive = false
    @State private var isScanning = false

    private let securityManager = SecurityManager.shared

    // Parsed recommendations from hardeningData
    private var recommendations: [(icon: String, title: String, severity: String, color: Color)] {
        guard let data = score?.hardeningData else { return [] }
        var items: [(icon: String, title: String, severity: String, color: Color)] = []

        // Check each hardening aspect
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
            items.append((icon: "shield.lefthalf.filled", title: "Enable WAF (ModSecurity)", severity: "Medium", color: .axWarning))
        }
        if (score?.failedLogins ?? 0) > 100 {
            items.append((icon: "exclamationmark.triangle.fill", title: "High number of failed logins detected", severity: "High", color: .axWarning))
        }
        if (score?.bannedIPs ?? 0) > 50 {
            items.append((icon: "xmark.shield.fill", title: "Many IPs banned — review ban list", severity: "Medium", color: .axAccentBlue))
        }

        // If everything is fine
        if items.isEmpty {
            items.append((icon: "checkmark.shield.fill", title: "All security checks passed!", severity: "Good", color: .axSuccess))
        }

        return items
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Score + Status Row
                HStack(spacing: AXSpacing.lg) {
                    securityScoreCard
                    protectionStatusGrid
                }

                // Stats Row
                statsRow

                // Recommendations (Phase 2)
                recommendationsCard

                // Quick Actions
                quickActionsCard

                // Recent Events
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

    // MARK: - Protection Status Grid (Phase 2: dynamic WAF)

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

    // MARK: - Recommendations (Phase 2)

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
                        Task { await loadOverviewData() }
                    }
                    AXActionButton(label: "One-Click Harden", icon: "lock.shield", style: .ghost, size: .small) {
                        // Future: apply all security recommendations
                    }
                    AXActionButton(label: "Generate Report", icon: "doc.text", style: .ghost, size: .small) {
                        // Future: generate security report
                    }
                }
            }
        }
    }



    // MARK: - Recent Events

    private var recentEventsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionTitle(title: "Recent Security Events")

                if isLoading {
                    AXLoadingState(message: "Loading events...", style: .inline)
                } else {
                    Text("Events will appear here once connected")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xl)
                }
            }
        }
    }

    // MARK: - Load Data (from Core)

    private func loadOverviewData() async {
        isLoading = true
        isScanning = true
        defer { Task { @MainActor in isLoading = false; isScanning = false } }

        // Security score + hardening data
        let result = await securityManager.hardeningCheck(serverId: serverId)
        await MainActor.run { score = result }

        // WAF status (dynamic — from Core)
        let waf = await securityManager.wafStatus(serverId: serverId)
        await MainActor.run { wafActive = waf.enabled }
    }
}
