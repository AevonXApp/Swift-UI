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
                sidebarTabs
                Divider().background(Color.axDivider)
                contentArea
            }
        }
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: AXSpacing.md) {
            headerBrand
            Spacer()
            headerStatusGroup
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
    }

    private var headerBrand: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axAccentBlue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "shield.checkered")
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axAccentBlue)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text("AXCerberus WAF")
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
                Text("Layer 7 Web Application Firewall")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    private var headerStatusGroup: some View {
        HStack(spacing: AXSpacing.lg) {
            if let ov = viewModel.overview {
                headerMiniStat(value: viewModel.formatNumber(ov.totalRequests), label: "Requests", color: .axAccentBlue)
                headerMiniStat(value: String(format: "%.1f%%", ov.protectionRate), label: "Block Rate", color: .axError)
                headerMiniStat(value: String(format: "%.1f", ov.qps), label: "QPS", color: .axAccentGreen)
            }
            serviceStatusBadge
        }
    }

    private func headerMiniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    private var serviceStatusBadge: some View {
        Group {
            if let status = viewModel.serviceStatus {
                AXStatusBadge(
                    status: status.isActive ? .online : .offline,
                    showLabel: true,
                    size: 8,
                    enablePulseAnimation: status.isActive
                )
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarTabs: some View {
        VStack(spacing: AXSpacing.xxxs) {
            ForEach(CerberusTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
            Spacer()
            sidebarFooter
        }
        .padding(AXSpacing.sm)
        .frame(width: 170)
        .background(Color.axSurface)
    }

    private func tabButton(_ tab: CerberusTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            viewModel.selectedTab = tab
        } label: {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                        .frame(width: 26, height: 26)
                    Image(systemName: tab.icon)
                        .font(AXTypography.caption)
                        .foregroundStyle(isSelected ? Color.axAccentBlue : Color.axTextMuted)
                }
                Text(tab.rawValue)
                    .font(AXTypography.subheadline)
                Spacer()
                if tab == .alerts && !viewModel.recentAlerts.isEmpty {
                    alertCountDot
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.clear)
            )
            .foregroundStyle(isSelected ? Color.axAccentBlue : Color.axTextSecondary)
        }
        .buttonStyle(.plain)
    }

    private var alertCountDot: some View {
        Text("\(viewModel.recentAlerts.count)")
            .font(AXTypography.monoXs)
            .foregroundStyle(.white)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(Capsule().fill(Color.axError))
    }

    private var sidebarFooter: some View {
        VStack(spacing: AXSpacing.xs) {
            Divider()
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(Color.axAccentGreen)
                    .frame(width: 6, height: 6)
                Text("12 modules")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.sm)
        }
    }

    // MARK: - Content

    private var contentArea: some View {
        Group {
            switch viewModel.selectedTab {
            case .dashboard:
                CerberusDashboardView(viewModel: viewModel)
            case .attacks:
                CerberusAttacksView(viewModel: viewModel)
            case .traffic:
                CerberusTrafficView(viewModel: viewModel)
            case .ipManagement:
                CerberusIPManagementView(viewModel: viewModel)
            case .modules:
                CerberusModulesView(viewModel: viewModel)
            case .honeypot:
                CerberusHoneypotView(viewModel: viewModel)
            case .alerts:
                CerberusAlertsView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
