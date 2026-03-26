//
//  ChronoDashboardView.swift
//  AevonX
//
//  AXChrono dashboard — stat cards, recent deploys, watchers, alerts.
//

import SwiftUI

struct ChronoDashboardView: View {
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                Text(L10n.Chrono.dashboardTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                statCards
                recentDeploysSection
                alertsSection
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadDashboard() }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: 3), spacing: AXSpacing.lg) {
            statCard(value: "\(viewModel.daemonStatus?.trackedProjects ?? 0)", label: L10n.Chrono.activeProjects, icon: "folder.badge.gearshape", color: .axAccentBlue)
            statCard(value: "\(viewModel.daemonStatus?.totalDeploys ?? 0)", label: L10n.Chrono.totalDeploys, icon: "arrow.triangle.2.circlepath", color: .axAccentGreen)
            statCard(value: "\(viewModel.daemonStatus?.failedThisWeek ?? 0)", label: L10n.Chrono.failedThisWeek, icon: "exclamationmark.triangle", color: .axError)
            statCard(value: viewModel.daemonStatus?.healthStatus ?? "—", label: L10n.Chrono.healthStatus, icon: "heart.fill", color: .axSuccess)
            statCard(value: "\(viewModel.daemonStatus?.cacheSizeMB ?? 0) MB", label: L10n.Chrono.cacheSize, icon: "internaldrive", color: .axAccentPurple)
            statCard(value: "\(viewModel.daemonStatus?.secretsDetected ?? 0)", label: L10n.Chrono.secretsDetected, icon: "lock.shield", color: .axWarning)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Recent Deploys

    private var recentDeploysSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(L10n.Chrono.recentDeploys)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            if viewModel.recentDeploys.isEmpty {
                Text(L10n.Chrono.Deploy.empty)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                    .padding(.vertical, AXSpacing.lg)
            } else {
                VStack(spacing: AXSpacing.xs) {
                    ForEach(viewModel.recentDeploys) { deploy in
                        ChronoDeployRow(deploy: deploy)
                    }
                }
            }
        }
    }

    // MARK: - Alerts

    @ViewBuilder
    private var alertsSection: some View {
        if !viewModel.dashboardAlerts.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text(L10n.Chrono.alerts)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                ForEach(viewModel.dashboardAlerts) { alert in
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axWarning)
                            .font(.system(size: 12))
                        Text(alert.message)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                        Spacer()
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axWarning.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
            }
        }
    }
}
