//
//  CerberusAlertsView.swift
//  AevonX
//
//  Alerts tab — real-time security event feed with severity triage.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusAlertsView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var severityFilter: String = "all"
    @State private var selectedAlert: WAFAlertEvent?
    @State private var alertPage = 0
    private let alertPageSize = 50

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.alertsLoading && viewModel.recentAlerts.isEmpty {
                    alertsSkeletonContent
                } else {
                    alertsHero
                    severityStatsRow
                    filterToolbar
                    alertsFeedSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadAlerts() }
        .onChange(of: severityFilter) { _ in alertPage = 0 }
        .sheet(item: $selectedAlert) { alertDetailSheet($0) }
    }
}

// MARK: - Skeleton

private extension CerberusAlertsView {

    var alertsSkeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
            AXCard { AXSkeletonBlock(lines: 8) }
        }
    }
}

// MARK: - Hero

private extension CerberusAlertsView {

    var alertsHero: some View {
        AXGlassCard(accentColor: heroAccentColor) {
            HStack(spacing: AXSpacing.xl) {
                alertsHeroLeft
                Spacer()
                alertsHeroRight
            }
        }
    }

    var alertsHeroLeft: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [heroAccentColor.opacity(0.25), heroAccentColor.opacity(0.05)],
                            center: .center, startRadius: 0, endRadius: 26
                        )
                    )
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(heroAccentColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: "bell.badge.fill")
                    .font(AXTypography.title3)
                    .foregroundStyle(heroAccentColor)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Cerberus.Alerts.title)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text(L10n.Cerberus.Alerts.subtitle)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                    if !viewModel.recentAlerts.isEmpty {
                        AXBadge(
                            text: L10n.Cerberus.Badge.events(viewModel.recentAlerts.count),
                            color: heroAccentColor, style: .soft
                        )
                    }
                }
            }
        }
    }

    var alertsHeroRight: some View {
        HStack(spacing: AXSpacing.xxl) {
            heroMiniStat(
                value: "\(countBySeverity("critical"))",
                label: L10n.Cerberus.Alerts.critical, color: .axError
            )
            heroMiniStat(
                value: "\(countBySeverity("high"))",
                label: L10n.Cerberus.Alerts.high, color: .axWarning
            )
            heroMiniStat(
                value: "\(countBySeverity("medium") + countBySeverity("low"))",
                label: L10n.Cerberus.Alerts.other, color: .axAccentBlue
            )
            refreshBtn
        }
    }

    func heroMiniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    var refreshBtn: some View {
        Button {
            Task { await viewModel.loadAlerts() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axAccentBlue)
                .frame(width: 32, height: 32)
                .background(Color.axAccentBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Row

private extension CerberusAlertsView {

    var severityStatsRow: some View {
        HStack(spacing: AXSpacing.md) {
            severityStatCard(
                icon: "bell.badge", value: "\(viewModel.recentAlerts.count)",
                label: L10n.Cerberus.Alerts.totalAlerts, color: .axAccentBlue
            )
            severityStatCard(
                icon: "exclamationmark.octagon.fill",
                value: "\(countBySeverity("critical"))",
                label: L10n.Cerberus.Alerts.critical, color: .axError
            )
            severityStatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(countBySeverity("high"))",
                label: L10n.Cerberus.Alerts.high, color: .axWarning
            )
            severityStatCard(
                icon: "info.circle.fill",
                value: "\(countBySeverity("medium") + countBySeverity("low"))",
                label: L10n.Cerberus.Alerts.mediumLow, color: .axAccentGreen
            )
        }
    }

    func severityStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(color.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundStyle(color)
                    }
                    Spacer()
                }
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }
}

// MARK: - Filter Toolbar

private extension CerberusAlertsView {

    var filterToolbar: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
            ForEach(["all", "critical", "high", "medium", "low"], id: \.self) { sev in
                filterChip(sev, label: L10n.Cerberus.Alerts.filterLabel(for: sev))
            }
            Spacer()
            Text(L10n.Cerberus.Badge.events(filteredAlerts.count))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    func filterChip(_ sev: String, label: String) -> some View {
        let isSelected = severityFilter == sev
        let chipColor = severityColor(sev)
        return Button { severityFilter = sev } label: {
            Text(label)
                .font(AXTypography.monoXs)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.axTextPrimary : Color.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? chipColor.opacity(0.15) : Color.axSurface.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(isSelected ? chipColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feed Section

private extension CerberusAlertsView {

    var alertsFeedSection: some View {
        AXCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                feedHeader
                if filteredAlerts.isEmpty {
                    alertsEmptyState
                } else {
                    alertFeedRows
                }
            }
        }
    }

    var feedHeader: some View {
        HStack {
            Image(systemName: "bell.badge")
                .foregroundStyle(Color.axAccentBlue)
            Text(L10n.Cerberus.Alerts.securityEvents)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: L10n.Cerberus.Badge.events(filteredAlerts.count), color: .axAccentBlue, style: .soft)
        }
    }

    var alertsEmptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.axAccentGreen.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.axAccentGreen)
                }
                Text(L10n.Cerberus.Alerts.allClear)
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
                Text(L10n.Cerberus.Alerts.noEventsDesc)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            .padding(.vertical, AXSpacing.xxxl)
            Spacer()
        }
    }

    private var paginatedAlerts: [WAFAlertEvent] {
        let start = alertPage * alertPageSize
        let end = min(start + alertPageSize, filteredAlerts.count)
        guard start < end else { return [] }
        return Array(filteredAlerts[start..<end])
    }

    private var alertTotalPages: Int {
        max(1, (filteredAlerts.count + alertPageSize - 1) / alertPageSize)
    }

    var alertFeedRows: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(paginatedAlerts) { alert in
                Button { selectedAlert = alert } label: {
                    alertRowContent(alert)
                }
                .buttonStyle(.plain)
            }
            if filteredAlerts.count > alertPageSize {
                alertPaginationBar
            }
        }
    }

    private var alertPaginationBar: some View {
        HStack(spacing: AXSpacing.md) {
            Text(L10n.Cerberus.Pagination.showing(
                alertPage * alertPageSize + 1,
                min((alertPage + 1) * alertPageSize, filteredAlerts.count),
                filteredAlerts.count
            ))
            .font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            Spacer()
            HStack(spacing: AXSpacing.xs) {
                alertPageBtn(icon: "chevron.left", action: { alertPage -= 1 }, disabled: alertPage == 0)
                Text(L10n.Cerberus.Pagination.page(alertPage + 1, alertTotalPages))
                    .font(AXTypography.monoSm).foregroundStyle(Color.axTextSecondary)
                alertPageBtn(icon: "chevron.right", action: { alertPage += 1 }, disabled: alertPage >= alertTotalPages - 1)
            }
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func alertPageBtn(icon: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(disabled ? Color.axTextMuted.opacity(0.4) : Color.axAccentBlue)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface))
        }
        .buttonStyle(.plain).disabled(disabled)
    }

    func alertRowContent(_ alert: WAFAlertEvent) -> some View {
        let color = severityColor(alert.severity)
        return HStack(spacing: AXSpacing.md) {
            alertRowIcon(alert, color: color)
            alertRowText(alert, color: color)
            Spacer()
            Text(formatTimestamp(alert.timestamp))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
            Image(systemName: "chevron.right")
                .font(.system(size: 9))
                .foregroundStyle(Color.axTextMuted)
        }
        .padding(.vertical, AXSpacing.sm)
        .padding(.horizontal, AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurfaceHover.opacity(0.4))
                .overlay(
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.6))
                            .frame(width: 3)
                        Spacer()
                    }
                )
        )
    }

    func alertRowIcon(_ alert: WAFAlertEvent, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(color.opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: eventTypeIcon(alert.type))
                .font(AXTypography.caption)
                .foregroundStyle(color)
        }
    }

    func alertRowText(_ alert: WAFAlertEvent, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            HStack(spacing: AXSpacing.xs) {
                Text(L10n.Cerberus.Alerts.alertTypeDisplay(alert.type))
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextPrimary)
                AXBadge(text: L10n.Cerberus.Alerts.filterLabel(for: alert.severity), color: color, style: .soft)
            }
            Text(alert.message)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Detail Sheet

private extension CerberusAlertsView {

    func alertDetailSheet(_ alert: WAFAlertEvent) -> some View {
        let accent = severityColor(alert.severity)
        return VStack(spacing: 0) {
            // Hero header
            alertSheetHero(alert, accent: accent)

            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)

            // Message card
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text(L10n.Cerberus.Alerts.message)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextTertiary)
                Text(alert.message)
                    .font(AXTypography.body)
                    .foregroundStyle(Color.axTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AXSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(0.03))

            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)

            // Details
            ScrollView {
                VStack(spacing: AXSpacing.xxs) {
                    alertDetailField(label: L10n.Cerberus.Alerts.type, value: L10n.Cerberus.Alerts.alertTypeDisplay(alert.type), icon: "tag.fill", color: accent)
                    alertDetailField(label: L10n.Cerberus.Alerts.severity, value: L10n.Cerberus.Alerts.filterLabel(for: alert.severity), icon: "exclamationmark.triangle.fill", color: accent)
                    alertDetailField(label: L10n.Cerberus.Alerts.timestamp, value: alert.timestamp, icon: "clock.fill", color: .axAccentBlue)
                    if let details = alert.details {
                        ForEach(details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            alertDetailField(label: key.replacingOccurrences(of: "_", with: " ").capitalized, value: value, icon: "info.circle.fill", color: .axAccentPurple)
                        }
                    }
                }
                .padding(AXSpacing.lg)
            }

            // Close button
            HStack {
                Spacer()
                Button { selectedAlert = nil } label: {
                    Text(L10n.Button.close)
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
            .padding(AXSpacing.lg)
        }
        .frame(minWidth: 420, idealWidth: 500, maxWidth: 600, minHeight: 400, idealHeight: 480, maxHeight: 580)
        .background(Color.axBackground)
    }

    func alertSheetHero(_ alert: WAFAlertEvent, accent: Color) -> some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [accent.opacity(0.2), accent.opacity(0.04)], center: .center, startRadius: 0, endRadius: 26))
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(accent.opacity(0.2), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: eventTypeIcon(alert.type))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Cerberus.Alerts.alertTypeDisplay(alert.type))
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    AXBadge(text: L10n.Cerberus.Alerts.filterLabel(for: alert.severity), color: accent, style: .soft)
                    Text(formatTimestamp(alert.timestamp))
                        .font(AXTypography.monoXs)
                        .foregroundStyle(Color.axTextMuted)
                }
            }
            Spacer()
            Button { selectedAlert = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
        .background(
            LinearGradient(colors: [accent.opacity(0.04), Color.clear], startPoint: .leading, endPoint: .trailing)
        )
    }

    func alertDetailField(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color.opacity(0.6))
                .frame(width: 18)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.vertical, AXSpacing.sm)
        .padding(.horizontal, AXSpacing.md)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.3)))
    }
}

// MARK: - Helpers

private extension CerberusAlertsView {

    var filteredAlerts: [WAFAlertEvent] {
        guard severityFilter != "all" else { return viewModel.recentAlerts }
        return viewModel.recentAlerts.filter { $0.severity == severityFilter }
    }

    var heroAccentColor: Color {
        let critCount = countBySeverity("critical")
        if critCount > 0 { return .axError }
        let highCount = countBySeverity("high")
        if highCount > 0 { return .axWarning }
        if viewModel.recentAlerts.isEmpty { return .axAccentGreen }
        return .axAccentBlue
    }

    func countBySeverity(_ sev: String) -> Int {
        viewModel.recentAlerts.filter { $0.severity == sev }.count
    }

    func severityColor(_ sev: String) -> Color {
        switch sev {
        case "critical": return .axError
        case "high":     return .axWarning
        case "medium":   return .axAccentBlue
        case "low":      return .axAccentGreen
        default:         return .axAccentBlue
        }
    }

    func eventTypeIcon(_ type: String) -> String {
        switch type {
        case "waf_block":          return "shield.slash"
        case "ip_blocked":         return "hand.raised.fill"
        case "ddos_detected":      return "bolt.shield"
        case "honeypot_triggered": return "ant"
        case "credential_attack":  return "key.fill"
        case "dlp_event":          return "doc.text.magnifyingglass"
        case "auto_rule":          return "gearshape.circle"
        default:                   return "bell.badge"
        }
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

    func formatTimestamp(_ iso: String) -> String {
        guard let date = Self.isoFmt.date(from: iso) ?? Self.isoFmtBasic.date(from: iso) else { return iso }
        return Self.timeFmt.string(from: date)
    }
}
