//
//  CerberusRootView.swift
//  AevonX
//
//  Root view for AXCerberus WAF management.
//  Wraps content with AXPluginGateView to check installation.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Public Entry Point

/// Use this as the entry point for AXCerberus.
/// It checks if the plugin is installed before showing the UI.
struct CerberusRootView: View {
    let serverId: String

    var body: some View {
        AXPluginGateView(slug: "axcerberus-waf", serverId: serverId) {
            CerberusContentView(serverId: serverId)
        }
    }
}

// MARK: - Content (shown when installed)

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
            Image(systemName: "shield.checkered")
                .font(.title2)
                .foregroundStyle(Color.axAccentBlue)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text("AXCerberus WAF")
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
                Text("Layer 7 Web Application Firewall")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextSecondary)
            }

            Spacer()

            serviceStatusBadge
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
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
        VStack(spacing: AXSpacing.xxs) {
            ForEach(CerberusTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
            Spacer()
        }
        .padding(AXSpacing.sm)
        .frame(width: 180)
        .background(Color.axSurface)
    }

    private func tabButton(_ tab: CerberusTab) -> some View {
        Button {
            viewModel.selectedTab = tab
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: tab.icon)
                    .frame(width: 18)
                Text(tab.rawValue)
                    .font(AXTypography.subheadline)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(viewModel.selectedTab == tab
                          ? Color.axAccentBlue.opacity(0.15)
                          : Color.clear)
            )
            .foregroundStyle(viewModel.selectedTab == tab
                             ? Color.axAccentBlue
                             : Color.axTextSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    private var contentArea: some View {
        Group {
            switch viewModel.selectedTab {
            case .dashboard:
                CerberusDashboardView(viewModel: viewModel)
            case .attacks:
                CerberusAttacksView(viewModel: viewModel)
            case .websites:
                CerberusWebsitesView(viewModel: viewModel)
            case .ipManagement:
                CerberusIPManagementView(viewModel: viewModel)
            case .modules:
                CerberusModulesView(viewModel: viewModel)
            case .honeypot:
                CerberusHoneypotView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Usage Example
//
// Any future AXPlugin follows the same pattern:
//
//   struct MyPluginRootView: View {
//       let serverId: String
//       var body: some View {
//           AXPluginGateView(slug: "myplugin", serverId: serverId) {
//               MyPluginContentView(serverId: serverId)
//           }
//       }
//   }
//
