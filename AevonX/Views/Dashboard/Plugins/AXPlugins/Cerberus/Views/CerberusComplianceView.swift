//
//  CerberusComplianceView.swift
//  AevonX
//
//  Compliance tab — PCI-DSS and security compliance report.
//  Enterprise-grade compliance dashboard with score hero, stats, and grouped checks.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusComplianceView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                if viewModel.complianceLoading && viewModel.complianceReport == nil {
                    skeletonContent
                } else if let report = viewModel.complianceReport {
                    heroCard(report)
                    summaryStatsRow(report)
                    checksSection(report)
                } else {
                    emptyState
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadComplianceReport() }
    }
}

// MARK: - Hero Card

private extension CerberusComplianceView {

    func heroCard(_ report: WAFComplianceReport) -> some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.xxl) {
                heroScoreRing(report.score)
                heroDetails(report)
                Spacer(minLength: 0)
                refreshButton
            }
            .padding(AXSpacing.xl)
        }
    }

    func heroScoreRing(_ score: Int) -> some View {
        AXCircularProgress(
            progress: Double(score) / 100.0,
            color: scoreColor(score),
            size: 88,
            lineWidth: 7
        ) {
            VStack(spacing: AXSpacing.xxxs) {
                Text(gradeLetter(score))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(score))
                Text("\(score)%")
                    .font(AXTypography.caption2)
                    .foregroundStyle(Color.axTextSecondary)
            }
        }
    }

    func heroDetails(_ report: WAFComplianceReport) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(report.framework)
                .font(AXTypography.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)

            Text(L10n.Cerberus.Compliance.complianceScore)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)

            heroPills(report)
        }
    }

    func heroPills(_ report: WAFComplianceReport) -> some View {
        HStack(spacing: AXSpacing.sm) {
            AXBadge(text: "\(report.passed) \(L10n.Cerberus.Compliance.passed)", color: .axAccentGreen, style: .soft)
            AXBadge(text: "\(report.failed) \(L10n.Cerberus.Compliance.failed)", color: .axError, style: .soft)
            AXBadge(text: "\(report.warnings) \(L10n.Cerberus.Compliance.warnings)", color: .axWarning, style: .soft)
        }
    }

    var refreshButton: some View {
        Button {
            Task { await viewModel.loadComplianceReport() }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(AXTypography.body)
                .foregroundStyle(Color.axAccentBlue)
                .frame(width: 32, height: 32)
                .background(Color.axAccentBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Stats Row

private extension CerberusComplianceView {

    func summaryStatsRow(_ report: WAFComplianceReport) -> some View {
        HStack(spacing: AXSpacing.md) {
            statCard(
                label: L10n.Cerberus.Compliance.passed,
                value: "\(report.passed)",
                icon: "checkmark.circle.fill",
                color: .axAccentGreen
            )
            statCard(
                label: L10n.Cerberus.Compliance.failed,
                value: "\(report.failed)",
                icon: "xmark.circle.fill",
                color: .axError
            )
            statCard(
                label: L10n.Cerberus.Compliance.warnings,
                value: "\(report.warnings)",
                icon: "exclamationmark.triangle.fill",
                color: .axWarning
            )
        }
    }

    func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.axTextPrimary)

                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.lg)
        }
    }
}

// MARK: - Checks List

private extension CerberusComplianceView {

    func checksSection(_ report: WAFComplianceReport) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionHeader(report)
            checksList(report)
        }
    }

    func sectionHeader(_ report: WAFComplianceReport) -> some View {
        HStack {
            Text(L10n.Cerberus.Compliance.checks)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            Text(L10n.Cerberus.Compliance.totalChecks(report.checks.count))
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    func checksList(_ report: WAFComplianceReport) -> some View {
        let sorted = sortedChecks(report.checks)
        return VStack(spacing: AXSpacing.sm) {
            ForEach(sorted) { check in
                checkRow(check)
            }
        }
    }

    func sortedChecks(_ checks: [WAFComplianceCheck]) -> [WAFComplianceCheck] {
        checks.sorted { lhs, rhs in
            if lhs.isPassed != rhs.isPassed { return !lhs.isPassed }
            return lhs.requirement < rhs.requirement
        }
    }

    func checkRow(_ check: WAFComplianceCheck) -> some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                checkIcon(check.isPassed)
                checkInfo(check)
                Spacer(minLength: 0)
                AXBadge(
                    text: check.category,
                    color: .axAccentPurple,
                    style: .soft
                )
            }
            .padding(AXSpacing.md)
        }
    }

    func checkIcon(_ passed: Bool) -> some View {
        Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 22))
            .foregroundStyle(passed ? Color.axAccentGreen : Color.axError)
    }

    func checkInfo(_ check: WAFComplianceCheck) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            Text(check.requirement)
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(1)
            Text(check.description)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
                .lineLimit(2)
        }
    }
}

// MARK: - Empty State

private extension CerberusComplianceView {

    var emptyState: some View {
        AXEmptyState(
            icon: "shield.checkered",
            title: L10n.Cerberus.Compliance.noReport,
            description: L10n.Cerberus.Compliance.noReportDesc,
            actionLabel: L10n.Cerberus.Compliance.generateReport
        ) {
            Task { await viewModel.loadComplianceReport() }
        }
        .padding(.top, AXSpacing.xxxxl)
    }
}

// MARK: - Skeleton Loading

private extension CerberusComplianceView {

    var skeletonContent: some View {
        VStack(spacing: AXSpacing.xl) {
            skeletonHero
            skeletonStats
            skeletonChecks
        }
    }

    var skeletonHero: some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.xxl) {
                Circle()
                    .fill(Color.axSurface)
                    .frame(width: 88, height: 88)
                    .shimmer()
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    AXSkeletonRow(width: 160, height: 18)
                    AXSkeletonRow(width: 100, height: 12)
                    HStack(spacing: AXSpacing.sm) {
                        AXSkeletonRow(width: 70, height: 20)
                        AXSkeletonRow(width: 70, height: 20)
                        AXSkeletonRow(width: 80, height: 20)
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }

    var skeletonStats: some View {
        HStack(spacing: AXSpacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                AXCard {
                    VStack(spacing: AXSpacing.sm) {
                        AXSkeletonRow(width: 24, height: 24, cornerRadius: AXCornerRadius.xl)
                        AXSkeletonRow(width: 32, height: 22)
                        AXSkeletonRow(width: 50, height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.lg)
                }
            }
        }
    }

    var skeletonChecks: some View {
        VStack(spacing: AXSpacing.sm) {
            ForEach(0..<5, id: \.self) { _ in
                AXCard {
                    HStack(spacing: AXSpacing.md) {
                        AXSkeletonRow(width: 22, height: 22, cornerRadius: AXCornerRadius.xl)
                        AXSkeletonBlock(lines: 2, height: 13)
                        Spacer()
                        AXSkeletonRow(width: 60, height: 20)
                    }
                    .padding(AXSpacing.md)
                }
            }
        }
    }
}

// MARK: - Helpers

private extension CerberusComplianceView {

    func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .axAccentGreen }
        if score >= 60 { return .axWarning }
        return .axError
    }

    func gradeLetter(_ score: Int) -> String {
        if score >= 90 { return "A" }
        if score >= 80 { return "B" }
        if score >= 70 { return "C" }
        if score >= 60 { return "D" }
        return "F"
    }
}
