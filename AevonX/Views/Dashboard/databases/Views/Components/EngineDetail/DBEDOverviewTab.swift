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
            AXStatCard(
                icon: "clock",
                label: "Uptime",
                value: AXFormatter.formatUptime(metrics.uptime),
                color: viewModel.databaseType.brandColor
            )

            AXStatCard(
                icon: "link",
                label: "Connections",
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                color: .axAccentGreen
            )

            AXStatCard(
                icon: "memorychip",
                label: "Memory",
                value: AXFormatter.formatSizeMB(metrics.memoryUsage),
                color: .axWarning
            )
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
