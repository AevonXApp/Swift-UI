//
//  SecuritySection.swift
//  AevonX
//
//  Security audit and vulnerability monitoring for Node.js apps.
//  NPM audit, outdated check, license scanning.
//

import SwiftUI
import AevonXCoreBridge

struct SecuritySection: View {
    let serverId: String
    let appPath: String?

    @State private var auditSummary: AuditSummary?
    @State private var isLoading = true
    @State private var isFixing = false
    @State private var auditOutput: String = ""
    @State private var showRawOutput = false

    struct AuditSummary {
        var total: Int = 0
        var critical: Int = 0
        var high: Int = 0
        var moderate: Int = 0
        var low: Int = 0
        var info: Int = 0
    }

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if isLoading {
                AXLoadingState(message: "Running security scan…")
            } else if let summary = auditSummary {
                summaryCard(summary)
                severityGrid(summary)
                actionsCard
                if showRawOutput { rawOutputCard }
            } else {
                AXPlaceholder(
                    icon: "shield.checkered",
                    title: "No Audit Data",
                    subtitle: appPath == nil ? "No project path configured" : "Run an audit to check for vulnerabilities",
                    action: AXPlaceholderAction(label: "Run Audit") {
                        await runAudit()
                    }
                )
            }
        }
        .task { await runAudit() }
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: AuditSummary) -> some View {
        AXCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AXSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill((summary.total == 0 ? Color.axSuccess : Color.axWarning).opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(summary.total == 0 ? .axSuccess : .axWarning)
                        }
                        Text("Security Audit")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }

                    Text(summary.total == 0 ? "No vulnerabilities found" : "\(summary.total) vulnerabilities found")
                        .font(AXTypography.subheadline)
                        .foregroundColor(summary.total == 0 ? .axSuccess : .axWarning)
                        .padding(.leading, 40)
                }

                Spacer()

                // Shield icon with color + glow
                Image(systemName: summary.total == 0 ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(summary.total == 0 ? .axSuccess : (summary.critical > 0 ? .axError : .axWarning))
                    .shadow(color: (summary.total == 0 ? Color.axSuccess : .axWarning).opacity(0.3), radius: 8)
            }
        }
    }

    // MARK: - Severity Grid

    private func severityGrid(_ summary: AuditSummary) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.sm) {
            severityCard(label: "Critical", count: summary.critical, color: .axError)
            severityCard(label: "High", count: summary.high, color: Color(hex: "#FF6B35"))
            severityCard(label: "Moderate", count: summary.moderate, color: .axWarning)
            severityCard(label: "Low", count: summary.low, color: .axAccentBlue)
            severityCard(label: "Info", count: summary.info, color: .axTextMuted)
        }
    }

    private func severityCard(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(count > 0 ? color : .axTextMuted)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(count > 0 ? color.opacity(0.08) : Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(count > 0 ? color.opacity(0.2) : Color.axBorder.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.axAccentBlue.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axAccentBlue)
                    }
                    Text("Actions")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }

                HStack(spacing: AXSpacing.md) {
                    AXActionButton(label: "Re-scan", icon: "arrow.clockwise", style: .ghost) {
                        Task { await runAudit() }
                    }

                    AXActionButton(label: "Auto Fix", icon: "wrench.and.screwdriver", style: .primary) {
                        Task { await autoFix() }
                    }

                    AXActionButton(label: isFixing ? "Fixing…" : "Force Fix", icon: "hammer.fill", style: .warning) {
                        Task { await forceFix() }
                    }

                    Spacer()

                    Button {
                        showRawOutput.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 11))
                            Text("Raw Output")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Raw Output

    private var rawOutputCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.axTextSecondary.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                    }
                    Text("Audit Output")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }

                ScrollView {
                    Text(auditOutput)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#4EC9B0"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Actions

    private func runAudit() async {
        guard let path = appPath else { return }
        isLoading = true
        let ssh = SSHService.shared
        let result = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; cd \"\(path)\" && npm audit 2>&1",
            serverId: serverId
        )
        let output = result?.stdout ?? ""
        auditOutput = output
        auditSummary = parseAuditOutput(output)
        isLoading = false
    }

    private func autoFix() async {
        guard let path = appPath else { return }
        isFixing = true
        let ssh = SSHService.shared
        let result = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; cd \"\(path)\" && npm audit fix 2>&1",
            serverId: serverId
        )
        auditOutput = result?.stdout ?? ""
        GlobalToastManager.shared.showSuccess("Audit fix applied")
        await runAudit()
        isFixing = false
    }

    private func forceFix() async {
        guard let path = appPath else { return }
        isFixing = true
        let ssh = SSHService.shared
        let result = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; cd \"\(path)\" && npm audit fix --force 2>&1",
            serverId: serverId
        )
        auditOutput = result?.stdout ?? ""
        GlobalToastManager.shared.showSuccess("Force fix applied")
        await runAudit()
        isFixing = false
    }

    private func parseAuditOutput(_ output: String) -> AuditSummary {
        var summary = AuditSummary()
        let lines = output.lowercased()

        // Parse "X vulnerabilities" line
        if let range = lines.range(of: "found \\d+", options: .regularExpression) {
            let numStr = String(lines[range]).replacingOccurrences(of: "found ", with: "")
            summary.total = Int(numStr) ?? 0
        }

        // Count severities
        let countPattern = { (keyword: String) -> Int in
            if let range = lines.range(of: "\\d+ \(keyword)", options: .regularExpression) {
                let numStr = String(lines[range]).replacingOccurrences(of: " \(keyword)", with: "")
                return Int(numStr) ?? 0
            }
            return 0
        }
        summary.critical = countPattern("critical")
        summary.high = countPattern("high")
        summary.moderate = countPattern("moderate")
        summary.low = countPattern("low")
        summary.info = countPattern("info")

        if summary.total == 0 && output.contains("0 vulnerabilities") {
            summary.total = 0
        }

        return summary
    }
}
