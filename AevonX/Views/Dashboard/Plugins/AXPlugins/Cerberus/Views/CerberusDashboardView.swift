//
//  CerberusDashboardView.swift
//  AevonX
//
//  Dashboard tab — AXCerberus WAF command center.
//  Threat hero · live metrics · 24h timeline · attack origins · DDoS shield
//  · module activity · recent block log · country breakdown.
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
                    liveIndicatorsRow
                    ddosShieldCard
                    bottomRow
                }
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await viewModel.loadDashboard()
            await viewModel.loadBlockLog()
        }
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
                AXCard { AXSkeletonBlock(lines: 6) }.frame(width: 280)
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
                threatIconBadge
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
            statusBadgesRow
        }
    }

    private var statusBadgesRow: some View {
        HStack(spacing: AXSpacing.sm) {
            AXStatusBadge(
                status: (viewModel.serviceStatus?.isActive ?? false) ? .online : .offline,
                showLabel: true,
                enablePulseAnimation: viewModel.serviceStatus?.isActive ?? false
            )
            if viewModel.ddosStatus?.underAttack == true {
                AXBadge(text: "UNDER ATTACK", color: .axError, style: .soft)
            }
            if (viewModel.overview?.blockedRequests ?? 0) > 0 {
                AXBadge(text: "\(viewModel.formatNumber(viewModel.overview?.blockedRequests ?? 0)) blocked", color: .axWarning, style: .soft)
            }
        }
    }

    private var threatIconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [threatColor.opacity(0.25), threatColor.opacity(0.05)],
                        center: .center, startRadius: 0, endRadius: 28
                    )
                )
                .frame(width: 52, height: 52)
            Circle()
                .stroke(threatColor.opacity(0.3), lineWidth: 1)
                .frame(width: 52, height: 52)
            Image(systemName: threatIcon)
                .font(AXTypography.title3)
                .foregroundStyle(threatColor)
        }
    }

    private var protectionRingCenter: some View {
        VStack(spacing: AXSpacing.sm) {
            AXCircularProgress(
                value: (viewModel.overview?.protectionRate ?? 0.0) / 100,
                size: 88, lineWidth: 8, color: threatColor, showValue: false
            )
            .overlay(
                VStack(spacing: 0) {
                    Text(String(format: "%.1f%%", viewModel.overview?.protectionRate ?? 0.0))
                        .font(AXTypography.monoMd)
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
            heroMetric(label: "Total Requests", value: viewModel.formatNumber(viewModel.overview?.totalRequests ?? 0), color: .axAccentBlue)
            heroMetric(label: "Requests / sec", value: String(format: "%.1f", viewModel.overview?.qps ?? 0.0), color: .axAccentGreen)
            heroMetric(label: "Uptime", value: viewModel.formatUptime(viewModel.overview?.uptimeSeconds ?? 0), color: .axAccentPurple)
        }
    }

    private func heroMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Primary Stats Grid

    private var primaryStatsGrid: some View {
        HStack(spacing: AXSpacing.md) {
            primaryStatCard(title: "Total Requests",
                            value: viewModel.formatNumber(viewModel.overview?.totalRequests ?? 0),
                            icon: "arrow.up.arrow.down", color: .axAccentBlue,
                            subtitle: "all traffic")
            primaryStatCard(title: "Blocked",
                            value: viewModel.formatNumber(viewModel.overview?.blockedRequests ?? 0),
                            icon: "hand.raised.fill", color: .axError,
                            subtitle: String(format: "%.1f%%", viewModel.overview?.protectionRate ?? 0.0))
            primaryStatCard(title: "Allowed",
                            value: viewModel.formatNumber(viewModel.overview?.allowedRequests ?? 0),
                            icon: "checkmark.shield.fill", color: .axAccentGreen,
                            subtitle: "passed through")
            primaryStatCard(title: "QPS",
                            value: String(format: "%.1f", viewModel.overview?.qps ?? 0.0),
                            icon: "gauge.with.dots.needle.33percent", color: .axAccentPurple,
                            subtitle: "queries/sec")
        }
    }

    private func primaryStatCard(title: String, value: String, icon: String, color: Color, subtitle: String) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    iconBox(icon: icon, color: color, size: 30)
                    Spacer()
                }
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.xs) {
                    Text(title)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextSecondary)
                    Spacer()
                    Text(subtitle)
                        .font(AXTypography.monoXs)
                        .foregroundStyle(color.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Middle Row (Timeline + Countries)

    private var middleRow: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            timelineCard
            topCountriesCard.frame(width: 300)
        }
    }

    private var timelineCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                timelineHeader
                timelineChartArea
                timelineLegend
            }
        }
    }

    private var timelineHeader: some View {
        HStack {
            Image(systemName: "chart.bar.fill").foregroundStyle(Color.axAccentBlue)
            Text("24-Hour Traffic").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            timelineTotalBadge
        }
    }

    private var timelineTotalBadge: some View {
        Group {
            if !viewModel.timeline.isEmpty {
                let total = viewModel.timeline.reduce(0) { $0 + $1.total }
                AXBadge(text: viewModel.formatNumber(total) + " reqs", color: .axAccentBlue, style: .soft)
            }
        }
    }

    private var timelineChartArea: some View {
        Group {
            if viewModel.timeline.isEmpty || viewModel.timeline.allSatisfy({ $0.total == 0 }) {
                emptyChartPlaceholder
            } else {
                timelineAreaChart
            }
        }
    }

    private var timelineAreaChart: some View {
        Chart {
            ForEach(viewModel.timeline) { entry in
                AreaMark(
                    x: .value("Hour", "\(entry.hour):00"),
                    y: .value("Allowed", entry.allowed)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.axAccentGreen.opacity(0.4), Color.axAccentGreen.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Hour", "\(entry.hour):00"),
                    y: .value("Allowed", entry.allowed)
                )
                .foregroundStyle(Color.axAccentGreen.opacity(0.8))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Hour", "\(entry.hour):00"),
                    y: .value("Blocked", entry.blocked)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.axError.opacity(0.4), Color.axError.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Hour", "\(entry.hour):00"),
                    y: .value("Blocked", entry.blocked)
                )
                .foregroundStyle(Color.axError.opacity(0.8))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 4)) {
                AxisGridLine().foregroundStyle(Color.axDivider.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.axTextTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(Color.axDivider.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.axTextTertiary)
            }
        }
        .frame(height: 200)
    }

    private var timelineLegend: some View {
        HStack(spacing: AXSpacing.lg) {
            chartLegendDot(color: .axAccentGreen, label: "Allowed")
            chartLegendDot(color: .axError, label: "Blocked")
            Spacer()
            if let peak = viewModel.timeline.max(by: { $0.total < $1.total }), peak.total > 0 {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.up.right").font(.system(size: 9)).foregroundStyle(Color.axWarning)
                    Text("Peak: \(peak.hour):00").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted)
                }
            }
        }
    }

    private func chartLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "chart.bar").font(AXTypography.title3).foregroundStyle(Color.axTextMuted)
            Text("No timeline data").font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity).frame(height: 200)
    }

    // MARK: - Top Countries Panel

    private var topCountriesCard: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                countriesHeader
                if viewModel.countries.isEmpty {
                    Spacer()
                    AXEmptyState(icon: "globe", title: "No Data", description: "No attack origins recorded yet.")
                    Spacer()
                } else {
                    countriesListContent
                }
            }
        }
    }

    private var countriesHeader: some View {
        HStack {
            Image(systemName: "globe.americas.fill").foregroundStyle(Color.axError)
            Text("Attack Origins").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.countries.isEmpty {
                AXBadge(text: "\(viewModel.countries.count)", color: .axError, style: .soft)
            }
        }
    }

    private var countriesListContent: some View {
        let maxCount = viewModel.countries.first?.count ?? 1
        return VStack(spacing: AXSpacing.sm) {
            ForEach(Array(viewModel.countries.prefix(8).enumerated()), id: \.element.id) { idx, country in
                countryRow(country, maxCount: maxCount, rank: idx + 1)
            }
        }
    }

    private func countryRow(_ country: CountryStats, maxCount: Int, rank: Int) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Text("\(rank)")
                .font(AXTypography.monoXs)
                .foregroundStyle(rank <= 3 ? Color.axError : Color.axTextMuted)
                .frame(width: 14, alignment: .trailing)
            Text(flagEmoji(for: country.countryCode))
                .font(AXTypography.caption)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack {
                    Text(country.countryName.isEmpty ? country.countryCode : country.countryName)
                        .font(AXTypography.caption).foregroundStyle(Color.axTextPrimary).lineLimit(1)
                    Spacer()
                    Text(viewModel.formatNumber(country.count))
                        .font(AXTypography.monoXs).foregroundStyle(Color.axError)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs).fill(Color.axError.opacity(0.08))
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(LinearGradient(colors: [Color.axError.opacity(0.8), Color.axError.opacity(0.3)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * (Double(country.count) / Double(max(maxCount, 1))))
                    }
                    .frame(height: 3)
                }
                .frame(height: 3)
            }
        }
    }

    // MARK: - Live Indicators Row

    private var liveIndicatorsRow: some View {
        HStack(spacing: AXSpacing.md) {
            liveIndicatorCard(label: "Bytes In", value: viewModel.formatBytes(viewModel.overview?.bytesIn ?? 0),
                              icon: "arrow.down.circle.fill", color: .axAccentBlue, sub: "inbound")
            liveIndicatorCard(label: "Bytes Out", value: viewModel.formatBytes(viewModel.overview?.bytesOut ?? 0),
                              icon: "arrow.up.circle.fill", color: .axAccentGreen, sub: "outbound")
            liveIndicatorCard(label: "Bot Requests", value: viewModel.formatNumber(viewModel.overview?.botRequests ?? 0),
                              icon: "cpu.fill", color: .axWarning, sub: botPercentLabel)
            liveIndicatorCard(label: "Uptime", value: viewModel.formatUptime(viewModel.overview?.uptimeSeconds ?? 0),
                              icon: "clock.fill", color: .axAccentPurple, sub: "continuous")
        }
    }

    private func liveIndicatorCard(label: String, value: String, icon: String, color: Color, sub: String) -> some View {
        AXCard(accentColor: color) {
            HStack(spacing: AXSpacing.md) {
                iconBox(icon: icon, color: color, size: 36)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(value).font(AXTypography.title3).fontWeight(.bold).foregroundStyle(Color.axTextPrimary)
                    HStack(spacing: AXSpacing.xs) {
                        Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
                        Text(sub).font(AXTypography.monoXs).foregroundStyle(color.opacity(0.6))
                    }
                }
                Spacer()
            }
        }
    }

    private var botPercentLabel: String {
        let total = (viewModel.overview?.botRequests ?? 0) + (viewModel.overview?.humanRequests ?? 0)
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", Double(viewModel.overview?.botRequests ?? 0) / Double(total) * 100)
    }

    // MARK: - DDoS Shield Card

    private var ddosShieldCard: some View {
        AXGlassCard(accentColor: ddosColor) {
            HStack(spacing: AXSpacing.xl) {
                ddosShieldIcon
                ddosShieldInfo
                Spacer()
                ddosShieldLevel
            }
        }
    }

    private var ddosShieldIcon: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [ddosColor.opacity(0.2), ddosColor.opacity(0.03)],
                                     center: .center, startRadius: 0, endRadius: 30))
                .frame(width: 56, height: 56)
            Circle().stroke(ddosColor.opacity(0.3), lineWidth: 1).frame(width: 56, height: 56)
            Image(systemName: "bolt.shield.fill").font(AXTypography.title3).foregroundStyle(ddosColor)
        }
    }

    private var ddosShieldInfo: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Text("DDoS Shield").font(AXTypography.headline).fontWeight(.semibold).foregroundStyle(Color.axTextPrimary)
                AXBadge(text: "Level \(viewModel.ddosStatus?.level ?? 0): \(viewModel.ddosStatus?.levelName ?? "None")", color: ddosColor, style: .soft)
                if viewModel.ddosStatus?.underAttack == true {
                    AXBadge(text: "UNDER ATTACK", color: .axError, style: .soft)
                }
            }
            HStack(spacing: AXSpacing.xxl) {
                ddosMetric(label: "Current QPS", value: String(format: "%.1f", viewModel.ddosStatus?.currentQps ?? 0.0))
                ddosMetric(label: "Baseline QPS", value: String(format: "%.1f", viewModel.ddosStatus?.baselineQps ?? 0.0))
                ddosMetric(label: "Spike Ratio", value: ddosSpikeRatio)
            }
        }
    }

    private var ddosShieldLevel: some View {
        AXCircularProgress(value: min(Double(viewModel.ddosStatus?.level ?? 0) / 3.0, 1.0),
                           size: 56, lineWidth: 5, color: ddosColor, showValue: false)
            .overlay(
                VStack(spacing: 0) {
                    Text("\(viewModel.ddosStatus?.level ?? 0)")
                        .font(AXTypography.title3).fontWeight(.bold).foregroundStyle(ddosColor)
                    Text("LVL").font(AXTypography.caption2).foregroundStyle(Color.axTextMuted)
                }
            )
    }

    private func ddosMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(value).font(AXTypography.monoMd).fontWeight(.semibold).foregroundStyle(Color.axTextPrimary)
            Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
        }
    }

    private var ddosSpikeRatio: String {
        let current = viewModel.ddosStatus?.currentQps ?? 0.0
        let baseline = viewModel.ddosStatus?.baselineQps ?? 1.0
        guard baseline > 0 else { return "1.0x" }
        return String(format: "%.1fx", current / baseline)
    }

    // MARK: - Bottom Row (Module Activity + Recent Blocks)

    private var bottomRow: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            moduleActivityGrid
            recentBlocksCard.frame(width: 420)
        }
    }

    private var moduleActivityGrid: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "square.grid.3x3.fill").foregroundStyle(Color.axAccentBlue)
                    Text("Module Activity").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    Text("today").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted)
                }
                moduleActivityCells
            }
        }
    }

    private var moduleActivityCells: some View {
        HStack(spacing: 0) {
            moduleCell(icon: "ant.fill", label: "Honeypot",
                       value: "\(viewModel.overview?.honeypotHitsToday ?? 0)", color: .axWarning)
            Divider().frame(height: 52)
            moduleCell(icon: "key.fill", label: "Credential",
                       value: "\(viewModel.overview?.credentialAttacksToday ?? 0)", color: .axError)
            Divider().frame(height: 52)
            moduleCell(icon: "doc.text.magnifyingglass", label: "DLP",
                       value: "\(viewModel.overview?.dlpEventsToday ?? 0)", color: .axAccentPurple)
            Divider().frame(height: 52)
            moduleCell(icon: "bell.badge.fill", label: "Alerts",
                       value: "\(viewModel.recentAlerts.count)", color: .axAccentBlue)
        }
    }

    private func moduleCell(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            iconBox(icon: icon, color: color, size: 36)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value).font(AXTypography.title3).fontWeight(.bold).foregroundStyle(Color.axTextPrimary)
                Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
            }
            Spacer()
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recent Blocks Feed

    private var recentBlocksCard: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Color.axError)
                    Text("Recent Blocks").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if !viewModel.blockLog.isEmpty {
                        AXBadge(text: "\(viewModel.blockLog.count)", color: .axError, style: .soft)
                    }
                }
                if viewModel.blockLog.isEmpty {
                    emptyFeedPlaceholder
                } else {
                    recentBlocksList
                }
            }
        }
    }

    private var recentBlocksList: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(Array(viewModel.blockLog.prefix(8).enumerated()), id: \.element.id) { _, entry in
                blockLogRow(entry)
            }
        }
    }

    private func blockLogRow(_ entry: WAFBlockLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            severityDot(entry.severity)
            Text(flagEmoji(for: entry.countryCode)).font(AXTypography.caption)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(entry.ip).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary).lineLimit(1)
                    Spacer()
                    Text(entry.rule).font(AXTypography.monoXs).foregroundStyle(Color.axError).lineLimit(1)
                }
                HStack(spacing: AXSpacing.xs) {
                    Text("\(entry.method) \(entry.path)")
                        .font(AXTypography.caption).foregroundStyle(Color.axTextMuted).lineLimit(1)
                    Spacer()
                    Text(formatTimestamp(entry.timestamp))
                        .font(AXTypography.monoXs).foregroundStyle(Color.axTextTertiary)
                }
            }
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.4)))
    }

    private func severityDot(_ severity: String) -> some View {
        Circle()
            .fill(severityColor(severity))
            .frame(width: 6, height: 6)
    }

    private var emptyFeedPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: "shield.checkered").font(AXTypography.title2).foregroundStyle(Color.axTextMuted)
                Text("No recent blocks").font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }
            .padding(.vertical, AXSpacing.xxl)
            Spacer()
        }
    }

    // MARK: - Shared Helpers

    private func iconBox(icon: String, color: Color, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundStyle(color)
        }
    }

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

    private func severityColor(_ s: String) -> Color {
        switch s.lowercased() {
        case "critical": return .axError
        case "high": return .axWarning
        case "medium": return .axAccentPurple
        default: return .axAccentBlue
        }
    }

    private func formatTimestamp(_ ts: String) -> String {
        guard ts.count >= 19 else { return ts }
        return String(ts.suffix(from: ts.index(ts.startIndex, offsetBy: 11)).prefix(8))
    }
}
