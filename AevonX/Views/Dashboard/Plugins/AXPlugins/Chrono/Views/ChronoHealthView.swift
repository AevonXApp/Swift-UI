//
//  ChronoHealthView.swift
//  AevonX
//
//  Health monitoring — probes status, response times, uptime across all projects.
//

import SwiftUI

struct ChronoHealthView: View {
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                summaryCards
                probesList
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadHealth() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "heart.text.square")
                .font(.system(size: 16))
                .foregroundColor(.axAccentGreen)
            Text(L10n.Chrono.Health.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            Spacer()
            Button {
                Task { await viewModel.loadHealth() }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "arrow.clockwise")
                    Text(L10n.Chrono.Health.refresh)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Summary

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
            summaryCard(
                value: "\(viewModel.healthProbes.count)",
                label: L10n.Chrono.Health.totalProbes,
                icon: "heart.text.square",
                color: .axAccentBlue
            )
            summaryCard(
                value: "\(upCount)",
                label: L10n.Chrono.Health.healthy,
                icon: "checkmark.circle.fill",
                color: .axSuccess
            )
            summaryCard(
                value: "\(degradedCount)",
                label: L10n.Chrono.Health.degraded,
                icon: "exclamationmark.triangle.fill",
                color: .axWarning
            )
            summaryCard(
                value: "\(downCount)",
                label: L10n.Chrono.Health.down,
                icon: "xmark.circle.fill",
                color: .axError
            )
        }
    }

    private func summaryCard(value: String, label: String, icon: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Probes List

    @ViewBuilder
    private var probesList: some View {
        if viewModel.healthProbes.isEmpty {
            emptyState
        } else {
            VStack(spacing: AXSpacing.sm) {
                ForEach(viewModel.healthProbes) { probe in
                    ChronoHealthProbeCard(probe: probe)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text(L10n.Chrono.Health.empty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            Text(L10n.Chrono.Health.emptyHint)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }

    // MARK: - Computed

    private var upCount: Int { viewModel.healthProbes.filter { $0.status == "up" }.count }
    private var degradedCount: Int { viewModel.healthProbes.filter { $0.status == "degraded" }.count }
    private var downCount: Int { viewModel.healthProbes.filter { $0.status == "down" }.count }
}

// MARK: - Health Probe Card Component

struct ChronoHealthProbeCard: View {
    let probe: ChronoHealthProbe

    var body: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                statusIndicator
                projectInfo
                Spacer()
                responseMetrics
                uptimeBar
            }
            .padding(AXSpacing.lg)
        }
    }

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: statusIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(statusColor)
        }
    }

    private var projectInfo: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(probe.projectName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            Text(probe.url)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .lineLimit(1)
            HStack(spacing: AXSpacing.sm) {
                Text(L10n.Chrono.Health.lastCheck(probe.lastCheck))
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                if probe.consecutiveFailures > 0 {
                    HStack(spacing: AXSpacing.xxxs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                        Text("\(probe.consecutiveFailures) failures")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.axError)
                }
            }
        }
    }

    private var responseMetrics: some View {
        VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
            Text("\(probe.responseTimeMS)ms")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(responseColor)
            Text(L10n.Chrono.Health.responseTime)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
    }

    private var uptimeBar: some View {
        VStack(spacing: AXSpacing.xxxs) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(Color.axSurface)
                    .frame(width: 60, height: 6)
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(uptimeColor)
                    .frame(width: 60 * CGFloat(probe.uptimePercent / 100), height: 6)
            }
            Text(String(format: "%.1f%%", probe.uptimePercent))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(uptimeColor)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch probe.status {
        case "up": return .axSuccess
        case "degraded": return .axWarning
        case "down": return .axError
        default: return .axTextMuted
        }
    }

    private var statusIcon: String {
        switch probe.status {
        case "up": return "checkmark.circle.fill"
        case "degraded": return "exclamationmark.triangle.fill"
        case "down": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private var responseColor: Color {
        if probe.responseTimeMS < 300 { return .axSuccess }
        if probe.responseTimeMS < 1000 { return .axWarning }
        return .axError
    }

    private var uptimeColor: Color {
        if probe.uptimePercent >= 99.5 { return .axSuccess }
        if probe.uptimePercent >= 95 { return .axWarning }
        return .axError
    }
}
