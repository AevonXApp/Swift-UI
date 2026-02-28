//
//  AISecuritySection.swift
//  AevonX
//
//  AI Security Assistant — AI-powered threat analysis.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

struct AISecuritySection: View {
    let serverId: String

    @State private var isAnalyzing = false
    @State private var selectedFeature = 0
    @State private var aiData: AISecurityData?
    @State private var configIssues: [(setting: String, current: String, recommended: String, risk: String)] = []
    @State private var recommendations: [(severity: String, title: String, description: String)] = []

    private let securityManager = SecurityManager.shared

    private let features = ["Log Summary", "Threat Analysis", "Config Audit", "Recommendations"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // AI Header
                headerCard

                // Tabs
                tabSwitcher

                switch selectedFeature {
                case 0: logSummaryView
                case 1: threatAnalysisView
                case 2: configAuditView
                case 3: recommendationsView
                default: logSummaryView
                }
            }
            .padding(AXSpacing.xxl)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.lg) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(Color.axAccentBlue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                    .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("AI Security Assistant")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("AI-powered analysis of your server security posture")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()

                Button(action: { Task { await runFullAnalysis() } }) {
                    HStack(spacing: AXSpacing.xs) {
                        if isAnalyzing { ProgressView().scaleEffect(0.6) }
                        else { Image(systemName: "sparkles").font(.system(size: 12)) }
                        Text(isAnalyzing ? "Analyzing…" : "Analyze Server")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(isAnalyzing ? Color.axTextMuted : Color.axAccentBlue)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isAnalyzing)
            }
        }
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        AXTabSwitcher(
            labels: features,
            selected: $selectedFeature
        )
    }

    // MARK: - Log Summary (redesigned)

    private var logSummaryView: some View {
        VStack(spacing: AXSpacing.lg) {
            if let data = aiData {
                // Stats row
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(
                        icon: "xmark.circle.fill",
                        label: "Failed Logins",
                        value: formatNumber(data.failedLogins),
                        color: .axError
                    )
                    AXStatCard(
                        icon: "checkmark.circle.fill",
                        label: "Successful Logins",
                        value: formatNumber(data.acceptedLogins),
                        color: .axSuccess
                    )
                    AXStatCard(
                        icon: "person.2.fill",
                        label: "Attack Sources",
                        value: "\(data.topAttackers.count)",
                        color: .axWarning
                    )
                    AXStatCard(
                        icon: "shield.fill",
                        label: "Risk Level",
                        value: data.failedLogins > 1000 ? "High" : data.failedLogins > 100 ? "Medium" : "Low",
                        color: data.failedLogins > 1000 ? .axError : data.failedLogins > 100 ? .axWarning : .axSuccess
                    )
                }

                // Top Attackers Table
                if !data.topAttackers.isEmpty {
                    AXCard(padding: 0) {
                        VStack(spacing: 0) {
                            AXSectionTitle(title: "Top Attack Sources", icon: "exclamationmark.triangle.fill", iconColor: .axError) {
                                AXBadge(text: "\(data.topAttackers.count) sources", color: .axTextMuted, style: .soft)
                            }
                            .padding(AXSpacing.lg)

                            Divider().background(Color.axBorder)

                            // Table header
                            HStack(spacing: 0) {
                                Text("#").frame(width: 30, alignment: .leading)
                                Text("IP Address").frame(maxWidth: .infinity, alignment: .leading)
                                Text("Attempts").frame(width: 100, alignment: .trailing)
                                Text("Severity").frame(width: 80, alignment: .center)
                            }
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axBackgroundTertiary.opacity(0.5))

                            Divider().background(Color.axBorder)

                            ForEach(Array(data.topAttackers.prefix(10).enumerated()), id: \.offset) { index, attacker in
                                HStack(spacing: 0) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axTextMuted)
                                        .frame(width: 30, alignment: .leading)

                                    HStack(spacing: AXSpacing.sm) {
                                        Circle()
                                            .fill(attackerColor(attacker.count))
                                            .frame(width: 6, height: 6)
                                        Text(attacker.ip)
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(.axTextPrimary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Text(formatNumber(attacker.count))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(attackerColor(attacker.count))
                                        .frame(width: 100, alignment: .trailing)

                                    Text(attackerSeverity(attacker.count))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(attackerColor(attacker.count))
                                        .padding(.horizontal, AXSpacing.xs)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule().fill(attackerColor(attacker.count).opacity(0.1))
                                        )
                                        .frame(width: 80, alignment: .center)
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                            }
                        }
                    }
                }
            } else {
                // Empty state
                AXCard {
                    AXPlaceholder(
                        icon: "waveform.path.ecg",
                        title: "No Analysis Data",
                        subtitle: "Click \"Analyze Server\" to scan logs and generate a security report"
                    )
                }
            }
        }
    }

    // MARK: - Threat Analysis

    private var threatAnalysisView: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionTitle(title: "Threat Analysis", icon: "exclamationmark.shield.fill", iconColor: .axWarning)

                Divider().background(Color.axBorder)

                if recommendations.isEmpty {
                    AXPlaceholder(
                        icon: "shield.checkered",
                        title: "Run analysis to detect potential threats"
                    )
                } else {
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { _, rec in
                        let isHigh = rec.severity == "HIGH"
                        HStack(alignment: .top, spacing: AXSpacing.md) {
                            Image(systemName: isHigh ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(isHigh ? .axError : .axWarning)
                                .frame(width: 28, height: 28)
                                .background((isHigh ? Color.axError : Color.axWarning).opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)

                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                HStack {
                                    Text(rec.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.axTextPrimary)
                                    Spacer()
                                    Text(rec.severity)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(isHigh ? .axError : .axWarning)
                                        .padding(.horizontal, AXSpacing.sm)
                                        .padding(.vertical, 2)
                                        .background((isHigh ? Color.axError : Color.axWarning).opacity(0.1))
                                        .cornerRadius(AXCornerRadius.sm)
                                }
                                Text(rec.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextSecondary)
                            }
                        }
                        .padding(AXSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(Color.axSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke((isHigh ? Color.axError : Color.axWarning).opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Config Audit

    private var configAuditView: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    AXSectionTitle(title: "Configuration Audit", icon: "gearshape.fill")
                    if !configIssues.isEmpty {
                        AXBadge(text: "\(configIssues.count) issues", color: .axWarning, style: .filled)
                    }
                }
                .padding(AXSpacing.lg)

                Divider().background(Color.axBorder)

                if configIssues.isEmpty {
                    AXPlaceholder(
                        icon: "doc.text.magnifyingglass",
                        title: "Run analysis to audit server configuration"
                    )
                } else {
                    // Table header
                    HStack(spacing: 0) {
                        Text("Setting").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Current").frame(width: 120, alignment: .center)
                        Text("Recommended").frame(width: 140, alignment: .center)
                        Text("Risk").frame(width: 70, alignment: .center)
                    }
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axBackgroundTertiary.opacity(0.5))

                    Divider().background(Color.axBorder)

                    ForEach(Array(configIssues.enumerated()), id: \.offset) { index, issue in
                        HStack(spacing: 0) {
                            Text(issue.setting)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.axTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(issue.current)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axError)
                                .frame(width: 120, alignment: .center)

                            Text(issue.recommended)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axSuccess)
                                .frame(width: 140, alignment: .center)

                            Text(issue.risk)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(issue.risk == "HIGH" ? .axError : .axWarning)
                                .padding(.horizontal, AXSpacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill((issue.risk == "HIGH" ? Color.axError : Color.axWarning).opacity(0.1))
                                )
                                .frame(width: 70, alignment: .center)
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                    }
                }
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsView: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionTitle(title: "Security Recommendations", icon: "lightbulb.fill", iconColor: .axAccentGreen)

                Divider().background(Color.axBorder)

                if recommendations.isEmpty && configIssues.isEmpty {
                    AXPlaceholder(
                        icon: "lightbulb",
                        title: "AI will provide personalized recommendations",
                        subtitle: "Run analysis to get recommendations based on your server."
                    )
                } else {
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { index, rec in
                        let isHigh = rec.severity == "HIGH"
                        HStack(alignment: .top, spacing: AXSpacing.md) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(isHigh ? Color.axError : Color.axWarning))

                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text(rec.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.axTextPrimary)
                                Text(rec.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, AXSpacing.sm)

                        if index < recommendations.count - 1 {
                            Divider().background(Color.axBorder.opacity(0.3))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers



    private func attackerColor(_ count: Int) -> Color {
        if count > 1000 { return .axError }
        if count > 500 { return .axWarning }
        return .axAccentBlue
    }

    private func attackerSeverity(_ count: Int) -> String {
        if count > 1000 { return "Critical" }
        if count > 500 { return "High" }
        return "Medium"
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Analysis (from Core)

    private func runFullAnalysis() async {
        isAnalyzing = true
        defer { Task { @MainActor in isAnalyzing = false } }

        let data = await securityManager.gatherSecurityData(serverId: serverId)

        await MainActor.run {
            aiData = data
            configIssues = generateConfigIssues(data)
            recommendations = generateRecommendations(data)
        }
    }

    // MARK: - Local Analysis (no commands — pure data processing)

    private func generateConfigIssues(_ data: AISecurityData) -> [(String, String, String, String)] {
        var issues: [(String, String, String, String)] = []
        if data.sshConfig.contains("PasswordAuth:yes") { issues.append(("PasswordAuthentication", "yes", "no", "HIGH")) }
        if data.sshConfig.contains("PermitRootLogin:yes") { issues.append(("PermitRootLogin", "yes", "no / prohibit-password", "HIGH")) }
        if data.hardeningData.contains("ASLR:0") || data.hardeningData.contains("ASLR:1") { issues.append(("ASLR", "Disabled/Partial", "Full (2)", "MEDIUM")) }
        if data.hardeningData.contains("SYN_COOKIES:0") { issues.append(("SYN Cookies", "Disabled", "Enabled", "MEDIUM")) }
        if data.sshConfig.contains("Port:22") { issues.append(("SSH Port", "22 (default)", "Non-standard port", "LOW")) }
        return issues
    }

    private func generateRecommendations(_ data: AISecurityData) -> [(String, String, String)] {
        var recs: [(String, String, String)] = []
        if data.sshConfig.contains("PasswordAuth:yes") { recs.append(("HIGH", "Disable Password Authentication", "SSH password authentication is enabled, making your server vulnerable to brute-force attacks.")) }
        if data.sshConfig.contains("PermitRootLogin:yes") { recs.append(("HIGH", "Disable Root SSH Login", "Root login via SSH is enabled. Disable it and use a regular user with sudo.")) }
        if data.hardeningData.contains("FAIL2BAN:inactive") { recs.append(("HIGH", "Install and Enable fail2ban", "No brute-force protection is active.")) }
        if data.sshConfig.contains("Port:22") { recs.append(("MEDIUM", "Change Default SSH Port", "Using the default SSH port (22) increases exposure to automated attacks.")) }
        return recs
    }
}
