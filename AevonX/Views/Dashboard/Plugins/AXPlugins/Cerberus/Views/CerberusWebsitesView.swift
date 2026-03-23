//
//  CerberusWebsitesView.swift
//  AevonX
//
//  Websites tab — per-domain traffic analytics with protection rate rings.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusWebsitesView: View {
    @ObservedObject var viewModel: CerberusViewModel

    private var sortedDomains: [(domain: String, stats: DomainStats)] {
        viewModel.domainStats
            .map { (domain: $0.key, stats: $0.value) }
            .sorted { $0.stats.totalRequests > $1.stats.totalRequests }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.isLoading && viewModel.domainStats.isEmpty {
                    skeletonContent
                } else if sortedDomains.isEmpty {
                    emptyState
                } else {
                    summaryGlassCard
                    domainList
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadDomainStats() }
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            AXCard { AXSkeletonBlock(lines: 2) }
            ForEach(0..<4, id: \.self) { _ in
                AXCard { AXSkeletonBlock(lines: 3) }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            Image(systemName: "globe.slash")
                .font(AXTypography.largeTitle)
                .foregroundStyle(Color.axTextMuted)
            Text("No website traffic yet")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextSecondary)
            Text("Traffic data appears once requests pass through the WAF.")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AXSpacing.xxxxl)
    }

    // MARK: - Summary Glass Card

    private var summaryGlassCard: some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.xxxl) {
                summaryGlassStat(
                    icon: "globe",
                    value: "\(sortedDomains.count)",
                    label: "Websites",
                    color: .axAccentBlue
                )
                Divider().frame(height: 40)
                summaryGlassStat(
                    icon: "arrow.up.arrow.down",
                    value: viewModel.formatNumber(sortedDomains.reduce(0) { $0 + $1.stats.totalRequests }),
                    label: "Total Requests",
                    color: .axAccentGreen
                )
                Divider().frame(height: 40)
                summaryGlassStat(
                    icon: "hand.raised.fill",
                    value: viewModel.formatNumber(sortedDomains.reduce(0) { $0 + $1.stats.blockedRequests }),
                    label: "Total Blocked",
                    color: .axError
                )
                Divider().frame(height: 40)
                summaryGlassStat(
                    icon: "arrow.down.circle",
                    value: viewModel.formatBytes(sortedDomains.reduce(0) { $0 + $1.stats.bytesIn }),
                    label: "Bandwidth In",
                    color: .axAccentPurple
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func summaryGlassStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(AXTypography.headline)
                .foregroundStyle(color)
            Text(value)
                .font(AXTypography.title3)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Domain List

    private var domainList: some View {
        VStack(spacing: AXSpacing.sm) {
            ForEach(Array(sortedDomains.enumerated()), id: \.element.domain) { idx, item in
                domainCard(rank: idx + 1, domain: item.domain, stats: item.stats)
            }
        }
    }

    private func domainCard(rank: Int, domain: String, stats: DomainStats) -> some View {
        let blockedRate = stats.totalRequests > 0
            ? Double(stats.blockedRequests) / Double(stats.totalRequests)
            : 0.0
        let protectionRate = 1.0 - blockedRate
        let accentColor: Color = blockedRate > 0.3 ? .axError : blockedRate > 0.1 ? .axWarning : .axAccentGreen

        return AXCard(accentColor: accentColor) {
            HStack(spacing: AXSpacing.lg) {
                domainRingColumn(rank: rank, protectionRate: protectionRate, accentColor: accentColor)
                domainInfoColumn(domain: domain, stats: stats, blockedRate: blockedRate, accentColor: accentColor)
            }
        }
    }

    private func domainRingColumn(rank: Int, protectionRate: Double, accentColor: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            AXCircularProgress(
                progress: protectionRate,
                color: accentColor,
                size: 56,
                lineWidth: 5
            ) {
                Text(String(format: "%.0f%%", protectionRate * 100))
                    .font(AXTypography.monoXs)
                    .foregroundStyle(accentColor)
            }
            Text("#\(rank)")
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(width: 64)
    }

    private func domainInfoColumn(domain: String, stats: DomainStats, blockedRate: Double, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            domainInfoHeader(domain: domain, stats: stats)
            domainProgressBar(blockedRate: blockedRate)
            domainStatChips(stats: stats)
        }
    }

    private func domainInfoHeader(domain: String, stats: DomainStats) -> some View {
        HStack {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "globe")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axAccentBlue)
                Text(domain)
                    .font(AXTypography.monoMd)
                    .foregroundStyle(Color.axTextPrimary)
                    .lineLimit(1)
            }
            Spacer()
            AXBadge(
                text: viewModel.formatNumber(stats.totalRequests) + " req",
                color: .axAccentBlue,
                style: .soft
            )
        }
    }

    private func domainProgressBar(blockedRate: Double) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(Color.axAccentGreen.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: [Color.axError, Color.axError.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * blockedRate, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text(String(format: "%.1f%% blocked", blockedRate * 100))
                    .font(AXTypography.caption)
                    .foregroundStyle(blockedRate > 0.1 ? Color.axError : Color.axTextMuted)
                Spacer()
                Text(String(format: "%.1f%% allowed", (1 - blockedRate) * 100))
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axAccentGreen)
            }
        }
    }

    private func domainStatChips(stats: DomainStats) -> some View {
        HStack(spacing: AXSpacing.md) {
            domainChip(label: "Blocked", value: viewModel.formatNumber(stats.blockedRequests), color: .axError)
            domainChip(label: "Allowed", value: viewModel.formatNumber(stats.totalRequests - stats.blockedRequests), color: .axAccentGreen)
            domainChip(label: "In", value: viewModel.formatBytes(stats.bytesIn), color: .axAccentBlue)
            domainChip(label: "Out", value: viewModel.formatBytes(stats.bytesOut), color: .axAccentPurple)
            Spacer()
        }
    }

    private func domainChip(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }
}
