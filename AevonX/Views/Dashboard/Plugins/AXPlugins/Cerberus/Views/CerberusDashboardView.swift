//
//  CerberusDashboardView.swift
//  AevonX
//
//  Dashboard tab — AXCerberus WAF command center.
//  Threat hero card · live metrics · 24h timeline · attack origins · DDoS shield.
//

import SwiftUI
import Charts
import AevonXCoreBridge

struct CerberusDashboardView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.isLoading && viewModel.overview == nil {
                    skeletonContent
                } else {
                    errorBanner
                    threatHeroCard
                    primaryStatsGrid
                    middleRow
                    secondaryRow
                    ddosCard
                    quickStatsCard
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadDashboard() }
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.lg) {
            AXCard { AXSkeletonBlock(lines: 3) }
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
            HStack(alignment: .top, spacing: AXSpacing.md) {
                AXCard { AXSkeletonBlock(lines: 8) }
                AXCard { AXSkeletonBlock(lines: 6) }.frame(width: 260)
            }
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.axWarning)
                Text(error)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextSecondary)
                    .lineLimit(2)
                Spacer()
                Button("Retry") { Task { await viewModel.loadDashboard() } }
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axAccentBlue)
                    .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axWarning.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axWarning.opacity(0.25), lineWidth: 1))
            )
        }
    }

    // MARK: - Threat Hero

    private var threatHeroCard: some View {
        AXGlassCard(padding: AXSpacing.xl, accentColor: threatColor) {
            HStack(spacing: AXSpacing.xxl) {
                threatStatusLeft
                Spacer()
                protectionRingCenter
                Spacer()
                heroMetricsRight
            }
        }
    }

    private var threatStatusLeft: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(threatColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: threatIcon)
                        .font(AXTypography.title3)
                        .foregroundStyle(threatColor)
                }
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(threatLabel)
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text("AXCerberus · Layer 7 WAF")
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                }
            }
            AXStatusBadge(
                status: (viewModel.serviceStatus?.isActive ?? false) ? .online : .offline,
                showLabel: true,
                enablePulseAnimation: viewModel.serviceStatus?.isActive ?? false
            )
        }
    }

    private var protectionRingCenter: some View {
        VStack(spacing: AXSpacing.sm) {
            AXCircularProgress(
                value: (viewModel.overview?.protectionRate ?? 0) / 100,
                size: 72,
                lineWidth: 6,
                color: threatColor,
                showValue: false
            )
            .overlay(
                VStack(spacing: 0) {
                    Text(String(format: "%.1f%%", viewModel.overview?.protectionRate ?? 0))
                        .font(AXTypography.monoSm)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text("blocked")
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
            )
            Text("Protection Rate")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextSecondary)
        }
    }

    private var heroMetricsRight: some View {
        VStack(alignment: .trailing, spacing: AXSpacing.lg) {
            heroMetric(label: "Total Requests", value: viewModel.formatNumber(viewModel.overview?.totalRequests ?? 0))
            heroMetric(label: "Requests / sec", value: String(format: "%.1f", viewModel.overview?.qps ?? 0))
            heroMetric(label: "Uptime", value: viewModel.formatUptime(viewModel.overview?.uptimeSeconds ?? 0))
        }
    }

    private func heroMetric(label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Primary Stats Grid

    private var primaryStatsGrid: some View {
        HStack(spacing: AXSpacing.md) {
            statCard(title: "Total Requests",
                     value: viewModel.formatNumber(viewModel.overview?.totalRequests ?? 0),
                     icon: "arrow.up.arrow.down", color: .axAccentBlue)
            statCard(title: "Blocked",
                     value: viewModel.formatNumber(viewModel.overview?.blockedRequests ?? 0),
                     icon: "hand.raised.fill", color: .axError)
            statCard(title: "Allowed",
                     value: viewModel.formatNumber(viewModel.overview?.allowedRequests ?? 0),
                     icon: "checkmark.shield.fill", color: .axAccentGreen)
            statCard(title: "QPS",
                     value: String(format: "%.1f", viewModel.overview?.qps ?? 0),
                     icon: "gauge.with.dots.needle.33percent", color: .axAccentPurple)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(color.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: icon)
                            .font(AXTypography.caption)
                            .foregroundStyle(color)
                    }
                    Spacer()
                }
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextSecondary)
            }
        }
    }

    // MARK: - Middle Row (Timeline + Countries)

    private var middleRow: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            timelineCard
            topCountriesCard.frame(width: 260)
        }
    }

    private var timelineCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionHeader(title: "24-Hour Traffic", subtitle: "Request volume by hour")
                timelineChartArea
                HStack(spacing: AXSpacing.lg) {
                    chartLegend(color: .axAccentGreen, label: "Allowed")
                    chartLegend(color: .axError, label: "Blocked")
                }
            }
        }
    }

    private var timelineChartArea: some View {
        Group {
            if viewModel.timeline.isEmpty || viewModel.timeline.allSatisfy({ $0.total == 0 }) {
                emptyChartPlaceholder
            } else {
                timelineChartContent
            }
        }
    }

    private var timelineChartContent: some View {
        Chart {
            ForEach(viewModel.timeline) { entry in
                BarMark(x: .value("Hour", "\(entry.hour):00"), y: .value("Allowed", entry.allowed))
                    .foregroundStyle(Color.axAccentGreen.opacity(0.75))
                    .cornerRadius(AXCornerRadius.xs)
                BarMark(x: .value("Hour", "\(entry.hour):00"), y: .value("Blocked", entry.blocked))
                    .foregroundStyle(Color.axError.opacity(0.8))
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 4)) {
                AxisGridLine().foregroundStyle(Color.axDivider.opacity(0.4))
                AxisValueLabel().foregroundStyle(Color.axTextTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(Color.axDivider.opacity(0.4))
                AxisValueLabel().foregroundStyle(Color.axTextTertiary)
            }
        }
        .frame(height: 180)
    }

    private func chartLegend(color: Color, label: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                .fill(color)
                .frame(width: 12, height: 4)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextSecondary)
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "chart.bar")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axTextMuted)
            Text("No timeline data")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    // MARK: - Top Countries Panel

    private var topCountriesCard: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionHeader(title: "Attack Origins", subtitle: "Top countries today")
                if viewModel.countries.isEmpty {
                    Spacer()
                    AXEmptyState(icon: "globe", title: "No Data", description: "No attack origins recorded yet.")
                    Spacer()
                } else {
                    countriesListMini
                }
            }
        }
    }

    private var countriesListMini: some View {
        let maxCount = viewModel.countries.first?.count ?? 1
        return VStack(spacing: AXSpacing.sm) {
            ForEach(Array(viewModel.countries.prefix(6).enumerated()), id: \.element.id) { idx, country in
                dashboardCountryRow(country, maxCount: maxCount, rank: idx + 1)
            }
        }
    }

    private func dashboardCountryRow(_ country: CountryStats, maxCount: Int, rank: Int) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Text("\(rank)")
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 14, alignment: .trailing)
            Text(flagEmoji(for: country.countryCode))
                .font(AXTypography.caption)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack {
                    Text(country.countryName.isEmpty ? country.countryCode : country.countryName)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.formatNumber(country.count))
                        .font(AXTypography.monoXs)
                        .foregroundStyle(Color.axError)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(Color.axError.opacity(0.1))
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(Color.axError.opacity(0.65))
                            .frame(width: geo.size.width * (Double(country.count) / Double(max(maxCount, 1))))
                    }
                    .frame(height: 3)
                }
                .frame(height: 3)
            }
        }
    }

    // MARK: - Secondary Row

    private var secondaryRow: some View {
        HStack(spacing: AXSpacing.md) {
            AXCard { AXMiniStat(label: "Bytes In", value: viewModel.formatBytes(viewModel.overview?.bytesIn ?? 0), icon: "arrow.down.circle.fill", color: .axAccentBlue) }
            AXCard { AXMiniStat(label: "Bytes Out", value: viewModel.formatBytes(viewModel.overview?.bytesOut ?? 0), icon: "arrow.up.circle.fill", color: .axAccentGreen) }
            AXCard { AXMiniStat(label: "Bot Requests", value: viewModel.formatNumber(viewModel.overview?.botRequests ?? 0), icon: "cpu.fill", color: .axWarning) }
            AXCard { AXMiniStat(label: "Uptime", value: viewModel.formatUptime(viewModel.overview?.uptimeSeconds ?? 0), icon: "clock.fill", color: .axAccentPurple) }
        }
    }

    // MARK: - DDoS Shield Card

    private var ddosCard: some View {
        AXGlassCard(accentColor: ddosColor) {
            HStack(spacing: AXSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(ddosColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "bolt.shield.fill")
                        .font(AXTypography.title3)
                        .foregroundStyle(ddosColor)
                }
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.sm) {
                        Text("DDoS Shield")
                            .font(AXTypography.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.axTextPrimary)
                        AXBadge(text: "Level \(viewModel.ddosStatus?.level ?? 0): \(viewModel.ddosStatus?.levelName ?? "None")", color: ddosColor, style: .soft)
                        if viewModel.ddosStatus?.underAttack == true {
                            AXBadge(text: "UNDER ATTACK", color: .axError, style: .soft)
                        }
                    }
                    HStack(spacing: AXSpacing.xxl) {
                        ddosMetric(label: "Current QPS", value: String(format: "%.1f", viewModel.ddosStatus?.currentQps ?? 0))
                        ddosMetric(label: "Baseline QPS", value: String(format: "%.1f", viewModel.ddosStatus?.baselineQps ?? 0))
                    }
                }
                Spacer()
                AXCircularProgress(value: min(Double(viewModel.ddosStatus?.level ?? 0) / 3.0, 1.0), size: 52, lineWidth: 5, color: ddosColor, showValue: false)
                    .overlay(
                        Text("\(viewModel.ddosStatus?.level ?? 0)")
                            .font(AXTypography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(ddosColor)
                    )
            }
        }
    }

    private func ddosMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.monoMd)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Quick Stats Card

    private var quickStatsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXSectionHeader(title: "Module Activity", subtitle: "Events detected today")
                HStack(spacing: 0) {
                    moduleActivityCell(icon: "ant.fill", label: "Honeypot Hits",
                                       value: "\(viewModel.overview?.honeypotHitsToday ?? 0)", color: .axWarning)
                    Divider().frame(height: 52)
                    moduleActivityCell(icon: "key.fill", label: "Credential Attacks",
                                       value: "\(viewModel.overview?.credentialAttacksToday ?? 0)", color: .axError)
                    Divider().frame(height: 52)
                    moduleActivityCell(icon: "doc.text.magnifyingglass", label: "DLP Events",
                                       value: "\(viewModel.overview?.dlpEventsToday ?? 0)", color: .axAccentPurple)
                }
            }
        }
    }

    private func moduleActivityCell(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(AXTypography.caption)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextSecondary)
            }
            Spacer()
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Helpers

    private var threatLevel: Int {
        let ddos = viewModel.ddosStatus?.level ?? 0
        let blocked = viewModel.overview?.blockedRequests ?? 0
        if viewModel.ddosStatus?.underAttack == true || ddos >= 3 { return 3 }
        if ddos >= 2 || blocked > 10_000 { return 2 }
        if ddos >= 1 || blocked > 100 { return 1 }
        return 0
    }

    private var threatColor: Color {
        switch threatLevel {
        case 0: return .axAccentGreen
        case 1: return .axAccentBlue
        case 2: return .axWarning
        default: return .axError
        }
    }

    private var threatLabel: String {
        switch threatLevel {
        case 0: return "Protected"
        case 1: return "Monitoring"
        case 2: return "Alert"
        default: return "Under Attack"
        }
    }

    private var threatIcon: String {
        switch threatLevel {
        case 0: return "shield.fill"
        case 1: return "shield.lefthalf.filled"
        case 2: return "exclamationmark.shield.fill"
        default: return "bolt.shield.fill"
        }
    }

    private var ddosColor: Color {
        switch viewModel.ddosStatus?.level ?? 0 {
        case 0: return .axAccentGreen
        case 1, 2: return .axWarning
        default: return .axError
        }
    }

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        return code.uppercased().unicodeScalars.compactMap { Unicode.Scalar(base + $0.value).map(String.init) }.joined()
    }
}
