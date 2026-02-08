//
//  DBEMOverviewSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

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
                            .font(.system(size: 14))
                            .foregroundColor(.axTextSecondary)
                            .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                            .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else {
                    // Engine Info Card
                    EngineInfoCard(viewModel: viewModel)

                    // Metrics Grid
                    if let metrics = viewModel.metrics {
                        MetricsGrid(metrics: metrics, themeColor: viewModel.databaseType.brandColor)
                    }

                    // Performance Stats
                    if let stats = viewModel.performanceStats {
                        PerformanceCard(stats: stats, themeColor: viewModel.databaseType.brandColor)
                    }

                    // Danger Zone
                    AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
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
        AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
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
    let metrics: AevonXCore.DatabaseMetrics
    let themeColor: Color

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            DBEMMetricCard(
                title: "Uptime",
                value: formatUptime(metrics.uptime),
                icon: "clock",
                color: themeColor
            )

            DBEMMetricCard(
                title: "Connections",
                value: "\(metrics.connections)/\(metrics.maxConnections)",
                icon: "link",
                color: .axAccentGreen
            )

            DBEMMetricCard(
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
}

struct PerformanceCard: View {
    let stats: AevonXCore.PerformanceStatistics
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

struct DBEMMetricCard: View {
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

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.axError)

            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}
