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
                    Text("Overview")
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
                    AXLoadingState(message: "Loading engine data...")
                        .frame(minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    AXPlaceholder(
                        icon: "exclamationmark.triangle.fill",
                        title: "Error",
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
                                Text("Danger Zone")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axError)
                                
                                Spacer()
                                
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.axError)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.md) {
                                Text("Uninstalling the engine will remove all binaries and may result in partial or total data loss if backups are not maintained.")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextSecondary)
                                
                                Button(role: .destructive) {
                                    viewModel.showUninstallConfirmation()
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Uninstall \(viewModel.databaseType.displayName)")
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
                Text("Engine Information")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                DBEMInfoRow(label: "Type", value: viewModel.databaseType.displayName)
                DBEMInfoRow(label: "Version", value: viewModel.formattedVersion)
                DBEMInfoRow(label: "Install Path", value: viewModel.formattedInstallPath)
                DBEMInfoRow(label: "Status", value: viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                DBEMInfoRow(label: "Service", value: viewModel.isRunning ? "Running" : "Stopped")
                DBEMInfoRow(label: "Boot", value: viewModel.isBootEnabled ? "Enabled" : "Disabled")
                DBEMInfoRow(label: "Config File", value: viewModel.configFilePath)
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
                label: "Uptime",
                value: AXFormatter.formatUptime(metrics.uptime),
                color: themeColor
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

}

struct PerformanceCard: View {
    let stats: PerformanceStatistics
    let themeColor: Color

    var body: some View {
        AXGlassCard(accentColor: themeColor) {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Text("Performance Statistics")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Divider()

                HStack(spacing: AXSpacing.xl) {
                    StatColumn(label: "Total Queries", value: "\(stats.totalQueries)")
                    StatColumn(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                    StatColumn(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                    StatColumn(label: "Cache Hit", value: String(format: "%.1f%%", stats.indexUsage * 100))
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

