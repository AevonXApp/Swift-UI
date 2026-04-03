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
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.dashboardLoading && viewModel.overview == nil {
                    skeletonContent
                } else {
                    errorBanner
                    threatHeroCard
                    primaryStatsGrid
                    domainHealthRow
                    middleRow
                    liveIndicatorsRow
                    ddosShieldCard
                    bottomRow
                }
            }
            .padding(AXSpacing.xl)
        }
        .task {
            // Load core dashboard first (6 SSH calls), then supplementary (3 SSH calls)
            // to avoid overwhelming the SSH multiplexer with 9+ concurrent commands.
            await viewModel.loadDashboard()
            async let blog: () = viewModel.loadBlockLog()
            async let qps:  () = viewModel.loadQPS()
            async let anom: () = viewModel.loadAnomalyStatus()
            _ = await (blog, qps, anom)
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
                Button(L10n.Button.retry) { Task { await viewModel.loadDashboard() } }
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
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [threatColor.opacity(0.06), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
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
                    Text(L10n.Cerberus.Dashboard.heroSubtitle)
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
                AXBadge(text: L10n.Cerberus.Dashboard.underAttack, color: .axError, style: .soft)
            }
            if (viewModel.overview?.blockedRequests ?? 0) > 0 {
                AXBadge(text: L10n.Cerberus.Dashboard.blockedCount(viewModel.formatNumber(viewModel.overview?.blockedRequests ?? 0)), color: .axWarning, style: .soft)
            }
            if let refreshed = viewModel.lastRefreshed {
                lastRefreshedBadge(refreshed)
            }
        }
    }

    private func lastRefreshedBadge(_ date: Date) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 9))
            Text(date, style: .relative)
                .font(AXTypography.caption2)
        }
        .foregroundStyle(Color.axTextMuted)
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
            ZStack {
                // Subtle radial glow behind the ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [threatColor.opacity(0.12), Color.clear],
                            center: .center, startRadius: 10, endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

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
                        Text(L10n.Cerberus.Dashboard.blocked)
                            .font(AXTypography.caption2)
                            .foregroundStyle(Color.axTextMuted)
                    }
                )
            }
            Text(L10n.Cerberus.Dashboard.protectionRate)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextSecondary)
        }
    }

    private var heroMetricsRight: some View {
        VStack(alignment: .trailing, spacing: AXSpacing.lg) {
            heroMetric(label: L10n.Cerberus.Dashboard.totalRequests, value: viewModel.formatNumber(viewModel.overview?.totalRequests ?? 0), color: .axAccentBlue)
            heroMetric(label: L10n.Cerberus.Dashboard.requestsPerSec, value: String(format: "%.1f", viewModel.currentQPS ?? viewModel.overview?.qps ?? 0.0), color: .axAccentGreen)
            heroMetric(label: L10n.Cerberus.Dashboard.uptime, value: viewModel.formatUptime(viewModel.overview?.uptimeSeconds ?? 0), color: .axAccentPurple)
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
            primaryStatCard(title: L10n.Cerberus.Dashboard.totalRequests,
                            value: viewModel.formatNumber(viewModel.overview?.totalRequests ?? 0),
                            icon: "arrow.up.arrow.down", color: .axAccentBlue,
                            subtitle: L10n.Cerberus.Dashboard.allTraffic)
            primaryStatCard(title: L10n.Cerberus.Dashboard.statBlocked,
                            value: viewModel.formatNumber(viewModel.overview?.blockedRequests ?? 0),
                            icon: "hand.raised.fill", color: .axError,
                            subtitle: String(format: "%.1f%%", viewModel.overview?.protectionRate ?? 0.0))
            primaryStatCard(title: L10n.Cerberus.Dashboard.statAllowed,
                            value: viewModel.formatNumber(viewModel.overview?.allowedRequests ?? 0),
                            icon: "checkmark.shield.fill", color: .axAccentGreen,
                            subtitle: L10n.Cerberus.Dashboard.passedThrough)
            primaryStatCard(title: L10n.Cerberus.Dashboard.statQPS,
                            value: String(format: "%.1f", viewModel.currentQPS ?? viewModel.overview?.qps ?? 0.0),
                            icon: "gauge.with.dots.needle.33percent", color: .axAccentPurple,
                            subtitle: L10n.Cerberus.Dashboard.queriesSec)
        }
    }

    private func primaryStatCard(title: String, value: String, icon: String, color: Color, subtitle: String) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    gradientIconBox(icon: icon, color: color, size: 30)
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

    // MARK: - Domain Health Row

    @ViewBuilder
    private var domainHealthRow: some View {
        if !viewModel.domains.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    gradientIconBox(icon: "globe", color: .mint, size: 22)
                    Text(L10n.Cerberus.Dashboard.domainHealth)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AXSpacing.md) {
                        ForEach(viewModel.domains) { domain in
                            domainMiniCard(domain)
                        }
                    }
                }
            }
        }
    }

    private func domainMiniCard(_ domain: WAFDomainInfo) -> some View {
        let stats = viewModel.domainStats[domain.domain]
        return VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(domain.enabled ? Color.axAccentGreen : Color.axTextMuted)
                    .frame(width: 6, height: 6)
                Text(domain.domain)
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextPrimary)
                    .lineLimit(1)
            }
            HStack(spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(viewModel.formatNumber(Int(stats?.totalRequests ?? 0)))
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axAccentBlue)
                    Text(L10n.Cerberus.Dashboard.totalRequests)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(viewModel.formatNumber(Int(stats?.blockedRequests ?? 0)))
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axError)
                    Text(L10n.Cerberus.Dashboard.statBlocked)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
            }
        }
        .padding(AXSpacing.md)
        .frame(minWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
        )
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
            gradientIconBox(icon: "chart.bar.fill", color: .axAccentBlue, size: 26)
            Text(L10n.Cerberus.Dashboard.hourTraffic)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
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
        .chartPlotStyle { plotArea in
            plotArea
                .border(Color.axDivider.opacity(0.2), width: 1)
                .background(Color.axSurface.opacity(0.3))
        }
        .frame(height: 200)
    }

    private var timelineLegend: some View {
        HStack(spacing: AXSpacing.lg) {
            chartLegendDot(color: .axAccentGreen, label: L10n.Cerberus.Dashboard.legendAllowed)
            chartLegendDot(color: .axError, label: L10n.Cerberus.Dashboard.legendBlocked)
            Spacer()
            timelinePeakLabel
        }
    }

    @ViewBuilder
    private var timelinePeakLabel: some View {
        if let peak = viewModel.timeline.max(by: { $0.total < $1.total }), peak.total > 0 {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.axWarning)
                Text(L10n.Cerberus.Dashboard.peakHour(peak.hour))
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextMuted)
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
            Text(L10n.Cerberus.Dashboard.noTimelineData).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
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
                    AXEmptyState(icon: "globe", title: L10n.Cerberus.Dashboard.noData, description: L10n.Cerberus.Dashboard.noAttackOrigins)
                    Spacer()
                } else {
                    countriesListContent
                }
            }
        }
    }

    private var countriesHeader: some View {
        HStack {
            gradientIconBox(icon: "globe.americas.fill", color: .axError, size: 26)
            Text(L10n.Cerberus.Dashboard.attackOrigins)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
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
            countryRowDetail(country, maxCount: maxCount)
        }
    }

    private func countryRowDetail(_ country: CountryStats, maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            HStack {
                Text(localizedCountryName(country))
                    .font(AXTypography.caption).foregroundStyle(Color.axTextPrimary).lineLimit(1)
                Spacer()
                Text(viewModel.formatNumber(country.count))
                    .font(AXTypography.monoXs).foregroundStyle(Color.axError)
            }
            countryBarGraph(country.count, maxCount: maxCount)
        }
    }

    private func countryBarGraph(_ count: Int, maxCount: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs).fill(Color.axError.opacity(0.08))
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(LinearGradient(colors: [Color.axError.opacity(0.8), Color.axError.opacity(0.3)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * (Double(count) / Double(max(maxCount, 1))))
            }
            .frame(height: 3)
        }
        .frame(height: 3)
    }

    // MARK: - Live Indicators Row

    private var liveIndicatorsRow: some View {
        HStack(spacing: AXSpacing.md) {
            liveIndicatorCard(label: L10n.Cerberus.Dashboard.bytesIn, value: viewModel.formatBytes(viewModel.overview?.bytesIn ?? 0),
                              icon: "arrow.down.circle.fill", color: .axAccentBlue, sub: L10n.Cerberus.Dashboard.inbound)
            liveIndicatorCard(label: L10n.Cerberus.Dashboard.bytesOut, value: viewModel.formatBytes(viewModel.overview?.bytesOut ?? 0),
                              icon: "arrow.up.circle.fill", color: .axAccentGreen, sub: L10n.Cerberus.Dashboard.outbound)
            liveIndicatorCard(label: L10n.Cerberus.Dashboard.botRequests, value: viewModel.formatNumber(viewModel.overview?.botRequests ?? 0),
                              icon: "cpu.fill", color: .axWarning, sub: botPercentLabel)
            liveIndicatorCard(label: L10n.Cerberus.Dashboard.uptime, value: viewModel.formatUptime(viewModel.overview?.uptimeSeconds ?? 0),
                              icon: "clock.fill", color: .axAccentPurple, sub: L10n.Cerberus.Dashboard.continuous)
        }
    }

    private func liveIndicatorCard(label: String, value: String, icon: String, color: Color, sub: String) -> some View {
        AXCard(accentColor: color) {
            HStack(spacing: AXSpacing.md) {
                gradientIconBox(icon: icon, color: color, size: 36)
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
            Image(systemName: "bolt.shield.fill")
                .font(AXTypography.title3)
                .foregroundStyle(ddosColor)
                .opacity(ddosShieldPulseActive ? 0.6 : 1.0)
                .animation(
                    ddosShieldPulseActive
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: ddosShieldPulseActive
                )
        }
    }

    private var ddosShieldPulseActive: Bool {
        viewModel.ddosStatus?.underAttack == true
    }

    private var ddosShieldInfo: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            ddosShieldTitleRow
            ddosShieldMetricsRow
        }
    }

    private var ddosShieldTitleRow: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.Cerberus.Dashboard.ddosShield).font(AXTypography.headline).fontWeight(.semibold).foregroundStyle(Color.axTextPrimary)
            AXBadge(text: L10n.Cerberus.Dashboard.levelName(viewModel.ddosStatus?.level ?? 0, L10n.Cerberus.Dashboard.ddosLevelName(for: viewModel.ddosStatus?.levelKey ?? "none")), color: ddosColor, style: .soft)
            if viewModel.ddosStatus?.underAttack == true {
                AXBadge(text: L10n.Cerberus.Dashboard.underAttack, color: .axError, style: .soft)
            }
        }
    }

    private var ddosShieldMetricsRow: some View {
        HStack(spacing: AXSpacing.xxl) {
            ddosMetric(label: L10n.Cerberus.Dashboard.currentQPS, value: String(format: "%.1f", viewModel.ddosStatus?.currentQps ?? 0.0))
            ddosMetric(label: L10n.Cerberus.Dashboard.baselineQPS, value: String(format: "%.1f", viewModel.ddosStatus?.baselineQps ?? 0.0))
            ddosMetric(label: L10n.Cerberus.Dashboard.spikeRatio, value: ddosSpikeRatio)
        }
    }

    private var ddosShieldLevel: some View {
        AXCircularProgress(value: min(Double(viewModel.ddosStatus?.level ?? 0) / 3.0, 1.0),
                           size: 56, lineWidth: 5, color: ddosColor, showValue: false)
            .overlay(
                VStack(spacing: 0) {
                    Text("\(viewModel.ddosStatus?.level ?? 0)")
                        .font(AXTypography.title3).fontWeight(.bold).foregroundStyle(ddosColor)
                    Text(L10n.Cerberus.Dashboard.lvl).font(AXTypography.caption2).foregroundStyle(Color.axTextMuted)
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
            recentBlocksCard.frame(width: 440)
        }
    }

    private var moduleActivityGrid: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                moduleActivityHeader
                moduleActivityCells
            }
        }
    }

    private var moduleActivityHeader: some View {
        HStack {
            gradientIconBox(icon: "square.grid.3x3.fill", color: .axAccentBlue, size: 26)
            Text(L10n.Cerberus.Dashboard.moduleActivity)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            Text(L10n.Cerberus.Dashboard.today).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted)
        }
    }

    private var moduleActivityCells: some View {
        HStack(spacing: 0) {
            moduleCell(icon: "ant.fill", label: L10n.Cerberus.Dashboard.honeypotLabel,
                       value: "\(viewModel.overview?.honeypotHitsToday ?? 0)", color: .axWarning,
                       showBorder: true)
            moduleCell(icon: "key.fill", label: L10n.Cerberus.Dashboard.credentialLabel,
                       value: "\(viewModel.overview?.credentialAttacksToday ?? 0)", color: .axError,
                       showBorder: true)
            moduleCell(icon: "doc.text.magnifyingglass", label: L10n.Cerberus.Dashboard.dlpLabel,
                       value: "\(viewModel.overview?.dlpEventsToday ?? 0)", color: .axAccentPurple,
                       showBorder: true)
            moduleCell(icon: "bell.badge.fill", label: L10n.Cerberus.Dashboard.alertsLabel,
                       value: "\(viewModel.recentAlerts.count)", color: .axAccentBlue,
                       showBorder: false)
        }
    }

    private func moduleCell(icon: String, label: String, value: String, color: Color, showBorder: Bool) -> some View {
        HStack(spacing: AXSpacing.md) {
            gradientIconBox(icon: icon, color: color, size: 36)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value).font(AXTypography.title3).fontWeight(.bold).foregroundStyle(Color.axTextPrimary)
                Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
            }
            Spacer()
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if showBorder {
                Rectangle()
                    .fill(Color.axDivider.opacity(0.4))
                    .frame(width: 1)
            }
        }
    }

    // MARK: - Recent Blocks Feed

    private var recentBlocksCard: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                recentBlocksHeader
                if viewModel.blockLog.isEmpty {
                    emptyFeedPlaceholder
                } else {
                    recentBlocksList
                }
            }
        }
    }

    private var recentBlocksHeader: some View {
        HStack {
            gradientIconBox(icon: "hand.raised.fill", color: .axError, size: 26)
            Text(L10n.Cerberus.Dashboard.recentBlocks)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.blockLog.isEmpty {
                AXBadge(text: "\(viewModel.blockLog.count)", color: .axError, style: .soft)
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
            Text(flagEmoji(for: entry.countryCode)).font(AXTypography.caption)
            blockLogRowDetail(entry)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.4)))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(severityColor(entry.severity))
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
    }

    private func blockLogRowDetail(_ entry: WAFBlockLogEntry) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            HStack(spacing: AXSpacing.xs) {
                Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(entry.ip) : entry.ip).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary).lineLimit(1)
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

    private var emptyFeedPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: "shield.checkered").font(AXTypography.title2).foregroundStyle(Color.axTextMuted)
                Text(L10n.Cerberus.Dashboard.noRecentBlocks).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
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

    private func gradientIconBox(icon: String, color: Color, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
        case 0: return L10n.Cerberus.Dashboard.protected
        case 1: return L10n.Cerberus.Dashboard.monitoring
        case 2: return L10n.Cerberus.Dashboard.alert
        default: return L10n.Cerberus.Dashboard.underAttackLabel
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

    private func localizedCountryName(_ country: CountryStats) -> String {
        if !country.countryName.isEmpty { return country.countryName }
        return Locale.current.localizedString(forRegionCode: country.countryCode) ?? country.countryCode
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
