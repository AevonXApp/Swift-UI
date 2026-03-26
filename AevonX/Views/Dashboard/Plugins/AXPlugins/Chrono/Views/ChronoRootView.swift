//
//  ChronoRootView.swift
//  AevonX
//
//  Root view for AXChrono — wraps in plugin gate, then shows tab layout.
//

import SwiftUI
import AevonXCoreBridge

struct ChronoRootView: View {
    let serverId: String

    var body: some View {
        AXPluginGateView(slug: "axchrono", serverId: serverId) {
            ChronoContentView(serverId: serverId)
        }
    }
}

// MARK: - Content

private struct ChronoContentView: View {
    @StateObject private var viewModel: ChronoViewModel

    init(serverId: String) {
        _viewModel = StateObject(wrappedValue: ChronoViewModel(serverId: serverId))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().background(Color.axDivider)
            HStack(spacing: 0) {
                sidebarNav
                Divider().background(Color.axDivider)
                contentArea
            }
        }
        .background(Color.axBackground)
        .task {
            await viewModel.checkService()
            await viewModel.loadDashboard()
        }
    }
}

// MARK: - Header Bar

private extension ChronoContentView {

    var headerBar: some View {
        HStack(spacing: AXSpacing.lg) {
            headerBrand
            Spacer()
            headerLiveMetrics
            headerServiceControl
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(
            Color.axSurface
                .overlay(
                    LinearGradient(
                        colors: [Color.axAccentPurple.opacity(0.03), Color.clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
        )
    }

    var headerBrand: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentPurple.opacity(0.2), Color.axAccentBlue.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(AXTypography.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axAccentPurple, Color.axAccentBlue],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(L10n.Chrono.brand)
                        .font(AXTypography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text("GIT")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axAccentPurple)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axAccentPurple.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
                }
                Text(L10n.Chrono.subtitle)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    var headerLiveMetrics: some View {
        HStack(spacing: AXSpacing.xl) {
            if let ds = viewModel.daemonStatus {
                headerMetric(value: "\(ds.trackedProjects)", label: L10n.Chrono.activeProjects, color: .axAccentBlue)
                Divider().frame(height: 24)
                headerMetric(value: "\(ds.totalDeploys)", label: L10n.Chrono.totalDeploys, color: .axAccentGreen)
                Divider().frame(height: 24)
                headerMetric(value: "\(ds.activeDeploys)", label: "Active", color: .axWarning)
            }
        }
    }

    func headerMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.monoSm)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    var headerServiceControl: some View {
        HStack(spacing: AXSpacing.sm) {
            if let status = viewModel.serviceStatus {
                AXStatusBadge(
                    status: status.isActive ? .online : .offline,
                    showLabel: true,
                    size: 8,
                    enablePulseAnimation: status.isActive
                )
            }
            serviceButtons
        }
    }

    var serviceButtons: some View {
        HStack(spacing: AXSpacing.xxs) {
            if viewModel.serviceOperationInProgress {
                ProgressView().controlSize(.small).frame(width: 16, height: 16)
            } else {
                let isActive = viewModel.serviceStatus?.isActive ?? false
                if isActive {
                    svcBtn(icon: "stop.fill", color: .axError, tip: L10n.Chrono.serviceStop) {
                        Task { await viewModel.stopService() }
                    }
                    svcBtn(icon: "arrow.clockwise", color: .axWarning, tip: L10n.Chrono.serviceRestart) {
                        Task { await viewModel.restartService() }
                    }
                } else {
                    svcBtn(icon: "play.fill", color: .axSuccess, tip: L10n.Chrono.serviceStart) {
                        Task { await viewModel.startService() }
                    }
                }
            }
        }
    }

    func svcBtn(icon: String, color: Color, tip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
        .help(tip)
    }
}

// MARK: - Sidebar

private extension ChronoContentView {

    var sidebarNav: some View {
        AXSidebarContainer(
            width: 220,
            header: { sidebarHeader },
            items: { sidebarItems },
            footer: { sidebarFooter }
        )
    }

    var sidebarHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentPurple.opacity(0.15), Color.axAccentBlue.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axAccentPurple, Color.axAccentBlue],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            Text(L10n.Chrono.sidebarTitle)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Color.axTextMuted)
                .tracking(1.5)
            Spacer()
            if let status = viewModel.serviceStatus {
                AXStatusBadge(status: status.isActive ? .online : .offline, showLabel: false, size: 7, enablePulseAnimation: status.isActive)
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.top, AXSpacing.md)
        .padding(.bottom, AXSpacing.sm)
    }

    @ViewBuilder
    var sidebarItems: some View {
        AXSidebarCategoryHeader(title: L10n.Chrono.catOverview, icon: "chart.xyaxis.line")
        sidebarRow(.dashboard)

        AXSidebarCategoryHeader(title: L10n.Chrono.catDeployment, icon: "arrow.triangle.2.circlepath")
        sidebarRow(.projects)
        sidebarRow(.deploys)
        sidebarRow(.timeline)

        AXSidebarCategoryHeader(title: L10n.Chrono.catIntelligence, icon: "brain.head.profile.fill")
        sidebarRow(.security)
        sidebarRowWithBadge(.approvals)
        sidebarRow(.hologram)

        AXSidebarCategoryHeader(title: L10n.Chrono.catManagement, icon: "gearshape.2.fill")
        sidebarRow(.settings)
    }

    func sidebarRow(_ tab: ChronoViewModel.ChronoTab) -> some View {
        AXSidebarRow(
            icon: tab.icon, title: tab.label, color: tab.color,
            isSelected: viewModel.selectedTab == tab,
            action: { viewModel.selectedTab = tab }
        )
    }

    func sidebarRowWithBadge(_ tab: ChronoViewModel.ChronoTab) -> some View {
        AXSidebarRow(
            icon: tab.icon, title: tab.label, color: tab.color,
            isSelected: viewModel.selectedTab == tab,
            action: { viewModel.selectedTab = tab }
        )
        .overlay(alignment: .trailing) {
            if !viewModel.pendingApprovals.isEmpty {
                Text("\(viewModel.pendingApprovals.count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(Capsule().fill(Color.axWarning))
                    .padding(.trailing, AXSpacing.sm)
            }
        }
    }

    var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.axBorder.opacity(0.25)).frame(height: 1).padding(.horizontal, AXSpacing.sm)
            HStack(spacing: AXSpacing.xs) {
                Circle().fill(Color.axAccentGreen).frame(width: 6, height: 6)
                Text("\(viewModel.projects.count) projects")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.axTextMuted.opacity(0.5))
                Spacer()
                Text(viewModel.daemonStatus?.version ?? "")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.axTextMuted.opacity(0.5))
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
        }
    }
}

// MARK: - Content Area

private extension ChronoContentView {

    var contentArea: some View {
        Group {
            switch viewModel.selectedTab {
            case .dashboard:  ChronoDashboardView(viewModel: viewModel)
            case .projects:   ChronoProjectsView(viewModel: viewModel)
            case .deploys:    ChronoDeployHistoryView(viewModel: viewModel)
            case .timeline:   ChronoTimelineView(viewModel: viewModel)
            case .security:   ChronoSecurityView(viewModel: viewModel)
            case .approvals:  ChronoApprovalsView(viewModel: viewModel)
            case .hologram:   ChronoHologramView(viewModel: viewModel)
            case .settings:   ChronoSettingsView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
