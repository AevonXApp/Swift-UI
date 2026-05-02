//
//  CerberusDomainDetailView.swift
//  AevonX
//
//  Full-page domain detail — overview stats, traffic chart,
//  countries, attacks, and per-domain blocking. No sheets.
//

import SwiftUI
import Charts
import AevonXCoreBridge

// MARK: - Tab

enum DomainDetailTab: String, CaseIterable {
    case overview, traffic, attacks, countries, blocking

    var label: String {
        switch self {
        case .overview:  return L10n.Cerberus.DomainDetail.tabOverview
        case .traffic:   return L10n.Cerberus.DomainDetail.tabTraffic
        case .attacks:   return L10n.Cerberus.DomainDetail.tabAttacks
        case .countries: return L10n.Cerberus.DomainDetail.tabCountries
        case .blocking:  return L10n.Cerberus.DomainDetail.tabBlocking
        }
    }

    var icon: String {
        switch self {
        case .overview:  return "chart.bar.xaxis"
        case .traffic:   return "arrow.up.arrow.down"
        case .attacks:   return "exclamationmark.triangle"
        case .countries: return "globe"
        case .blocking:  return "hand.raised.fill"
        }
    }
}

// MARK: - Main View

struct CerberusDomainDetailView: View {
    @ObservedObject var viewModel: CerberusViewModel
    let domain: WAFDomainInfo
    var onBack: () -> Void
    @State private var selectedTab: DomainDetailTab = .overview
    @State private var domainTimeRange: WAFTimeRange = .hour24
    @State private var hoveredHour: Int? = nil
    @State private var tooltipOffsetX: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            detailToolbar
            tabBar
            tabContent
        }
        .background(Color.axBackground)
        .task { await viewModel.loadDomainDetail(domain: domain.domain) }
    }
}

// MARK: - Toolbar

private extension CerberusDomainDetailView {

    var detailToolbar: some View {
        HStack(spacing: AXSpacing.md) {
            backButton
            toolbarDivider
            toolbarDomainInfo
            Spacer()
            if viewModel.domainDetailLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
            refreshButton
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface.opacity(0.6))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.axDivider.opacity(0.5)).frame(height: 1)
        }
    }

    var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                Text(L10n.Cerberus.Domains.title)
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.axAccentBlue)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axAccentBlue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
    }

    var toolbarDivider: some View {
        Rectangle()
            .fill(Color.axDivider)
            .frame(width: 1, height: 28)
    }

    var toolbarDomainInfo: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: domain.enabled
                                ? [Color.axAccentGreen.opacity(0.2), Color.axAccentBlue.opacity(0.1)]
                                : [Color.axTextMuted.opacity(0.1), Color.axTextMuted.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .strokeBorder(
                        domain.enabled ? Color.axAccentGreen.opacity(0.2) : Color.axTextMuted.opacity(0.1),
                        lineWidth: 1
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: domain.enabled ? "checkmark.shield.fill" : "shield.slash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        domain.enabled
                            ? LinearGradient(colors: [.axAccentGreen, .axAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.axTextMuted, .axTextMuted], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(domain.domain)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    AXStatusBadge(
                        status: domain.enabled ? .online : .offline,
                        showLabel: true,
                        enablePulseAnimation: domain.enabled
                    )
                    if !domain.webServer.isEmpty {
                        HStack(spacing: AXSpacing.xxs) {
                            Circle().fill(Color.axTextMuted.opacity(0.3)).frame(width: 3, height: 3)
                            Text(domain.webServer)
                                .font(AXTypography.caption2)
                                .foregroundStyle(Color.axTextTertiary)
                        }
                    }
                }
            }
        }
    }

    var refreshButton: some View {
        Button {
            Task { await viewModel.loadDomainDetail(domain: domain.domain) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.axTextSecondary)
                .frame(width: 28, height: 28)
                .background(Color.axSurface)
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .strokeBorder(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.domainDetailLoading)
    }
}

// MARK: - Tab Bar

private extension CerberusDomainDetailView {

    var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.xxs) {
                ForEach(DomainDetailTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.sm)
        }
        .background(Color.axSurface.opacity(0.4))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.axDivider.opacity(0.3)).frame(height: 1)
        }
    }

    func tabButton(_ tab: DomainDetailTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedTab = tab }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 10, weight: .medium))
                Text(tab.label)
                    .font(AXTypography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? Color.axAccentBlue : Color.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .strokeBorder(isSelected ? Color.axAccentBlue.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Content

private extension CerberusDomainDetailView {

    @ViewBuilder
    var tabContent: some View {
        Group {
            switch selectedTab {
            case .overview:  overviewTab
            case .traffic:   trafficTab
            case .attacks:   attacksTab
            case .countries: countriesTab
            case .blocking:  blockingTab
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Overview Tab

private extension CerberusDomainDetailView {

    var overviewTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                overviewMetrics
                timeFilterBar
                timelineChartSection
                HStack(alignment: .top, spacing: AXSpacing.lg) {
                    topCountriesCard
                    recentVisitsCard
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    var overviewMetrics: some View {
        let stats = viewModel.domainStats[domain.domain]
        let total = stats?.totalRequests ?? 0
        let blocked = stats?.blockedRequests ?? 0
        let rate = total > 0 ? Double(blocked) / Double(total) * 100 : 0

        return HStack(spacing: AXSpacing.md) {
            DetailMetricCard(
                title: L10n.Cerberus.DomainDetail.requests,
                value: DomainFormatHelper.formatNumber(total),
                icon: "arrow.up.arrow.down",
                color: .axAccentBlue,
                gradientEnd: .axAccentBlue.opacity(0.5)
            )
            DetailMetricCard(
                title: L10n.Cerberus.DomainDetail.blocked,
                value: DomainFormatHelper.formatNumber(blocked),
                icon: "hand.raised.fill",
                color: .axError,
                gradientEnd: .axWarning,
                subtitle: "Blocked automatically by WAF"
            )
            DetailMetricCard(
                title: L10n.Cerberus.DomainDetail.blockRate,
                value: String(format: "%.1f%%", rate),
                icon: "shield.checkered",
                color: rate > 10 ? .axWarning : .axAccentGreen,
                gradientEnd: rate > 10 ? .axError : .mint
            )
            DetailMetricCard(
                title: L10n.Cerberus.DomainDetail.avgLatency,
                value: avgLatencyText,
                icon: "timer",
                color: .axAccentGreen,
                gradientEnd: .mint
            )
        }
    }

    var timeFilterBar: some View {
        WAFTimeRangePicker(selected: $domainTimeRange)
            .onChange(of: domainTimeRange) {
                Task { await viewModel.loadDomainDetail(domain: domain.domain) }
            }
    }
}

// MARK: - Timeline Chart

private extension CerberusDomainDetailView {

    var timelineChartSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [Color.axAccentBlue.opacity(0.15), Color.axAccentBlue.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.axAccentBlue)
                }
                Text(L10n.Cerberus.DomainDetail.trafficChart)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextPrimary)
                Spacer()
                chartLegend
            }

            if viewModel.selectedDomainTimeline.isEmpty {
                DomainEmptyChart()
            } else {
                timelineChart
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .strokeBorder(Color.axBorder.opacity(0.4), lineWidth: 1)
                )
        )
    }

    var chartLegend: some View {
        HStack(spacing: AXSpacing.md) {
            legendDot(color: .axAccentBlue, label: L10n.Cerberus.DomainDetail.requests)
            legendDot(color: .axError, label: L10n.Cerberus.DomainDetail.blocked)
        }
    }

    func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var timelineChart: some View {
        let data = viewModel.selectedDomainTimeline
        return ZStack(alignment: .topLeading) {
            Chart {
                ForEach(data, id: \.hour) { entry in
                    AreaMark(
                        x: .value("Hour", entry.hour),
                        y: .value("Total", entry.total)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axAccentBlue.opacity(0.25), Color.axAccentBlue.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Hour", entry.hour),
                        y: .value("Total", entry.total)
                    )
                    .foregroundStyle(Color.axAccentBlue)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    if entry.blocked > 0 {
                        AreaMark(
                            x: .value("Hour", entry.hour),
                            y: .value("Blocked", entry.blocked)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.axError.opacity(0.2), Color.axError.opacity(0.01)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Hour", entry.hour),
                            y: .value("Blocked", entry.blocked)
                        )
                        .foregroundStyle(Color.axError.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }

                    if let h = hoveredHour, h == entry.hour {
                        RuleMark(x: .value("Hour", h))
                            .foregroundStyle(Color.axTextMuted.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 4)) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(String(format: "%02d:00", v))
                                .font(AXTypography.caption2)
                                .foregroundStyle(Color.axTextMuted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                        .foregroundStyle(Color.axDivider.opacity(0.5))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                        .foregroundStyle(Color.axDivider.opacity(0.5))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(DomainFormatHelper.formatNumber(v))
                                .font(AXTypography.caption2)
                                .foregroundStyle(Color.axTextMuted)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let loc):
                                let plotOrigin = geo[proxy.plotAreaFrame].origin
                                let relX = loc.x - plotOrigin.x
                                if let hour: Int = proxy.value(atX: relX) {
                                    let clamped = max(0, min(23, hour))
                                    hoveredHour = clamped
                                    if let posX = proxy.position(forX: clamped) {
                                        let raw = posX + plotOrigin.x
                                        tooltipOffsetX = min(max(raw - 60, 0), geo.size.width - 130)
                                    }
                                }
                            case .ended:
                                hoveredHour = nil
                            }
                        }
                }
            }
            .frame(height: 220)

            // Tooltip
            if let h = hoveredHour,
               let entry = data.first(where: { $0.hour == h }) {
                let blockPct = entry.total > 0 ? Double(entry.blocked) / Double(entry.total) * 100 : 0
                WAFChartTooltip(
                    title: String(format: "%02d:00", h),
                    rows: [
                        (L10n.Cerberus.DomainDetail.requests, "\(entry.total)", .axAccentBlue),
                        (L10n.Cerberus.DomainDetail.blocked,  "\(entry.blocked)", .axError),
                        ("Allowed",  "\(entry.allowed)",  .axAccentGreen),
                        ("Block%",   String(format: "%.1f%%", blockPct), blockPct > 20 ? .axError : .axTextMuted),
                    ]
                )
                .offset(x: tooltipOffsetX, y: 4)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: hoveredHour)
    }
}

// MARK: - Top Countries Card

private extension CerberusDomainDetailView {

    var topCountriesCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(
                                LinearGradient(
                                    colors: [Color.axAccentBlue.opacity(0.10), Color.axAccentBlue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.axAccentBlue)
                    }
                    Text(L10n.Cerberus.DomainDetail.topCountries)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    AXBadge(
                        text: "\(viewModel.selectedDomainCountries.count)",
                        color: .axAccentBlue,
                        style: .soft
                    )
                }

                if viewModel.selectedDomainCountries.isEmpty {
                    DomainEmptyMini(icon: "globe", text: L10n.Cerberus.DomainDetail.noCountries)
                } else {
                    ContinentLegendView(countryCodes: viewModel.selectedDomainCountries.prefix(6).map(\.countryCode))
                    ForEach(viewModel.selectedDomainCountries.prefix(6), id: \.countryCode) { country in
                        countryRow(country)
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }

    func countryRow(_ country: CountryStats) -> some View {
        let maxCount = viewModel.selectedDomainCountries.first?.count ?? 1
        let ratio = maxCount > 0 ? CGFloat(country.count) / CGFloat(maxCount) : 0
        let name = country.countryName.isEmpty
            ? (Locale.current.localizedString(forRegionCode: country.countryCode) ?? country.countryCode)
            : country.countryName
        let barColor = WAFContinent.from(countryCode: country.countryCode).color

        return HStack(spacing: AXSpacing.sm) {
            Text(countryFlagEmoji( country.countryCode))
                .font(.system(size: 14))
                .frame(width: 22)
            Text(name)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(1)
                .frame(minWidth: 60, alignment: .leading)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(barColor.opacity(0.35))
                    .frame(width: max(geo.size.width * ratio, 4))
            }
            .frame(height: 10)
            Text(DomainFormatHelper.formatNumber(country.count))
                .font(AXTypography.monoSm)
                .fontWeight(.medium)
                .foregroundStyle(Color.axTextSecondary)
                .frame(width: 45, alignment: .trailing)
        }
    }
}

// MARK: - Recent Visits Card

private extension CerberusDomainDetailView {

    var recentVisitsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(
                                LinearGradient(
                                    colors: [Color.axAccentGreen.opacity(0.15), Color.mint.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.axAccentGreen)
                    }
                    Text(L10n.Cerberus.DomainDetail.recentVisits)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                }

                if viewModel.selectedDomainAccessLog.isEmpty {
                    DomainEmptyMini(icon: "arrow.up.arrow.down", text: L10n.Cerberus.DomainDetail.noTraffic)
                } else {
                    ForEach(viewModel.selectedDomainAccessLog.prefix(8)) { entry in
                        recentVisitRow(entry)
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }

    func recentVisitRow(_ entry: WAFAccessLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 55)
            Text(entry.method)
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundStyle(methodColor(entry.method))
                .frame(width: 36)
            Text(entry.path)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(1)
            Spacer()
            statusPill(entry.statusCode)
        }
    }
}

// MARK: - Traffic Tab

private extension CerberusDomainDetailView {

    var trafficTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.selectedDomainAccessLog.isEmpty {
                    DomainEmptyTabState(
                        icon: "arrow.up.arrow.down",
                        title: L10n.Cerberus.DomainDetail.noTraffic,
                        color: .axAccentBlue
                    )
                } else {
                    trafficTableHeader
                    ForEach(viewModel.selectedDomainAccessLog) { entry in
                        trafficRowFull(entry)
                    }
                }
            }
        }
    }

    var trafficTableHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.PluginsUI.time).frame(width: 65, alignment: .leading)
            Text(L10n.PluginsUI.method).frame(width: 44, alignment: .leading)
            Text(L10n.PluginsUI.path).frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text("IP").frame(width: 110, alignment: .leading)
            Text(L10n.PluginsUI.status).frame(width: 50, alignment: .center)
            Text(L10n.PluginsUI.latency).frame(width: 55, alignment: .trailing)
        }
        .font(AXTypography.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(Color.axTextTertiary)
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.6))
    }

    func trafficRowFull(_ entry: WAFAccessLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 65, alignment: .leading)
            Text(entry.method)
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundStyle(methodColor(entry.method))
                .frame(width: 44, alignment: .leading)
            Text(entry.path)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(entry.ip)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 110, alignment: .leading)
            statusPill(entry.statusCode)
                .frame(width: 50)
            Text(String(format: "%.0fms", entry.latencyMs))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 55, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.axDivider.opacity(0.3)).frame(height: 1)
        }
    }
}

// MARK: - Attacks Tab

private extension CerberusDomainDetailView {

    var attacksTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.selectedDomainBlockLog.isEmpty {
                    DomainEmptyTabState(
                        icon: "checkmark.shield",
                        title: L10n.Cerberus.DomainDetail.noAttacks,
                        color: .axAccentGreen
                    )
                } else {
                    attackTableHeader
                    ForEach(viewModel.selectedDomainBlockLog) { entry in
                        attackRowFull(entry)
                    }
                }
            }
        }
    }

    var attackTableHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.PluginsUI.time).frame(width: 65, alignment: .leading)
            Text("IP").frame(width: 110, alignment: .leading)
            Text(L10n.PluginsUI.path).frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(L10n.PluginsUI.rule).frame(width: 120, alignment: .trailing)
        }
        .font(AXTypography.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(Color.axTextTertiary)
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.6))
    }

    func attackRowFull(_ entry: WAFBlockLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 65, alignment: .leading)
            Text(entry.ip)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .frame(width: 110, alignment: .leading)
            Text(entry.path)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextSecondary)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(entry.rule)
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axError)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxxs)
                .background(Color.axError.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.axDivider.opacity(0.3)).frame(height: 1)
        }
    }
}

// MARK: - Countries Tab

private extension CerberusDomainDetailView {

    var countriesTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.selectedDomainCountries.isEmpty {
                    DomainEmptyTabState(
                        icon: "globe",
                        title: L10n.Cerberus.DomainDetail.noCountries,
                        color: .axAccentBlue
                    )
                } else {
                    countriesBarChart
                    countriesFullList
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    var countriesBarChart: some View {
        let top10 = Array(viewModel.selectedDomainCountries.prefix(10))
        let codes = top10.map(\.countryCode)
        return AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.axAccentBlue)
                    Text(L10n.Cerberus.DomainDetail.topCountries)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                }

                ContinentLegendView(countryCodes: codes)

                Chart {
                    ForEach(top10, id: \.countryCode) { country in
                        let continent = WAFContinent.from(countryCode: country.countryCode)
                        BarMark(
                            x: .value("Country", "\(countryFlagEmoji( country.countryCode)) \(country.countryCode)"),
                            y: .value("Count", country.count)
                        )
                        .foregroundStyle(continent.color.opacity(0.85))
                        .cornerRadius(AXCornerRadius.xs)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(Color.axDivider.opacity(0.5))
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(DomainFormatHelper.formatNumber(v))
                                    .font(AXTypography.caption2)
                                    .foregroundStyle(Color.axTextMuted)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { AxisValueLabel().foregroundStyle(Color.axTextTertiary) }
                }
                .frame(height: 220)
            }
        }
    }

    var countriesFullList: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(viewModel.selectedDomainCountries.prefix(30), id: \.countryCode) { country in
                    countryRow(country)
                }
            }
        }
    }
}

// MARK: - Metric Card

private struct DetailMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var gradientEnd: Color = .clear
    var subtitle: String? = nil

    private var endColor: Color { gradientEnd == .clear ? color : gradientEnd }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.25), endColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, endColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.axTextPrimary)
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                if let subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.06), Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.2), endColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: color.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Empty States

private struct DomainEmptyChart: View {
    var body: some View {
        ZStack {
            // Faux grid lines
            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    Spacer()
                    Rectangle()
                        .fill(Color.axDivider.opacity(0.15))
                        .frame(height: 1)
                }
                Spacer()
            }
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { _ in
                    Spacer()
                    Rectangle()
                        .fill(Color.axDivider.opacity(0.08))
                        .frame(width: 1)
                }
                Spacer()
            }

            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.axAccentBlue.opacity(0.12), Color.axAccentBlue.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 64, height: 64)
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.axAccentBlue.opacity(0.6), .axAccentBlue.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                Text(L10n.Cerberus.DomainDetail.noTraffic)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

private struct DomainEmptyMini: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: AXSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.axTextMuted.opacity(0.06))
                    .frame(width: 44, height: 44)
                Circle()
                    .strokeBorder(Color.axTextMuted.opacity(0.1), lineWidth: 1)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.axTextMuted.opacity(0.4))
            }
            Text(text)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxl)
    }
}

private struct DomainEmptyTabState: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(color.opacity(0.06), lineWidth: 1)
                    .frame(width: 120, height: 120)
                // Middle ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.08), color.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 88, height: 88)
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            Text(title)
                .font(AXTypography.subheadline)
                .foregroundStyle(Color.axTextMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}

// MARK: - Helpers

extension CerberusDomainDetailView {

    var avgLatencyText: String {
        let entries = viewModel.selectedDomainAccessLog
        guard !entries.isEmpty else { return "—" }
        let avg = entries.map(\.latencyMs).reduce(0, +) / Double(entries.count)
        return String(format: "%.0fms", avg)
    }

    private static let isoFmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFmtBasic = ISO8601DateFormatter()
    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    func formatTime(_ iso: String) -> String {
        guard let date = Self.isoFmt.date(from: iso) ?? Self.isoFmtBasic.date(from: iso) else { return iso }
        return Self.timeFmt.string(from: date)
    }

    func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .axAccentGreen
        case "POST": return .axAccentBlue
        case "PUT", "PATCH": return .axWarning
        case "DELETE": return .axError
        default: return .axTextMuted
        }
    }

    func statusPill(_ code: Int) -> some View {
        let color: Color = switch code {
        case 200..<300: .axAccentGreen
        case 300..<400: .axAccentBlue
        case 403: .axError
        case 400..<500: .axWarning
        case 500...: .axError
        default: .axTextMuted
        }
        return Text("\(code)")
            .font(AXTypography.caption2)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
    }

}
