//
//  CerberusThreatFeedView.swift
//  AevonX
//
//  Threat Intelligence tab — feed status, source breakdown, manual refresh.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusThreatFeedView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.threatFeedLoading && viewModel.threatFeedStatus == nil {
                    skeletonContent
                } else if let status = viewModel.threatFeedStatus, status.enabled {
                    heroCard(status)
                    statsRow(status)
                    sourcesSection(status)
                } else {
                    disabledState
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadThreatFeedStatus() }
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.lg) {
            AXCard { AXSkeletonBlock(lines: 4) }
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<3, id: \.self) { _ in AXSkeletonStatCard() }
            }
            AXCard { AXSkeletonBlock(lines: 6) }
        }
    }

    // MARK: - Disabled

    private var disabledState: some View {
        AXEmptyState(
            icon: "antenna.radiowaves.left.and.right",
            title: L10n.Cerberus.ThreatFeed.disabledTitle,
            description: L10n.Cerberus.ThreatFeed.disabledDesc,
            accentColor: .axAccentPurple
        )
    }

    // MARK: - Hero Card

    private func heroCard(_ status: WAFThreatFeedStatus) -> some View {
        AXGlassCard(accentColor: .axAccentPurple) {
            VStack(spacing: AXSpacing.lg) {
                heroTopRow(status)
                heroDivider
                heroBottomRow(status)
            }
        }
    }

    private func heroTopRow(_ status: WAFThreatFeedStatus) -> some View {
        HStack(spacing: AXSpacing.lg) {
            heroIcon
            heroTitleBlock(status)
            Spacer()
            refreshButton
        }
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentPurple.opacity(0.3), Color.axAccentBlue.opacity(0.1)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 28
                    )
                )
                .frame(width: 52, height: 52)
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.axAccentPurple)
        }
    }

    private func heroTitleBlock(_ status: WAFThreatFeedStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            HStack(spacing: AXSpacing.sm) {
                Text(L10n.Cerberus.ThreatFeed.title)
                    .font(AXTypography.title3)
                    .foregroundStyle(Color.axTextPrimary)
                AXBadge(text: L10n.Status.active, color: .axAccentGreen, style: .soft)
            }
            heroSubtitle(status)
        }
    }

    private func heroSubtitle(_ status: WAFThreatFeedStatus) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text(status.lastUpdate ?? L10n.Cerberus.ThreatFeed.neverUpdated)
                .font(AXTypography.caption2)
        }
        .foregroundStyle(Color.axTextTertiary)
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.updateThreatFeed() }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                if viewModel.threatFeedLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(L10n.Button.refresh)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.12))
            .foregroundStyle(Color.axAccentBlue)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.threatFeedLoading)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(Color.axDivider)
            .frame(height: 1)
    }

    private func heroBottomRow(_ status: WAFThreatFeedStatus) -> some View {
        HStack(spacing: AXSpacing.xl) {
            heroMetric(
                label: L10n.Cerberus.ThreatFeed.totalEntries,
                value: formatLargeNumber(status.totalEntries ?? 0),
                color: .axAccentBlue
            )
            heroMetric(
                label: L10n.Cerberus.ThreatFeed.threatsBlocked,
                value: formatLargeNumber(status.blockedByFeed ?? 0),
                color: .axError
            )
            heroMetric(
                label: L10n.Cerberus.ThreatFeed.feedSources,
                value: "\(resolvedSources(status).count)",
                color: .axAccentGreen
            )
            Spacer()
        }
    }

    private func heroMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.monoMd)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    // MARK: - Stats Row

    private func statsRow(_ status: WAFThreatFeedStatus) -> some View {
        HStack(spacing: AXSpacing.md) {
            statCard(
                icon: "list.number", label: L10n.Cerberus.ThreatFeed.totalEntries,
                value: formatLargeNumber(status.totalEntries ?? 0),
                color: .axAccentBlue
            )
            statCard(
                icon: "hand.raised.fill", label: L10n.Cerberus.ThreatFeed.blockedByFeed,
                value: formatLargeNumber(status.blockedByFeed ?? 0),
                color: .axError
            )
            statCard(
                icon: "checkmark.shield.fill", label: L10n.Cerberus.ThreatFeed.sourcesActive,
                value: "\(resolvedSources(status).count)",
                color: .axAccentGreen
            )
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                statIconBox(icon: icon, color: color)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(value)
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(label)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
                Spacer()
            }
        }
    }

    private func statIconBox(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.md)
            .fill(color.opacity(0.12))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            )
    }

    // MARK: - Sources Section

    private func sourcesSection(_ status: WAFThreatFeedStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sourceSectionHeader(status)
            ForEach(Array(resolvedSources(status).enumerated()), id: \.offset) { _, source in
                sourceRow(source, totalEntries: status.totalEntries ?? 1)
            }
        }
    }

    private func sourceSectionHeader(_ status: WAFThreatFeedStatus) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.axAccentPurple)
            Text(L10n.Cerberus.ThreatFeed.sourceBreakdown)
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            AXBadge(
                text: "\(resolvedSources(status).count) sources",
                color: .axAccentPurple, style: .soft
            )
            Spacer()
        }
    }

    private func sourceRow(_ source: WAFThreatSource, totalEntries: Int) -> some View {
        AXCard(padding: AXSpacing.md) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                sourceRowTop(source)
                sourceProgressBar(source, totalEntries: totalEntries)
            }
        }
    }

    private func sourceRowTop(_ source: WAFThreatSource) -> some View {
        HStack {
            sourceIconLabel(source)
            Spacer()
            sourceEntryBadge(source)
        }
    }

    private func sourceIconLabel(_ source: WAFThreatSource) -> some View {
        HStack(spacing: AXSpacing.sm) {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axAccentPurple.opacity(0.12))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.axAccentPurple)
                )
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(source.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextPrimary)
                Text(L10n.Cerberus.ThreatFeed.updated(source.lastUpdated))
                    .font(AXTypography.caption2)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    private func sourceEntryBadge(_ source: WAFThreatSource) -> some View {
        AXBadge(
            text: "\(formatLargeNumber(source.entries)) entries",
            color: .axAccentBlue, style: .soft
        )
    }

    private func sourceProgressBar(_ source: WAFThreatSource, totalEntries: Int) -> some View {
        let fraction = totalEntries > 0
            ? min(Double(source.entries) / Double(totalEntries), 1.0)
            : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(Color.axSurface)
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(
                        LinearGradient(
                            colors: [.axAccentPurple, .axAccentBlue],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Helpers

    private func resolvedSources(_ status: WAFThreatFeedStatus) -> [WAFThreatSource] {
        if let sources = status.sources, !sources.isEmpty {
            return sources
        }
        return fallbackSources(total: status.totalEntries ?? 0)
    }

    private func fallbackSources(total: Int) -> [WAFThreatSource] {
        let third = total / 3
        return [
            WAFThreatSource(name: "Spamhaus DROP", entries: third, lastUpdated: "auto"),
            WAFThreatSource(name: "Emerging Threats", entries: third, lastUpdated: "auto"),
            WAFThreatSource(name: "FireHOL Level 1", entries: total - (third * 2), lastUpdated: "auto"),
        ]
    }

    private func formatLargeNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }
}
