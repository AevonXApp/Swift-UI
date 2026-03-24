//
//  CerberusTrafficView.swift
//  AevonX
//
//  Traffic tab — domains, response times, status codes, bot analysis.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusTrafficView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.isLoading && viewModel.domainStats.isEmpty {
                    skeletonContent
                } else {
                    trafficSummaryRow
                    HStack(alignment: .top, spacing: AXSpacing.lg) {
                        responseTimesCard
                        botAnalysisCard
                    }
                    statusCodesCard
                    domainsList
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadTrafficAnalytics() }
    }

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                AXCard { AXSkeletonBlock(lines: 4) }
                AXCard { AXSkeletonBlock(lines: 4) }
            }
        }
    }

    // MARK: - Summary Row

    private var trafficSummaryRow: some View {
        HStack(spacing: AXSpacing.md) {
            trafficSummaryStat(icon: "globe", value: "\(sortedDomains.count)", label: "Domains", color: .axAccentBlue)
            trafficSummaryStat(icon: "arrow.up.arrow.down", value: viewModel.formatNumber(totalReqs), label: "Requests", color: .axAccentGreen)
            trafficSummaryStat(icon: "clock", value: latencyLabel, label: "P95 Latency", color: .axWarning)
            trafficSummaryStat(icon: "cpu", value: botRateLabel, label: "Bot Traffic", color: .axAccentPurple)
        }
    }

    private func trafficSummaryStat(icon: String, value: String, label: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(color.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(AXTypography.caption)
                            .foregroundStyle(color)
                    }
                    Spacer()
                }
                Text(value)
                    .font(AXTypography.title2)
                    .foregroundStyle(Color.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    // MARK: - Response Times Card

    private var responseTimesCard: some View {
        AXCard(accentColor: .axWarning) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.axWarning)
                    Text("Response Latency")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if let rt = viewModel.responseTimes {
                        AXBadge(text: "\(rt.samples) samples", color: .axWarning, style: .soft)
                    }
                }
                if let rt = viewModel.responseTimes, rt.samples > 0 {
                    latencyBars(rt)
                } else {
                    emptyBox(icon: "clock", text: "No latency data")
                }
            }
        }
    }

    private func latencyBars(_ rt: WAFResponseTimes) -> some View {
        let maxVal = max(rt.max, 1)
        return VStack(spacing: AXSpacing.sm) {
            latencyRow(label: "P50", value: rt.p50, max: maxVal, color: .axAccentGreen)
            latencyRow(label: "P95", value: rt.p95, max: maxVal, color: .axWarning)
            latencyRow(label: "P99", value: rt.p99, max: maxVal, color: .axError)
            latencyRow(label: "Avg", value: rt.avg, max: maxVal, color: .axAccentBlue)
            latencyRow(label: "Max", value: rt.max, max: maxVal, color: .axError)
        }
    }

    private func latencyRow(label: String, value: Double, max: Double, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(label)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 30, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(color.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(value / max), height: 8)
                }
            }
            .frame(height: 8)
            Text(String(format: "%.0fms", value))
                .font(AXTypography.monoXs)
                .foregroundStyle(color)
                .frame(width: 52, alignment: .trailing)
        }
    }

    // MARK: - Bot Analysis Card

    private var botAnalysisCard: some View {
        AXCard(accentColor: .axAccentPurple) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(Color.axAccentPurple)
                    Text("Bot Analysis")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                }
                if let bd = viewModel.botDetails, (bd.totalBot + bd.totalHuman) > 0 {
                    botAnalysisContent(bd)
                } else {
                    emptyBox(icon: "cpu", text: "No classification data")
                }
            }
        }
    }

    private func botAnalysisContent(_ bd: WAFBotDetails) -> some View {
        VStack(spacing: AXSpacing.md) {
            AXCircularProgress(
                progress: min(bd.botRate / 100, 1.0),
                color: bd.botRate > 50 ? .axError : bd.botRate > 20 ? .axWarning : .axAccentGreen,
                size: 80,
                lineWidth: 7
            ) {
                Text(String(format: "%.0f%%", bd.botRate))
                    .font(AXTypography.monoMd)
                    .foregroundStyle(Color.axTextPrimary)
            }
            HStack(spacing: AXSpacing.xl) {
                botStatCol(icon: "person.fill", label: "Human", value: viewModel.formatNumber(bd.totalHuman), color: .axAccentGreen)
                botStatCol(icon: "cpu", label: "Bot", value: viewModel.formatNumber(bd.totalBot), color: .axAccentPurple)
            }
        }
    }

    private func botStatCol(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            Image(systemName: icon)
                .font(AXTypography.caption)
                .foregroundStyle(color)
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    // MARK: - Status Codes Card

    private var statusCodesCard: some View {
        AXCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(Color.axAccentBlue)
                    Text("HTTP Status Codes")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if !viewModel.statusCodes.isEmpty {
                        AXBadge(text: "\(viewModel.statusCodes.count) codes", color: .axAccentBlue, style: .soft)
                    }
                }
                if viewModel.statusCodes.isEmpty {
                    emptyBox(icon: "number", text: "No status code data")
                } else {
                    statusCodeBars
                }
            }
        }
    }

    private var statusCodeBars: some View {
        let maxCount = viewModel.statusCodes.map(\.count).max() ?? 1
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.xs) {
            ForEach(viewModel.statusCodes.prefix(12)) { sc in
                statusCodeRow(sc, maxCount: maxCount)
            }
        }
    }

    private func statusCodeRow(_ sc: WAFStatusCode, maxCount: Int) -> some View {
        let color = statusCodeColor(sc.code)
        let ratio = maxCount > 0 ? Double(sc.count) / Double(maxCount) : 0
        return HStack(spacing: AXSpacing.sm) {
            AXBadge(text: "\(sc.code)", color: color, style: .soft)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(color.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(color.opacity(0.7))
                        .frame(width: geo.size.width * ratio, height: 6)
                }
            }
            .frame(height: 6)
            Text(viewModel.formatNumber(sc.count))
                .font(AXTypography.monoXs)
                .foregroundStyle(color)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, AXSpacing.xxs)
    }

    // MARK: - Domains List

    private var domainsList: some View {
        VStack(spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(Color.axAccentBlue)
                Text("Domains")
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
                AXBadge(text: "\(sortedDomains.count)", color: .axAccentBlue, style: .soft)
                Spacer()
            }
            if sortedDomains.isEmpty {
                emptyBox(icon: "globe.slash", text: "No domain traffic yet")
            } else {
                ForEach(Array(sortedDomains.enumerated()), id: \.element.domain) { idx, item in
                    domainCard(rank: idx + 1, domain: item.domain, stats: item.stats)
                }
            }
        }
    }

    private func domainCard(rank: Int, domain: String, stats: DomainStats) -> some View {
        let blockedRate = stats.totalRequests > 0 ? Double(stats.blockedRequests) / Double(stats.totalRequests) : 0
        let protRate = 1.0 - blockedRate
        let accent: Color = blockedRate > 0.3 ? .axError : blockedRate > 0.1 ? .axWarning : .axAccentGreen
        return AXCard(accentColor: accent) {
            HStack(spacing: AXSpacing.lg) {
                VStack(spacing: AXSpacing.xs) {
                    AXCircularProgress(progress: protRate, color: accent, size: 52, lineWidth: 5) {
                        Text(String(format: "%.0f%%", protRate * 100))
                            .font(AXTypography.monoXs)
                            .foregroundStyle(accent)
                    }
                    Text("#\(rank)")
                        .font(AXTypography.monoXs)
                        .foregroundStyle(Color.axTextMuted)
                }
                .frame(width: 60)
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Text(domain)
                            .font(AXTypography.monoMd)
                            .foregroundStyle(Color.axTextPrimary)
                            .lineLimit(1)
                        Spacer()
                        AXBadge(text: viewModel.formatNumber(stats.totalRequests) + " req", color: .axAccentBlue, style: .soft)
                    }
                    domainProgressBar(blockedRate: blockedRate)
                    domainStatChips(stats: stats)
                }
            }
        }
    }

    private func domainProgressBar(blockedRate: Double) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs).fill(Color.axAccentGreen.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(LinearGradient(colors: [Color.axError, Color.axError.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
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
            statChip("Blocked", viewModel.formatNumber(stats.blockedRequests), .axError)
            statChip("Allowed", viewModel.formatNumber(stats.totalRequests - stats.blockedRequests), .axAccentGreen)
            statChip("In", viewModel.formatBytes(stats.bytesIn), .axAccentBlue)
            statChip("Out", viewModel.formatBytes(stats.bytesOut), .axAccentPurple)
            Spacer()
        }
    }

    private func statChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(value).font(AXTypography.monoSm).foregroundStyle(color)
            Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
        }
    }

    // MARK: - Helpers

    private var sortedDomains: [(domain: String, stats: DomainStats)] {
        viewModel.domainStats.map { (domain: $0.key, stats: $0.value) }
            .sorted { $0.stats.totalRequests > $1.stats.totalRequests }
    }

    private var totalReqs: Int { sortedDomains.reduce(0) { $0 + $1.stats.totalRequests } }

    private var latencyLabel: String {
        guard let rt = viewModel.responseTimes, rt.samples > 0 else { return "—" }
        return String(format: "%.0fms", rt.p95)
    }

    private var botRateLabel: String {
        guard let bd = viewModel.botDetails else { return "—" }
        return String(format: "%.1f%%", bd.botRate)
    }

    private func statusCodeColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .axAccentGreen
        case 300..<400: return .axAccentBlue
        case 400..<500: return .axWarning
        case 500..<600: return .axError
        default: return .axTextMuted
        }
    }

    private func emptyBox(icon: String, text: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon).font(AXTypography.title2).foregroundStyle(Color.axTextMuted)
                Text(text).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }
            .padding(.vertical, AXSpacing.xl)
            Spacer()
        }
    }
}
