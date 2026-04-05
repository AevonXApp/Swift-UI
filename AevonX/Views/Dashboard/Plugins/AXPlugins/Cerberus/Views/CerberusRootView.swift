//
//  CerberusRootView.swift
//  AevonX
//
//  Root view for AXCerberus WAF — premium command shell.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusRootView: View {
    let serverId: String

    var body: some View {
        AXPluginGateView(slug: "axcerberus-waf", serverId: serverId) {
            CerberusContentView(serverId: serverId)
        }
    }
}

// MARK: - Content

private struct CerberusContentView: View {
    @StateObject private var viewModel: CerberusViewModel

    init(serverId: String) {
        _viewModel = StateObject(wrappedValue: CerberusViewModel(serverId: serverId))
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
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
    }
}

// MARK: - Header Bar

private extension CerberusContentView {

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
                        colors: [Color.axAccentBlue.opacity(0.03), Color.clear],
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
                            colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.55).opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "shield.checkered")
                    .font(AXTypography.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(L10n.Cerberus.Root.brand)
                        .font(AXTypography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(L10n.Cerberus.Root.waf)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axAccentBlue)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axAccentBlue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
                }
                Text(L10n.Cerberus.Root.subtitle)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    var headerLiveMetrics: some View {
        HStack(spacing: AXSpacing.xl) {
            if let ov = viewModel.overview {
                headerMetric(value: viewModel.formatNumber(ov.totalRequests), label: L10n.Cerberus.Root.requests, color: .axAccentBlue)
                Divider().frame(height: 24)
                headerMetric(value: String(format: "%.1f%%", Double(ov.protectionRate)), label: L10n.Cerberus.Root.blockRate, color: .axError)
                Divider().frame(height: 24)
                headerMetric(value: String(format: "%.1f", Double(ov.qps)), label: L10n.Cerberus.Root.qps, color: .axAccentGreen)
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
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
            } else {
                let isActive = viewModel.serviceStatus?.isActive ?? false
                if isActive {
                    svcBtn(icon: "stop.fill", color: .axError, tip: L10n.Cerberus.Root.stopWAF) {
                        Task { await viewModel.stopService() }
                    }
                    svcBtn(icon: "arrow.clockwise", color: .axWarning, tip: L10n.Cerberus.Root.restartWAF) {
                        Task { await viewModel.restartService() }
                    }
                } else {
                    svcBtn(icon: "play.fill", color: .axSuccess, tip: L10n.Cerberus.Root.startWAF) {
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

// MARK: - Sidebar Navigation

private extension CerberusContentView {

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
                            colors: [Color.axAccentBlue.opacity(0.15), Color.axAccentBlue.opacity(0.55).opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            Text(L10n.Cerberus.Root.sidebarTitle)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Color.axTextMuted)
                .tracking(1.5)
            Spacer()
            if let status = viewModel.serviceStatus {
                AXStatusBadge(
                    status: status.isActive ? .online : .offline,
                    showLabel: false,
                    size: 7,
                    enablePulseAnimation: status.isActive
                )
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.top, AXSpacing.md)
        .padding(.bottom, AXSpacing.sm)
    }

    @ViewBuilder
    var sidebarItems: some View {
        // OVERVIEW
        AXSidebarCategoryHeader(title: L10n.Cerberus.Root.catOverview, icon: "chart.xyaxis.line")
        sidebarRow(.dashboard)
        sidebarRow(.traffic)
        sidebarRow(.visitorLog)
        sidebarRow(.attacks)

        // SECURITY
        AXSidebarCategoryHeader(title: L10n.Cerberus.Root.catSecurity, icon: "lock.shield.fill")
        sidebarRow(.ipManagement)
        sidebarRow(.modules)
        sidebarRow(.honeypot)
        sidebarRowWithBadge(.alerts)

        // INTELLIGENCE
        AXSidebarCategoryHeader(title: L10n.Cerberus.Root.catIntelligence, icon: "brain.head.profile.fill")
        sidebarRow(.threatFeed)
        sidebarRow(.compliance)
        sidebarRow(.sessions)
        sidebarRow(.customRules)

        // MANAGEMENT
        AXSidebarCategoryHeader(title: L10n.Cerberus.Root.catManagement, icon: "gearshape.2.fill")
        sidebarRow(.domains)
        sidebarRow(.settings)
    }

    func sidebarRow(_ tab: CerberusTab) -> some View {
        AXSidebarRow(
            icon: tab.icon,
            title: tab.label,
            color: tab.color,
            isSelected: viewModel.selectedTab == tab,
            action: { viewModel.selectedTab = tab }
        )
    }

    func sidebarRowWithBadge(_ tab: CerberusTab) -> some View {
        AXSidebarRow(
            icon: tab.icon,
            title: tab.label,
            color: tab.color,
            isSelected: viewModel.selectedTab == tab,
            action: { viewModel.selectedTab = tab }
        )
        .overlay(alignment: .trailing) {
            if !viewModel.recentAlerts.isEmpty {
                Text("\(viewModel.recentAlerts.count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(Capsule().fill(Color.axError))
                    .padding(.trailing, AXSpacing.sm)
            }
        }
    }

    var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.axBorder.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.sm)
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(Color.axAccentGreen)
                    .frame(width: 6, height: 6)
                Text(L10n.Cerberus.Root.modulesCount(viewModel.enabledModuleCount))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.axTextMuted.opacity(0.5))
                Spacer()
                Text(viewModel.serviceStatus?.binary ?? "—")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.axTextMuted.opacity(0.5))
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
        }
    }
}

// MARK: - Content Area

private extension CerberusContentView {

    var contentArea: some View {
        Group {
            switch viewModel.selectedTab {
            case .dashboard:    CerberusDashboardView(viewModel: viewModel)
            case .attacks:      CerberusAttacksView(viewModel: viewModel)
            case .traffic:      CerberusTrafficView(viewModel: viewModel)
            case .domains:      CerberusDomainsView(viewModel: viewModel)
            case .ipManagement: CerberusIPManagementView(viewModel: viewModel)
            case .modules:      CerberusModulesView(viewModel: viewModel)
            case .honeypot:     CerberusHoneypotView(viewModel: viewModel)
            case .alerts:       CerberusAlertsView(viewModel: viewModel)
            case .threatFeed:   CerberusThreatFeedView(viewModel: viewModel)
            case .compliance:   CerberusComplianceView(viewModel: viewModel)
            case .sessions:     CerberusSessionView(viewModel: viewModel)
            case .customRules:  CerberusCustomRulesView(viewModel: viewModel)
            case .visitorLog:   CerberusVisitorLogView(viewModel: viewModel)
            case .settings:     CerberusSettingsView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedTab)
    }
}
