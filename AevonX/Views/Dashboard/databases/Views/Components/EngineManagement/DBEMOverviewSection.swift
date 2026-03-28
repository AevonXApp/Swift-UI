//
//  DBEMOverviewSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEMOverviewSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text(L10n.Engine.overview)
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.loadData() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                            .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                            .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                if viewModel.isLoading {
                    AXLoadingState(message: L10n.Engine.loadingEngineData)
                        .frame(minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    AXPlaceholder(
                        icon: "exclamationmark.triangle.fill",
                        title: L10n.Status.error,
                        subtitle: error,
                        iconColor: .axError
                    )
                    .frame(minHeight: 300)
                } else {
                    // Engine Info Card
                    EngineInfoCard(viewModel: viewModel)

                    // Metrics Grid
                    if let metrics = viewModel.metrics {
                        MetricsGrid(metrics: metrics, themeColor: .axAccentBlue)
                    }

                    // Performance Stats
                    if let stats = viewModel.performanceStats {
                        PerformanceCard(stats: stats, themeColor: .axAccentBlue)
                    }

                    // Danger Zone
                    AXGlassCard(accentColor: .axAccentBlue) {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Text(L10n.Engine.dangerZone)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axError)
                                
                                Spacer()
                                
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.axError)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.md) {
                                Text(L10n.Engine.uninstallWarning)
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextSecondary)
                                
                                Button(role: .destructive) {
                                    viewModel.showUninstallConfirmation()
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text(L10n.Engine.uninstallEngine(viewModel.databaseType.displayName))
                                    }
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.axBackground)
                                    .padding(.horizontal, AXSpacing.xl)
                                    .padding(.vertical, AXSpacing.md)
                                    .background(Color.axError)
                                    .cornerRadius(AXCornerRadius.md)
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.isOperationInProgress)
                            }
                        }
                        .padding(AXSpacing.lg)
                    }
                    .padding(.top, AXSpacing.xl)
                }
            }
            .padding(AXSpacing.xl)
        }
    }
}

// MARK: - Supporting Views

struct EngineInfoCard: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        AXGlassCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text(L10n.Engine.engineInformation)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                DBEMInfoRow(label: L10n.Engine.labelType, value: viewModel.databaseType.displayName)
                DBEMInfoRow(label: L10n.Engine.labelVersion, value: viewModel.formattedVersion)
                DBEMInfoRow(label: L10n.Engine.labelInstallPath, value: viewModel.formattedInstallPath)
                DBEMInfoRow(label: L10n.Engine.labelStatus, value: viewModel.engineInfo?.status.rawValue.capitalized ?? L10n.Status.unknown)
                DBEMInfoRow(label: L10n.Engine.labelService, value: viewModel.isRunning ? L10n.Status.running : L10n.Status.stopped)
                DBEMInfoRow(label: L10n.Engine.labelBoot, value: viewModel.isBootEnabled ? L10n.Status.enabled : L10n.Status.disabled)
                DBEMInfoRow(label: L10n.Engine.labelConfigFile, value: viewModel.configFilePath)
            }
            .padding(AXSpacing.lg)
        }
    }
}

struct MetricsGrid: View {
    let metrics: DatabaseMetrics
    let themeColor: Color

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            AXStatCard(
                icon: "clock",
                label: L10n.Engine.metricUptime,
                value: AXFormatter.formatUptime(metrics.uptime),
                color: themeColor
            )

            AXStatCard(
                icon: "link",
                label: L10n.Engine.metricConnections,
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                color: .axAccentGreen
            )

            AXStatCard(
                icon: "memorychip",
                label: L10n.Engine.metricMemory,
                value: AXFormatter.formatSizeMB(metrics.memoryUsage),
                color: .axWarning
            )
        }
    }

}

struct PerformanceCard: View {
    let stats: PerformanceStatistics
    let themeColor: Color

    var body: some View {
        AXGlassCard(accentColor: themeColor) {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text(L10n.Engine.performanceStatistics)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                HStack(spacing: AXSpacing.xl) {
                    StatColumn(label: L10n.Engine.metricTotalQueries, value: "\(stats.totalQueries)")
                    StatColumn(label: L10n.Engine.metricAvgQueryTime, value: String(format: "%.2f ms", stats.avgQueryTime))
                    StatColumn(label: L10n.Engine.metricMaxQueryTime, value: String(format: "%.2f ms", stats.maxQueryTime))
                    StatColumn(label: L10n.Engine.metricCacheHit, value: String(format: "%.1f%%", stats.indexUsage * 100))
                }
            }
            .padding(AXSpacing.lg)
        }
    }
}

struct StatColumn: View {
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

struct DBEMInfoRow: View {
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

