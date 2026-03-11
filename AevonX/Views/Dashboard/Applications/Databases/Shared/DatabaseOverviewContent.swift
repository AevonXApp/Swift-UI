//
//  DatabaseOverviewContent.swift
//  AevonX
//
//  Overview tab content extracted from UnifiedDatabaseDetailView
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

extension UnifiedDatabaseDetailView {

    // MARK: - Overview Tab

    var overviewContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header with refresh button
            HStack {
                Text("Overview")
                    .font(AXTypography.title)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost, size: .small) {
                    Task { await viewModel.loadData() }
                }
                .disabled(viewModel.isOperationInProgress)
            }

            if viewModel.isLoading {
                AXLoadingState(message: "Loading database data…")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                // Engine Info Card
                engineInfoCard

                // Metrics Grid
                if let metrics = viewModel.metrics {
                    metricsGrid(metrics: metrics)
                }

                // Performance Stats
                if let stats = viewModel.performanceStats {
                    performanceCard(stats: stats)
                }

                // Danger Zone
                dangerZoneCard
            }
        }
    }

    var engineInfoCard: some View {
        AXConfigCard(icon: "server.rack", title: "Engine Information") {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                AXInfoRow(label: "Type", value: databaseType.displayName, valueColor: databaseType.brandColor)
                AXInfoRow(label: "Version", value: viewModel.formattedVersion, valueColor: .axAccentBlue)
                AXInfoRow(label: "Install Path", value: viewModel.formattedInstallPath)
                AXInfoRow(label: "Status", value: viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                AXInfoRow(label: "Service", value: viewModel.isRunning ? "Running" : "Stopped",
                          valueColor: viewModel.isRunning ? .axSuccess : .axError)
                AXInfoRow(label: "Boot", value: viewModel.isBootEnabled ? "Enabled" : "Disabled",
                          valueColor: viewModel.isBootEnabled ? .axSuccess : .axTextMuted)
                AXInfoRow(label: "Config File", value: viewModel.configFilePath)
            }
        }
    }

    func metricsGrid(metrics: AevonXCoreBridge.DatabaseMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            AXStatCard(icon: "clock", label: "Uptime",
                       value: AevonXCoreBridge.AXFormatter.formatDuration(seconds: viewModel.metrics?.uptime ?? 0),
                       color: databaseType.brandColor)

            AXStatCard(icon: "link", label: "Connections",
                       value: "\(metrics.connections)/\(metrics.maxConnections)",
                       color: .axAccentGreen)

            AXStatCard(icon: "memorychip", label: "Memory",
                       value: AevonXCoreBridge.AXFormatter.formatSizeMB(viewModel.metrics?.memoryUsage ?? 0),
                       color: .axWarning)
        }
    }

    func performanceCard(stats: AevonXCoreBridge.PerformanceStatistics) -> some View {
        AXConfigCard(icon: "chart.bar.fill", title: "Performance Statistics") {
            HStack(spacing: AXSpacing.xl) {
                statColumn(label: "Total Queries", value: "\(stats.totalQueries)")
                statColumn(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                statColumn(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                statColumn(label: "Cache Hit", value: String(format: "%.1f%%", stats.indexUsage * 100))
            }
        }
    }

    func statColumn(label: String, value: String) -> some View {
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

    var dangerZoneCard: some View {
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
                Text("Uninstalling the engine will remove all binaries and may result in data loss if backups are not maintained.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)

                AXActionButton(
                    label: "Uninstall \(databaseType.displayName)",
                    icon: "trash",
                    style: .destructive,
                    size: .regular
                ) {
                    viewModel.showUninstallConfirmation()
                }
                .disabled(viewModel.isOperationInProgress)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axError.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, AXSpacing.xl)
    }
}
