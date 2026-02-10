//
//  DBEDOverviewTab.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEDOverviewTab: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Engine Info Card
                engineInfoCard

                // Metrics Cards
                if let metrics = viewModel.metrics {
                    metricsGrid(metrics: metrics)
                }

                // Performance Stats
                if let stats = viewModel.performanceStats {
                    performanceCard(stats: stats)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Engine Info Card

    private var engineInfoCard: some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Engine Information")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                DBInfoRow(label: "Type", value: viewModel.databaseType.displayName)
                DBInfoRow(label: "Version", value: viewModel.formattedVersion)
                DBInfoRow(label: "Install Path", value: viewModel.formattedInstallPath)
                DBInfoRow(label: "Status", value: viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                DBInfoRow(label: "Service", value: viewModel.isRunning ? "Running" : "Stopped")
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Metrics Grid

    private func metricsGrid(metrics: DatabaseMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            DBMetricCard(
                title: "Uptime",
                value: formatUptime(metrics.uptime),
                icon: "clock",
                color: viewModel.databaseType.brandColor
            )

            DBMetricCard(
                title: "Connections",
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                icon: "link",
                color: .axAccentGreen
            )

            DBMetricCard(
                title: "Memory",
                value: String(format: "%.1f MB", metrics.memoryUsage),
                icon: "memorychip",
                color: .axWarning
            )
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Performance Card

    private func performanceCard(stats: PerformanceStatistics) -> some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Performance Statistics")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                HStack(spacing: AXSpacing.xl) {
                    DBStatItem(label: "Total Queries", value: "\(stats.totalQueries)")
                    DBStatItem(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                    DBStatItem(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                    DBStatItem(label: "Cache Hit Ratio", value: String(format: "%.1f%%", stats.indexUsage * 100))
                }
            }
            .padding(AXSpacing.lg)
        }
    }
}

// MARK: - Supporting Views

private struct DBInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Text(value)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
        }
    }
}

private struct DBMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        AXGlassCard(accentColor: color) {
            VStack(spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(value)
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    Text(title)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AXSpacing.lg)
        }
    }
}

private struct DBStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: AXSpacing.xxs) {
            Text(value)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
    }
}
