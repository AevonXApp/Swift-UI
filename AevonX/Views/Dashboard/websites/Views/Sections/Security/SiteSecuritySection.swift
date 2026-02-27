//
//  SiteSecuritySection.swift
//  AevonX
//
//  Per-site security management section
//

import SwiftUI
import AevonXCore

struct SiteSecuritySection: View {
    @ObservedObject var viewModel: SiteSecurityViewModel
    @State private var selectedFeature: SiteSecurityFeature?
    @State private var showScanResults = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                SectionHeader(title: "Site Security", icon: "shield.lefthalf.filled")

                // Security Score
                securityScoreCard

                // Feature Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    ForEach(viewModel.securityStatuses) { status in
                        securityFeatureCard(status)
                    }
                }

                // Quick Actions
                ConfigCard(icon: "bolt.shield.fill", title: "Quick Actions", description: "Apply common security configurations") {
                    VStack(spacing: AXSpacing.sm) {
                        quickActionRow(title: "Block Sensitive Files", description: "Block .env, .git, config files", icon: "eye.slash.fill", color: .purple) {
                            Task { await viewModel.toggleSensitiveFilesBlock(enable: true) }
                        }
                        quickActionRow(title: "Enable Hotlink Protection", description: "Prevent image hotlinking", icon: "link.badge.plus", color: .orange) {
                            Task { await viewModel.toggleHotlinkProtection(enable: true) }
                        }
                        quickActionRow(title: "Fix Permissions", description: "Set 755/644 and www-data ownership", icon: "checkmark.shield.fill", color: .axSuccess) {
                            Task { await viewModel.fixPermissions() }
                        }
                        quickActionRow(title: "Run Malware Scan", description: "Scan PHP files for suspicious code", icon: "magnifyingglass", color: .red) {
                            Task {
                                await viewModel.runMalwareScan()
                                showScanResults = true
                            }
                        }
                        quickActionRow(title: "Audit Permissions", description: "Find files with 777/666 permissions", icon: "doc.badge.gearshape", color: .axAccentBlue) {
                            Task {
                                await viewModel.runPermissionAudit()
                                showScanResults = true
                            }
                        }
                    }
                }

                // Scan Progress
                if viewModel.isScanning {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.8)
                        Text(viewModel.scanProgress)
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axAccentBlue.opacity(0.05))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Permission Audit Results
                if !viewModel.permissionResults.isEmpty {
                    ConfigCard(icon: "exclamationmark.shield.fill", title: "Permission Issues (\(viewModel.permissionResults.count))", description: "Files with insecure permissions") {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.permissionResults) { result in
                                HStack {
                                    Text(result.permissions)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(result.severity.color)
                                        .frame(width: 40)
                                    Text(result.path)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(result.owner)
                                        .font(.system(size: 10))
                                        .foregroundColor(.axTextTertiary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // Malware Results
                if !viewModel.malwareResults.isEmpty {
                    ConfigCard(icon: "exclamationmark.octagon.fill", title: "Suspicious Code (\(viewModel.malwareResults.count))", description: "Potentially malicious patterns found") {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(viewModel.malwareResults) { result in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(result.filePath.components(separatedBy: "/").last ?? "")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.axError)
                                        Spacer()
                                        Text("Line \(result.lineNumber)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.axTextTertiary)
                                    }
                                    Text(String(result.lineContent.prefix(120)))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.axTextSecondary)
                                        .lineLimit(2)
                                    Text("Pattern: \(result.matchedPattern)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.axWarning)
                                }
                                .padding(AXSpacing.sm)
                                .background(Color.axError.opacity(0.05))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadSecurityStatus() } }
    }

    // MARK: - Security Score

    private var securityScoreCard: some View {
        let enabled = viewModel.securityStatuses.filter { $0.enabled }.count
        let total = viewModel.securityStatuses.count
        let score = total > 0 ? Double(enabled) / Double(total) * 100 : 0

        return HStack(spacing: AXSpacing.xl) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Security Score")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
                Text("\(Int(score))%")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(score >= 70 ? .axSuccess : (score >= 40 ? .axWarning : .axError))
                Text("\(enabled) of \(total) protections active")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextTertiary)
            }
            Spacer()
            CircularProgressView(progress: score / 100, color: score >= 70 ? .axSuccess : (score >= 40 ? .axWarning : .axError))
                .frame(width: 80, height: 80)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
    }

    // MARK: - Feature Card

    private func securityFeatureCard(_ status: SiteSecurityStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: status.feature.icon)
                    .font(.system(size: 18))
                    .foregroundColor(status.feature.color)
                Spacer()
                Circle()
                    .fill(status.statusColor)
                    .frame(width: 8, height: 8)
            }
            Text(status.feature.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            Text(status.statusText)
                .font(.system(size: 11))
                .foregroundColor(status.statusColor)
            if !status.issues.isEmpty {
                Text(status.issues.first ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.axWarning)
                    .lineLimit(1)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
    }

    // MARK: - Quick Action Row

    private func quickActionRow(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
            .padding(AXSpacing.sm)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Circular Progress

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
    }
}
