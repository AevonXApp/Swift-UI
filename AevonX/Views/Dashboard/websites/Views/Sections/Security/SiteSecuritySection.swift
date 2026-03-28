//
//  SiteSecuritySection.swift
//  AevonX
//
//  Per-site security management section
//

import SwiftUI
import AevonXCoreBridge

struct SiteSecuritySection: View {
    @ObservedObject var viewModel: SiteSecurityViewModel
    @State private var selectedFeature: SiteSecurityFeature?
    @State private var showScanResults = false

    private var hotlinkEnabled: Bool {
        viewModel.securityStatuses.first { $0.feature == .hotlinkProtection }?.enabled ?? false
    }

    private var sensitiveFilesEnabled: Bool {
        viewModel.securityStatuses.first { $0.feature == .sensitiveFiles }?.enabled ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Site Security", icon: "shield.lefthalf.filled")

                // Security Score
                securityScoreCard

                // Feature Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    ForEach(viewModel.securityStatuses) { status in
                        securityFeatureCard(status)
                    }
                }

                // Quick Actions
                AXConfigCard(icon: "bolt.shield.fill", title: "Quick Actions", subtitle: "Apply common security configurations") {
                    VStack(spacing: AXSpacing.sm) {
                        quickActionRow(title: sensitiveFilesEnabled ? "Disable Sensitive Files Block" : "Block Sensitive Files", description: "Block .env, .git, config files", icon: "eye.slash.fill", color: .purple) {
                            Task { await viewModel.toggleSensitiveFilesBlock(enable: !sensitiveFilesEnabled) }
                        }
                        quickActionRow(title: hotlinkEnabled ? "Disable Hotlink Protection" : "Enable Hotlink Protection", description: "Prevent image hotlinking", icon: "link.badge.plus", color: .orange) {
                            Task { await viewModel.toggleHotlinkProtection(enable: !hotlinkEnabled) }
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
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axAccentBlue.opacity(0.05))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Permission Audit Results
                if !viewModel.permissionResults.isEmpty {
                    AXConfigCard(icon: "exclamationmark.shield.fill", title: "Permission Issues (\(viewModel.permissionResults.count))", subtitle: "Files with insecure permissions") {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.permissionResults) { result in
                                HStack {
                                    Text(result.permissions)
                                        .font(AXTypography.monoMd).fontWeight(.bold)
                                        .foregroundColor(result.severity.color)
                                        .frame(width: 40)
                                    Text(result.path)
                                        .font(AXTypography.monoSm)
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(result.owner)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextTertiary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // Malware Results
                if !viewModel.malwareResults.isEmpty {
                    AXConfigCard(icon: "exclamationmark.octagon.fill", title: "Suspicious Code (\(viewModel.malwareResults.count))", subtitle: "Potentially malicious patterns found") {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(viewModel.malwareResults) { result in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(result.filePath.components(separatedBy: "/").last ?? "")
                                            .font(AXTypography.subheadline).fontWeight(.semibold)
                                            .foregroundColor(.axError)
                                        Spacer()
                                        Text("Line \(result.lineNumber)")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextTertiary)
                                    }
                                    Text(String(result.lineContent.prefix(120)))
                                        .font(AXTypography.monoXs)
                                        .foregroundColor(.axTextSecondary)
                                        .lineLimit(2)
                                    Text("Pattern: \(result.matchedPattern)")
                                        .font(AXTypography.caption2)
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
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                Text("\(Int(score))%")
                    .font(AXTypography.largeTitle).fontWeight(.bold)
                    .foregroundColor(score >= 70 ? .axSuccess : (score >= 40 ? .axWarning : .axError))
                Text("\(enabled) of \(total) protections active")
                    .font(AXTypography.footnote)
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
                    .font(AXTypography.title2)
                    .foregroundColor(status.feature.color)
                Spacer()
                Circle()
                    .fill(status.statusColor)
                    .frame(width: 8, height: 8)
            }
            Text(status.feature.rawValue)
                .font(AXTypography.callout).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
            Text(status.statusText)
                .font(AXTypography.footnote)
                .foregroundColor(status.statusColor)
            if !status.issues.isEmpty {
                Text(status.issues.first ?? "")
                    .font(AXTypography.caption)
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
                    .font(AXTypography.body)
                    .foregroundColor(color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AXTypography.callout).fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)
                    Text(description)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(AXTypography.caption)
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
                .font(AXTypography.title2).fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}
