//
//  CerberusTrafficView.swift
//  AevonX
//
//  Traffic tab — domains, response times, status codes, bot analysis,
//  access log with filters, country visitor breakdown.
//

import SwiftUI
import Charts
import AevonXCoreBridge

struct CerberusTrafficView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @State private var selectedSection: TrafficSection = .analytics
    @State private var accessLogFilter = ""
    @State private var selectedDomainName: String?

    enum TrafficSection: String, CaseIterable {
        case analytics = "Analytics"
        case accessLog = "Access Log"
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            Divider().background(Color.axDivider)
            ScrollView {
                VStack(spacing: AXSpacing.lg) {
                    if viewModel.isLoading && viewModel.domainStats.isEmpty {
                        skeletonContent
                    } else if selectedSection == .analytics {
                        analyticsContent
                    } else {
                        accessLogContent
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .task {
            await viewModel.loadTrafficAnalytics()
            await viewModel.loadAccessLog()
        }
        .sheet(isPresented: Binding(get: { selectedDomainName != nil }, set: { if !$0 { selectedDomainName = nil } })) {
            if let domain = selectedDomainName { domainDetailSheet(domain) }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: AXSpacing.xxs) {
            ForEach(TrafficSection.allCases, id: \.self) { section in
                sectionTab(section)
            }
            Spacer()
            if selectedSection == .accessLog && !viewModel.accessLog.isEmpty {
                AXBadge(text: "\(filteredAccessLog.count) entries", color: .axAccentBlue, style: .soft)
            }
        }
        .padding(.horizontal, AXSpacing.xl).padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func sectionTab(_ section: TrafficSection) -> some View {
        let isSelected = selectedSection == section
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSection = section }
        } label: {
            VStack(spacing: AXSpacing.xxs) {
                Text(section.rawValue)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.axAccentBlue : Color.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(isSelected ? Color.axAccentBlue : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) { ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() } }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                AXCard { AXSkeletonBlock(lines: 4) }
                AXCard { AXSkeletonBlock(lines: 4) }
            }
        }
    }

    // MARK: - Analytics Content

    private var analyticsContent: some View {
        VStack(spacing: AXSpacing.lg) {
            trafficSummaryRow
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                responseTimesCard
                VStack(spacing: AXSpacing.lg) {
                    botAnalysisCard
                    statusCodesChart
                }
            }
            domainsList
        }
    }

    // MARK: - Summary Row

    private var trafficSummaryRow: some View {
        HStack(spacing: AXSpacing.md) {
            summaryStat(icon: "globe", value: "\(sortedDomains.count)", label: "Domains", color: .axAccentBlue)
            summaryStat(icon: "arrow.up.arrow.down", value: viewModel.formatNumber(totalReqs), label: "Requests", color: .axAccentGreen)
            summaryStat(icon: "clock", value: latencyLabel, label: "P95 Latency", color: .axWarning)
            summaryStat(icon: "cpu", value: botRateLabel, label: "Bot Traffic", color: .axAccentPurple)
        }
    }

    private func summaryStat(icon: String, value: String, label: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    summaryIconBox(icon: icon, color: color)
                    Spacer()
                }
                Text(value).font(AXTypography.title2).fontWeight(.bold).foregroundStyle(Color.axTextPrimary)
                Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    private func summaryIconBox(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
            Image(systemName: icon).font(AXTypography.caption).foregroundStyle(color)
        }
    }

    // MARK: - Response Times Card

    private var responseTimesCard: some View {
        AXCard(accentColor: .axWarning) {
            VStack(alignment: .leading, spacing: 0) {
                responseTimesGradientHeader
                responseTimesBody
            }
        }
    }

    private var responseTimesGradientHeader: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath").foregroundStyle(Color.axWarning)
            Text("Response Latency").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if let rt = viewModel.responseTimes {
                AXBadge(text: "\(rt.samples) samples", color: .axWarning, style: .soft)
            }
        }
        .padding(.bottom, AXSpacing.md)
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [Color.axWarning.opacity(0.15), Color.axWarning.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 3)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
            .offset(y: -AXSpacing.lg)
        }
    }

    private var responseTimesBody: some View {
        Group {
            if let rt = viewModel.responseTimes, rt.samples > 0 {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    latencyChart(rt)
                    latencyBars(rt)
                }
            } else {
                emptyBox(icon: "clock", text: "No latency data")
            }
        }
    }

    private func latencyChart(_ rt: WAFResponseTimes) -> some View {
        let data: [(String, Double, Color)] = [
            ("P50", rt.p50, .axAccentGreen),
            ("P95", rt.p95, .axWarning),
            ("P99", rt.p99, .axError),
            ("Avg", rt.avg, .axAccentBlue),
        ]
        return Chart(data, id: \.0) { label, value, color in
            BarMark(x: .value("Percentile", label), y: .value("ms", value))
                .foregroundStyle(color.opacity(0.8))
                .cornerRadius(AXCornerRadius.xs)
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(Color.axDivider.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.axTextTertiary)
            }
        }
        .chartXAxis {
            AxisMarks { AxisValueLabel().foregroundStyle(Color.axTextTertiary) }
        }
        .frame(height: 140)
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
            Text(label).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 30, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs).fill(color.opacity(0.08)).frame(height: 8)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs).fill(color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(value / max), height: 8)
                }
            }.frame(height: 8)
            Text(String(format: "%.0fms", value)).font(AXTypography.monoXs).foregroundStyle(color)
                .frame(width: 52, alignment: .trailing)
        }
    }

    // MARK: - Bot Analysis Card

    private var botAnalysisCard: some View {
        AXCard(accentColor: .axAccentPurple) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "cpu").foregroundStyle(Color.axAccentPurple)
                    Text("Bot Analysis").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                    Spacer()
                }
                if let bd = viewModel.botDetails, (bd.totalBot + bd.totalHuman) > 0 {
                    botContent(bd)
                } else {
                    emptyBox(icon: "cpu", text: "No classification data")
                }
            }
        }
    }

    private func botContent(_ bd: WAFBotDetails) -> some View {
        let progressColor: Color = bd.botRate > 50 ? .axError : bd.botRate > 20 ? .axWarning : .axAccentGreen
        return HStack(spacing: AXSpacing.xl) {
            AXCircularProgress(
                progress: min(bd.botRate / 100, 1.0),
                color: progressColor,
                size: 80, lineWidth: 7
            ) {
                Text(String(format: "%.0f%%", bd.botRate))
                    .font(AXTypography.monoSm).foregroundStyle(Color.axTextPrimary)
            }
            .shadow(color: bd.botRate > 50 ? progressColor.opacity(0.35) : Color.clear, radius: 12, y: 2)
            botLegend(bd)
        }
    }

    private func botLegend(_ bd: WAFBotDetails) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Circle().fill(Color.axAccentGreen).frame(width: 6, height: 6)
                Text("Human").font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
                Text(viewModel.formatNumber(bd.totalHuman)).font(AXTypography.monoSm).foregroundStyle(Color.axAccentGreen)
            }
            HStack(spacing: AXSpacing.sm) {
                Circle().fill(Color.axAccentPurple).frame(width: 6, height: 6)
                Text("Bot").font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
                Text(viewModel.formatNumber(bd.totalBot)).font(AXTypography.monoSm).foregroundStyle(Color.axAccentPurple)
            }
        }
    }

    // MARK: - Status Codes Chart

    private var statusCodesChart: some View {
        AXCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                statusCodesHeader
                if viewModel.statusCodes.isEmpty {
                    emptyBox(icon: "number", text: "No status code data")
                } else {
                    statusCodeBarChart
                }
            }
        }
    }

    private var statusCodesHeader: some View {
        HStack {
            Image(systemName: "number").foregroundStyle(Color.axAccentBlue)
            Text("Status Codes").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.statusCodes.isEmpty {
                AXBadge(text: "\(viewModel.statusCodes.count)", color: .axAccentBlue, style: .soft)
            }
        }
    }

    private var statusCodeBarChart: some View {
        Chart(viewModel.statusCodes.prefix(8)) { sc in
            BarMark(x: .value("Code", "\(sc.code)"), y: .value("Count", sc.count))
                .foregroundStyle(statusCodeColor(sc.code).opacity(0.8))
                .cornerRadius(AXCornerRadius.xs)
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(Color.axDivider.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.axTextTertiary)
            }
        }
        .chartXAxis { AxisMarks { AxisValueLabel().foregroundStyle(Color.axTextTertiary) } }
        .frame(height: 120)
    }

    // MARK: - Domains List

    private var domainsList: some View {
        VStack(spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: "globe").foregroundStyle(Color.axAccentBlue)
                Text("Domains").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                AXBadge(text: "\(sortedDomains.count)", color: .axAccentBlue, style: .soft)
                Spacer()
            }
            if sortedDomains.isEmpty {
                emptyBox(icon: "globe.slash", text: "No domain traffic yet")
            } else {
                domainsListRows
            }
        }
    }

    private var domainsListRows: some View {
        ForEach(Array(sortedDomains.enumerated()), id: \.element.domain) { idx, item in
            Button { selectedDomainName = item.domain } label: {
                domainCard(rank: idx + 1, domain: item.domain, stats: item.stats)
            }
            .buttonStyle(.plain)
        }
    }

    private func domainCard(rank: Int, domain: String, stats: DomainStats) -> some View {
        let blockedRate = stats.totalRequests > 0 ? Double(stats.blockedRequests) / Double(stats.totalRequests) : 0
        let protRate = 1.0 - blockedRate
        let accent: Color = blockedRate > 0.3 ? .axError : blockedRate > 0.1 ? .axWarning : .axAccentGreen
        return AXCard(accentColor: accent) {
            HStack(spacing: AXSpacing.lg) {
                domainRankColumn(rank: rank, protRate: protRate, accent: accent)
                domainCardBody(domain: domain, stats: stats, blockedRate: blockedRate)
            }
        }
        .overlay(alignment: .leading) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(accent)
                    .frame(width: 3)
                    .padding(.vertical, AXSpacing.xs)
                Spacer()
            }
        }
    }

    private func domainRankColumn(rank: Int, protRate: Double, accent: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            AXCircularProgress(progress: protRate, color: accent, size: 48, lineWidth: 5) {
                Text(String(format: "%.0f%%", protRate * 100)).font(AXTypography.monoXs).foregroundStyle(accent)
            }
            rankBadge(rank)
        }
        .frame(width: 56)
    }

    private func rankBadge(_ rank: Int) -> some View {
        let color: Color = rank == 1 ? .yellow : rank == 2 ? .gray : rank == 3 ? .orange : .axTextMuted
        let bg: Color = rank <= 3 ? color.opacity(0.15) : Color.clear
        return Text("#\(rank)")
            .font(AXTypography.monoXs)
            .fontWeight(rank <= 3 ? .bold : .regular)
            .foregroundStyle(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(bg))
    }

    private func domainCardBody(domain: String, stats: DomainStats, blockedRate: Double) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text(domain).font(AXTypography.monoMd).foregroundStyle(Color.axTextPrimary).lineLimit(1)
                Spacer()
                AXBadge(text: viewModel.formatNumber(stats.totalRequests) + " req", color: .axAccentBlue, style: .soft)
                Image(systemName: "chevron.right").font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }
            domainProgressBar(blockedRate: blockedRate)
            domainStatChips(stats: stats)
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
            }.frame(height: 6)
            domainProgressLabels(blockedRate: blockedRate)
        }
    }

    private func domainProgressLabels(blockedRate: Double) -> some View {
        HStack {
            Text(String(format: "%.1f%% blocked", blockedRate * 100))
                .font(AXTypography.caption).foregroundStyle(blockedRate > 0.1 ? Color.axError : Color.axTextMuted)
            Spacer()
            Text(String(format: "%.1f%% allowed", (1 - blockedRate) * 100))
                .font(AXTypography.caption).foregroundStyle(Color.axAccentGreen)
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

    // MARK: - Domain Detail Sheet

    private func domainDetailSheet(_ domain: String) -> some View {
        let stats = viewModel.domainStats[domain]
        let blockedRate = (stats?.totalRequests ?? 0) > 0
            ? Double(stats?.blockedRequests ?? 0) / Double(stats?.totalRequests ?? 1) : 0
        return VStack(spacing: 0) {
            domainDetailHero(domain)
            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
            if let stats = stats {
                domainDetailStatsRow(stats, blockedRate: blockedRate)
                Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
                domainDetailAccessLog(domain)
            }
            Spacer(minLength: 0)
            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
            domainDetailFooter
        }
        .frame(width: 660, height: 500)
        .background(Color.axBackground)
    }

    private func domainDetailHero(_ domain: String) -> some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.04)], center: .center, startRadius: 0, endRadius: 24))
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
                    .frame(width: 44, height: 44)
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.axAccentBlue)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(domain)
                    .font(AXTypography.monoMd)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text("Domain Traffic Analysis")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            Spacer()
            Button { selectedDomainName = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
        .background(LinearGradient(colors: [Color.axAccentBlue.opacity(0.04), Color.clear], startPoint: .leading, endPoint: .trailing))
    }

    private func domainDetailStatsRow(_ stats: DomainStats, blockedRate: Double) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            domainMiniStat("Total", viewModel.formatNumber(stats.totalRequests), "arrow.up.arrow.down", .axAccentBlue)
            domainMiniStat("Blocked", viewModel.formatNumber(stats.blockedRequests), "hand.raised.fill", .axError)
            domainMiniStat("Block Rate", String(format: "%.1f%%", blockedRate * 100), "chart.pie.fill", blockedRate > 0.1 ? .axError : .axAccentGreen)
            domainMiniStat("Bytes In", viewModel.formatBytes(stats.bytesIn), "arrow.down.circle.fill", .axAccentBlue)
            domainMiniStat("Bytes Out", viewModel.formatBytes(stats.bytesOut), "arrow.up.circle.fill", .axAccentPurple)
        }
        .padding(AXSpacing.md)
    }

    private func domainMiniStat(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(value)
                .font(AXTypography.monoSm)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(color.opacity(0.04)))
    }

    private func domainDetailAccessLog(_ domain: String) -> some View {
        let entries = viewModel.accessLog.filter { $0.host == domain }.prefix(20)
        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.axAccentBlue)
                Text("Recent Requests")
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextPrimary)
                Spacer()
                Text("\(entries.count) entries")
                    .font(AXTypography.caption2)
                    .foregroundStyle(Color.axTextMuted)
            }
            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AXSpacing.sm) {
                        Image(systemName: "doc.text").font(AXTypography.title3).foregroundStyle(Color.axTextMuted)
                        Text("No access log entries").font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
                    }
                    .padding(.vertical, AXSpacing.lg)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.xxxs) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                            domainLogRow(entry, isEven: idx.isMultiple(of: 2))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }

    private func domainLogRow(_ entry: WAFAccessLogEntry, isEven: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp)).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 60)
            Text(entry.method).font(AXTypography.monoXs).fontWeight(.medium).foregroundStyle(methodColor(entry.method)).frame(width: 40)
            Text(entry.path).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary).lineLimit(1)
            Spacer()
            Text("\(entry.statusCode)").font(AXTypography.monoXs).foregroundStyle(statusCodeColor(entry.statusCode))
            Text(String(format: "%.0fms", entry.latencyMs)).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted)
        }
        .padding(.vertical, AXSpacing.xxs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.xs).fill(isEven ? Color.axSurfaceHover.opacity(0.2) : Color.clear))
    }

    private var domainDetailFooter: some View {
        HStack {
            Spacer()
            Button { selectedDomainName = nil } label: {
                Text("Close")
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextSecondary)
                    .padding(.horizontal, AXSpacing.xxxl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).strokeBorder(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(AXSpacing.md)
    }

    // MARK: - Access Log Content

    private var accessLogContent: some View {
        VStack(spacing: AXSpacing.md) {
            accessLogFilterBar
            accessLogSummary
            accessLogTable
        }
    }

    private var accessLogFilterBar: some View {
        HStack(spacing: AXSpacing.md) {
            AXTextField(placeholder: "Filter by IP, path, host, country...", text: $accessLogFilter, icon: "magnifyingglass")
            Button { Task { await viewModel.loadAccessLog() } } label: {
                Image(systemName: "arrow.clockwise").font(AXTypography.caption).foregroundStyle(Color.axAccentBlue)
                    .padding(AXSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axAccentBlue.opacity(0.1)))
            }.buttonStyle(.plain)
        }
    }

    private var accessLogSummary: some View {
        let entries = filteredAccessLog
        let botCount = entries.filter(\.isBot).count
        let avgLatency = entries.isEmpty ? 0.0 : entries.reduce(0.0) { $0 + $1.latencyMs } / Double(entries.count)
        let uniqueIPs = Set(entries.map(\.ip)).count
        return HStack(spacing: AXSpacing.md) {
            logSummaryCard(label: "Requests", value: "\(entries.count)", icon: "arrow.up.arrow.down", color: .axAccentBlue)
            logSummaryCard(label: "Unique IPs", value: "\(uniqueIPs)", icon: "person.2.fill", color: .axAccentGreen)
            logSummaryCard(label: "Bots", value: "\(botCount)", icon: "cpu.fill", color: .axWarning)
            logSummaryCard(label: "Avg Latency", value: String(format: "%.0fms", avgLatency), icon: "clock.fill", color: .axAccentPurple)
        }
    }

    private func logSummaryCard(label: String, value: String, icon: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            HStack(spacing: AXSpacing.md) {
                summaryIconBox(icon: icon, color: color)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(value).font(AXTypography.title3).fontWeight(.bold).foregroundStyle(Color.axTextPrimary)
                    Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
                }
                Spacer()
            }
        }
    }

    private var accessLogTable: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                accessLogTableHeader
                if filteredAccessLog.isEmpty {
                    emptyBox(icon: "doc.text", text: "No access log entries")
                } else {
                    accessLogRows
                }
            }
        }
    }

    private var accessLogTableHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text("Time").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 70)
            Text("IP").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 115, alignment: .leading)
            Text("").frame(width: 25)
            Text("Method").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 50)
            Text("Host").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 120, alignment: .leading)
            Text("Path").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(maxWidth: .infinity, alignment: .leading)
            Text("Status").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 45)
            Text("Latency").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 55)
            Text("Bot").font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 30)
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xs)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface))
    }

    private var accessLogRows: some View {
        ForEach(Array(filteredAccessLog.prefix(100).enumerated()), id: \.element.id) { idx, entry in
            accessLogRow(entry: entry, isEven: idx.isMultiple(of: 2))
        }
    }

    private func accessLogRow(entry: WAFAccessLogEntry, isEven: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp)).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 70)
            Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(entry.ip) : entry.ip).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary).frame(width: 115, alignment: .leading).lineLimit(1)
            Text(flagEmoji(for: entry.countryCode)).frame(width: 25)
            Text(entry.method).font(AXTypography.monoXs).foregroundStyle(methodColor(entry.method)).frame(width: 50)
            Text(settings.maskServerInfo && settings.maskInDashboard ? PrivacyMask.hostname(entry.host) : entry.host).font(AXTypography.monoXs).foregroundStyle(Color.axTextSecondary).frame(width: 120, alignment: .leading).lineLimit(1)
            Text(entry.path).font(AXTypography.monoXs).foregroundStyle(Color.axTextSecondary).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            Text("\(entry.statusCode)").font(AXTypography.monoXs).foregroundStyle(statusCodeColor(entry.statusCode)).frame(width: 45)
            Text(String(format: "%.0fms", entry.latencyMs)).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 55)
            Image(systemName: entry.isBot ? "cpu" : "person.fill")
                .font(.system(size: 9)).foregroundStyle(entry.isBot ? Color.axWarning : Color.axAccentGreen).frame(width: 30)
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.xs)
            .fill(isEven ? Color.axSurfaceHover.opacity(0.2) : Color.axSurfaceHover.opacity(0.05)))
    }

    // MARK: - Helpers

    private var sortedDomains: [(domain: String, stats: DomainStats)] {
        viewModel.domainStats.map { (domain: $0.key, stats: $0.value) }
            .sorted { $0.stats.totalRequests > $1.stats.totalRequests }
    }

    private var totalReqs: Int { sortedDomains.reduce(0) { $0 + $1.stats.totalRequests } }

    private var latencyLabel: String {
        guard let rt = viewModel.responseTimes, rt.samples > 0 else { return "---" }
        return String(format: "%.0fms", rt.p95)
    }

    private var botRateLabel: String {
        guard let bd = viewModel.botDetails else { return "---" }
        return String(format: "%.1f%%", bd.botRate)
    }

    private var filteredAccessLog: [WAFAccessLogEntry] {
        guard !accessLogFilter.isEmpty else { return viewModel.accessLog }
        let q = accessLogFilter.lowercased()
        return viewModel.accessLog.filter {
            $0.ip.lowercased().contains(q) || $0.path.lowercased().contains(q) ||
            $0.host.lowercased().contains(q) || $0.country.lowercased().contains(q)
        }
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

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .axAccentGreen
        case "POST": return .axAccentBlue
        case "PUT", "PATCH": return .axWarning
        case "DELETE": return .axError
        default: return .axTextMuted
        }
    }

    private func emptyBox(icon: String, text: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon).font(AXTypography.title2).foregroundStyle(Color.axTextMuted)
                Text(text).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }.padding(.vertical, AXSpacing.xl)
            Spacer()
        }
    }

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in code.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { flag.append(String(s)) }
        }
        return flag.isEmpty ? "🏳️" : flag
    }

    private func formatTime(_ ts: String) -> String {
        guard ts.count >= 19 else { return ts }
        return String(ts.suffix(from: ts.index(ts.startIndex, offsetBy: 11)).prefix(8))
    }
}
