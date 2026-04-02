//
//  CerberusDomainDetailView.swift
//  AevonX
//
//  Domain detail sheet — overview stats, filtered traffic,
//  filtered attacks, and country breakdown for a single domain.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusDomainDetailView: View {
    @ObservedObject var viewModel: CerberusViewModel
    let domain: WAFDomainInfo
    @State private var selectedTab: DomainDetailTab = .overview

    var body: some View {
        VStack(spacing: 0) {
            domainDetailHeader
            Divider().background(Color.axDivider)
            tabPicker
            Divider().background(Color.axDivider)
            tabContent
        }
        .frame(width: 700, height: 550)
        .background(Color.axBackground)
    }
}

// MARK: - Tab

private enum DomainDetailTab: String, CaseIterable {
    case overview, traffic, attacks, countries

    var label: String {
        switch self {
        case .overview:  return L10n.Cerberus.DomainDetail.tabOverview
        case .traffic:   return L10n.Cerberus.DomainDetail.tabTraffic
        case .attacks:   return L10n.Cerberus.DomainDetail.tabAttacks
        case .countries: return L10n.Cerberus.DomainDetail.tabCountries
        }
    }

    var icon: String {
        switch self {
        case .overview:  return "chart.bar.xaxis"
        case .traffic:   return "arrow.up.arrow.down"
        case .attacks:   return "exclamationmark.triangle"
        case .countries: return "globe"
        }
    }
}

// MARK: - Header

private extension CerberusDomainDetailView {

    var domainDetailHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(domain.enabled ? Color.axAccentGreen.opacity(0.12) : Color.axTextMuted.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: domain.enabled ? "checkmark.shield.fill" : "shield.slash")
                    .font(AXTypography.headline)
                    .foregroundStyle(domain.enabled ? Color.axAccentGreen : Color.axTextMuted)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(domain.domain)
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.xs) {
                    AXStatusBadge(
                        status: domain.enabled ? .online : .offline,
                        showLabel: true,
                        enablePulseAnimation: domain.enabled
                    )
                    if !domain.webServer.isEmpty {
                        Text(domain.webServer)
                            .font(AXTypography.caption2)
                            .foregroundStyle(Color.axTextTertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }

    var tabPicker: some View {
        HStack(spacing: AXSpacing.sm) {
            ForEach(DomainDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11))
                        Text(tab.label)
                            .font(AXTypography.caption)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.axAccentBlue : Color.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(selectedTab == tab ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
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
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Overview

private extension CerberusDomainDetailView {

    var overviewTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                overviewMetrics
                overviewSummary
            }
            .padding(AXSpacing.xl)
        }
    }

    var overviewMetrics: some View {
        HStack(spacing: AXSpacing.md) {
            metricCard(
                title: L10n.Cerberus.DomainDetail.requests,
                value: "\(domainTraffic.count)",
                icon: "arrow.up.arrow.down",
                color: .axAccentBlue
            )
            metricCard(
                title: L10n.Cerberus.DomainDetail.blocked,
                value: "\(domainBlocked.count)",
                icon: "hand.raised.fill",
                color: .axError
            )
            metricCard(
                title: L10n.Cerberus.DomainDetail.blockRate,
                value: blockRateText,
                icon: "shield.checkered",
                color: .axWarning
            )
            metricCard(
                title: L10n.Cerberus.DomainDetail.avgLatency,
                value: domainAvgLatency,
                icon: "timer",
                color: .axAccentGreen
            )
        }
    }

    func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(AXTypography.subheadline)
                    .foregroundStyle(color)
                Text(value)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    var overviewSummary: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text(L10n.Cerberus.DomainDetail.topPaths)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextPrimary)

                if topPaths.isEmpty {
                    Text("—")
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextMuted)
                } else {
                    ForEach(topPaths.prefix(8), id: \.path) { entry in
                        HStack {
                            Text(entry.path)
                                .font(AXTypography.monoSm)
                                .foregroundStyle(Color.axTextPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(entry.count)")
                                .font(AXTypography.monoSm)
                                .foregroundStyle(Color.axTextTertiary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Traffic Tab

private extension CerberusDomainDetailView {

    var trafficTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if domainTraffic.isEmpty {
                    emptyTabState(icon: "arrow.up.arrow.down", text: L10n.Cerberus.DomainDetail.noTraffic)
                } else {
                    ForEach(domainTraffic) { entry in
                        trafficRow(entry)
                        Divider().background(Color.axDivider.opacity(0.5))
                    }
                }
            }
        }
    }

    func trafficRow(_ entry: WAFAccessLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 65)
            Text(entry.method)
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(methodColor(entry.method))
                .frame(width: 40)
            Text(entry.path)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(1)
            Spacer()
            statusPill(entry.statusCode)
            Text(String(format: "%.0fms", entry.latencyMs))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.xs)
    }
}

// MARK: - Attacks Tab

private extension CerberusDomainDetailView {

    var attacksTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if domainBlocked.isEmpty {
                    emptyTabState(icon: "checkmark.shield", text: L10n.Cerberus.DomainDetail.noAttacks)
                } else {
                    ForEach(domainBlocked) { entry in
                        attackRow(entry)
                        Divider().background(Color.axDivider.opacity(0.5))
                    }
                }
            }
        }
    }

    func attackRow(_ entry: WAFBlockLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp))
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 65)
            Text(entry.ip)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .frame(width: 110)
            Text(entry.path)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextSecondary)
                .lineLimit(1)
            Spacer()
            Text(entry.rule)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axError)
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, AXSpacing.xxxs)
                .background(Color.axError.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.xs)
    }
}

// MARK: - Countries Tab

private extension CerberusDomainDetailView {

    var countriesTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.md) {
                if domainCountries.isEmpty {
                    emptyTabState(icon: "globe", text: L10n.Cerberus.DomainDetail.noCountries)
                } else {
                    ForEach(domainCountries.prefix(30), id: \.code) { country in
                        countryRow(country)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    func countryRow(_ country: DomainCountryEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(flagEmoji(for: country.code))
                .font(.system(size: 16))
            Text(country.code)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .frame(width: 30)
            // Bar
            GeometryReader { geo in
                let maxWidth = geo.size.width
                let ratio = domainCountries.first.map { Double(country.count) / Double($0.count) } ?? 0
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(Color.axAccentBlue.opacity(0.3))
                    .frame(width: maxWidth * ratio)
            }
            .frame(height: 16)
            Text("\(country.count)")
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - Helpers

private extension CerberusDomainDetailView {

    var domainTraffic: [WAFAccessLogEntry] {
        viewModel.accessLog.filter { $0.host == domain.domain }
    }

    var domainBlocked: [WAFBlockLogEntry] {
        viewModel.blockLog.filter { $0.host == domain.domain }
    }

    var blockRateText: String {
        let total = domainTraffic.count
        guard total > 0 else { return "0%" }
        let rate = Double(domainBlocked.count) / Double(total) * 100
        return String(format: "%.1f%%", rate)
    }

    var domainAvgLatency: String {
        let entries = domainTraffic
        guard !entries.isEmpty else { return "—" }
        let avg = entries.map(\.latencyMs).reduce(0, +) / Double(entries.count)
        return String(format: "%.0fms", avg)
    }

    struct PathCount: Hashable {
        let path: String
        let count: Int
    }

    var topPaths: [PathCount] {
        var counts: [String: Int] = [:]
        for entry in domainTraffic {
            counts[entry.path, default: 0] += 1
        }
        return counts.map { PathCount(path: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    struct DomainCountryEntry {
        let code: String
        let count: Int
    }

    var domainCountries: [DomainCountryEntry] {
        var counts: [String: Int] = [:]
        for entry in domainTraffic where !entry.countryCode.isEmpty {
            counts[entry.countryCode, default: 0] += 1
        }
        return counts.map { DomainCountryEntry(code: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func emptyTabState(icon: String, text: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(Color.axTextMuted)
            Text(text)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AXSpacing.xxxl)
    }

    func formatTime(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateFormat = "HH:mm:ss"
        return display.string(from: date)
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
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
    }

    func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { flag.append(String(s)) }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}
