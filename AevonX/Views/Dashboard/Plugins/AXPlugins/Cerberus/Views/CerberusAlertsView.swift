//
//  CerberusAlertsView.swift
//  AevonX
//
//  Alerts tab — real-time security event feed with severity filtering.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusAlertsView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var severityFilter: String = "all"
    @State private var selectedAlert: WAFAlertEvent?

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.isLoading && viewModel.recentAlerts.isEmpty {
                    skeletonContent
                } else {
                    alertsSummaryRow
                    filterBar
                    alertsFeed
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadAlerts() }
        .sheet(item: $selectedAlert) { alertDetailSheet($0) }
    }

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
            AXCard { AXSkeletonBlock(lines: 8) }
        }
    }

    // MARK: - Summary Row

    private var alertsSummaryRow: some View {
        HStack(spacing: AXSpacing.md) {
            alertSummaryStat(icon: "bell.badge", value: "\(viewModel.recentAlerts.count)", label: "Total Alerts", color: .axAccentBlue)
            alertSummaryStat(icon: "exclamationmark.octagon", value: "\(countBySeverity("critical"))", label: "Critical", color: .axError)
            alertSummaryStat(icon: "exclamationmark.triangle", value: "\(countBySeverity("high"))", label: "High", color: .axWarning)
            alertSummaryStat(icon: "info.circle", value: "\(countBySeverity("medium") + countBySeverity("low"))", label: "Medium/Low", color: .axAccentGreen)
        }
    }

    private func alertSummaryStat(icon: String, value: String, label: String, color: Color) -> some View {
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(Color.axTextMuted)
            ForEach(["all", "critical", "high", "medium", "low"], id: \.self) { sev in
                filterChip(sev)
            }
            Spacer()
            Button {
                Task { await viewModel.loadAlerts() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(AXTypography.caption)
                .foregroundStyle(Color.axAccentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    private func filterChip(_ sev: String) -> some View {
        let isSelected = severityFilter == sev
        return Button {
            severityFilter = sev
        } label: {
            Text(sev.capitalized)
                .font(AXTypography.monoXs)
                .foregroundStyle(isSelected ? Color.axTextPrimary : Color.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? severityColor(sev).opacity(0.15) : Color.axSurface.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alerts Feed

    private var alertsFeed: some View {
        AXCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(Color.axAccentBlue)
                    Text("Security Events")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    AXBadge(text: "\(filteredAlerts.count) events", color: .axAccentBlue, style: .soft)
                }
                if filteredAlerts.isEmpty {
                    alertsEmptyState
                } else {
                    alertRows
                }
            }
        }
    }

    private var alertsEmptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: "checkmark.shield")
                    .font(AXTypography.title2)
                    .foregroundStyle(Color.axAccentGreen)
                Text("No security events")
                    .font(AXTypography.subheadline)
                    .foregroundStyle(Color.axTextSecondary)
                Text("Everything is quiet. Alerts appear when the WAF detects threats.")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, AXSpacing.xxxl)
            Spacer()
        }
    }

    private var alertRows: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(Array(filteredAlerts.enumerated()), id: \.element.id) { _, alert in
                Button { selectedAlert = alert } label: {
                    alertRow(alert)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func alertRow(_ alert: WAFAlertEvent) -> some View {
        let color = severityColor(alert.severity)
        return HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: eventTypeIcon(alert.type))
                    .font(AXTypography.caption)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(alert.type.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(AXTypography.subheadline)
                        .foregroundStyle(Color.axTextPrimary)
                    AXBadge(text: alert.severity.capitalized, color: color, style: .soft)
                }
                Text(alert.message)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatTimestamp(alert.timestamp))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurfaceHover.opacity(0.5))
        )
    }

    // MARK: - Detail Sheet

    private func alertDetailSheet(_ alert: WAFAlertEvent) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            alertDetailHeader(alert)
            alertDetailBody(alert)
            Spacer()
        }
        .padding(AXSpacing.xl)
        .frame(width: 460, height: 360)
        .background(Color.axBackground)
    }

    private func alertDetailHeader(_ alert: WAFAlertEvent) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(severityColor(alert.severity).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: eventTypeIcon(alert.type))
                    .font(AXTypography.headline)
                    .foregroundStyle(severityColor(alert.severity))
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(alert.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    AXBadge(text: alert.severity.capitalized, color: severityColor(alert.severity), style: .soft)
                    Text(formatTimestamp(alert.timestamp))
                        .font(AXTypography.monoXs)
                        .foregroundStyle(Color.axTextMuted)
                }
            }
            Spacer()
            Button { selectedAlert = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private func alertDetailBody(_ alert: WAFAlertEvent) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            detailRow("Message", alert.message)
            detailRow("Type", alert.type)
            detailRow("Severity", alert.severity.capitalized)
            detailRow("Timestamp", alert.timestamp)
            if let details = alert.details {
                ForEach(details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    detailRow(key.capitalized, value)
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface.opacity(0.5)))
    }

    // MARK: - Helpers

    private var filteredAlerts: [WAFAlertEvent] {
        guard severityFilter != "all" else { return viewModel.recentAlerts }
        return viewModel.recentAlerts.filter { $0.severity == severityFilter }
    }

    private func countBySeverity(_ sev: String) -> Int {
        viewModel.recentAlerts.filter { $0.severity == sev }.count
    }

    private func severityColor(_ sev: String) -> Color {
        switch sev {
        case "critical": return .axError
        case "high":     return .axWarning
        case "medium":   return .axAccentBlue
        case "low":      return .axAccentGreen
        default:         return .axAccentBlue
        }
    }

    private func eventTypeIcon(_ type: String) -> String {
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

    private func formatTimestamp(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateFormat = "HH:mm:ss"
        return display.string(from: date)
    }
}
