//
//  DashboardSidebar.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

struct DashboardSidebar: View {
    let server: Server
    @ObservedObject var viewModel: ServerConnectionViewModel
    let onBack: () -> Void

    @ObservedObject private var hookRegistry = AevonXCoreBridge.HookRegistry.shared
    @State private var selectedPluginTabId: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header: Back & Server Info
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                        Text("Servers")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(.plain)

                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(statusColor.opacity(0.15))

                        Image(systemName: server.type == .remote ? "server.rack" : "desktopcomputer")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.axTextPrimary)

                        Text(server.host)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.axTextMuted)
                            .monospaced()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)

            Divider()
                .padding(.horizontal, AXSpacing.md)

            // Navigation
            ScrollView {
                VStack(spacing: AXSpacing.xs) {
                    // Standard tabs
                    ForEach(DashboardTab.allCases) { tab in
                        SidebarNavRow(
                            title: tab.rawValue,
                            icon: tab.icon,
                            isSelected: viewModel.selectedTab == tab && selectedPluginTabId == nil,
                            isPlugin: false,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedPluginTabId = nil
                                    viewModel.selectedPluginTab = nil
                                    viewModel.selectedTab = tab
                                }
                            }
                        )
                    }

                    // AevonXCore.Plugin-injected sidebar tabs
                    let pluginTabs = hookRegistry.plugins(for: .sidebarTabs)
                    if !pluginTabs.isEmpty {
                        Divider()
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xs)

                        HStack {
                            Text("Extensions")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.axTextMuted)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.bottom, 2)

                        ForEach(pluginTabs) { plugin in
                            SidebarNavRow(
                                title: plugin.name,
                                icon: plugin.icon ?? "puzzlepiece",
                                isSelected: selectedPluginTabId == plugin.id,
                                isPlugin: true,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPluginTabId = plugin.id
                                        viewModel.selectedPluginTab = plugin
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(AXSpacing.md)
            }

            Spacer()

            // Footer: Connection & Quick Controls
            VStack(spacing: AXSpacing.md) {
                Divider()

                // Status & Connection Toggle
                HStack {
                    DashboardConnectionStatusIndicator(viewModel: viewModel)
                    Spacer()

                    Button(action: {
                        Task {
                            if viewModel.isConnected {
                                await viewModel.disconnect()
                            } else {
                                await viewModel.connect()
                            }
                        }
                    }) {
                        Text(viewModel.isConnected ? "Disconnect" : "Connect")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(viewModel.isConnected ? .axError : .axSuccess)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(viewModel.isConnected ? Color.axError.opacity(0.1) : Color.axSuccess.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isConnecting)
                }
                .padding(.horizontal, AXSpacing.xs)

                // Quick Action Grid
                HStack(spacing: AXSpacing.sm) {
                    SidebarActionBtn(icon: "terminal", color: .axTextSecondary, isEnabled: viewModel.isConnected) {
                        selectedPluginTabId = nil
                        viewModel.selectedPluginTab = nil
                        viewModel.selectedTab = .terminal
                    }

                    SidebarActionBtn(icon: "arrow.clockwise", color: .axWarning, isEnabled: viewModel.isConnected) {
                        viewModel.isRestartConfirming = true
                    }

                    SidebarActionBtn(icon: "power", color: .axError, isEnabled: viewModel.isConnected) {
                        viewModel.isShutdownConfirming = true
                    }
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface.opacity(0.3))
        }
        .onChange(of: viewModel.isConnected) {
            if viewModel.isConnected {
                Task {
                    await AevonXCoreBridge.HookLoader.shared.load(serverId: server.id.uuidString)
                }
            } else {
                AevonXCoreBridge.HookLoader.shared.unload()
            }
        }
    }

    private var statusColor: Color {
        switch server.status {
        case .online: return .axSuccess
        case .offline: return .axTextMuted
        case .maintenance: return .axWarning
        case .error: return .axError
        }
    }
}

// MARK: - Sidebar Nav Row

private struct SidebarNavRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isPlugin: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                    .frame(width: 20)

                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()

                if isPlugin {
                    // AevonXCore.Plugin badge
                    HStack(spacing: 2) {
                        Image(systemName: "puzzlepiece.fill")
                            .font(.system(size: 7))
                        Text("AevonXCore.Plugin")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.axBorder, lineWidth: 0.5)
                            )
                    )
                } else if isSelected {
                    Circle()
                        .fill(Color.axAccentBlue)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar Action Button

private struct SidebarActionBtn: View {
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isEnabled ? color : .axTextMuted.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isEnabled ? Color.axSurface : Color.axSurface.opacity(0.3))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(isEnabled ? Color.axBorder : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Connection Status Indicator

struct DashboardConnectionStatusIndicator: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.4 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)

            Text(statusText)
                .font(AXTypography.caption2)
                .foregroundColor(statusColor)
        }
        .onChange(of: viewModel.isReconnecting) { _, isReconnecting in
            if isReconnecting {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.default) {
                    isPulsing = false
                }
            }
        }
    }

    private var statusColor: Color {
        if viewModel.isConnected { return .axSuccess }
        if viewModel.isReconnecting { return .axWarning }
        if viewModel.isConnecting { return .axWarning }
        return .axTextMuted
    }

    private var statusText: String {
        if viewModel.isConnected { return "Connected" }
        if viewModel.isReconnecting { return "Reconnecting..." }
        if viewModel.isConnecting { return "Connecting..." }
        return "Disconnected"
    }
}

