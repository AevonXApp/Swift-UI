//
//  DashboardSidebar.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

struct DashboardSidebar: View {
    let server: Server
    @ObservedObject var viewModel: ServerConnectionViewModel
    let onBack: () -> Void

    @ObservedObject private var hookRegistry = AevonXCoreBridge.HookRegistry.shared
    @State private var selectedPluginTabId: String? = nil
    @State private var isHoveringBack = false
    @State private var serverIconHovered = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            navigationSection
            Spacer(minLength: 0)
            footerSection
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back button
            Button(action: {
                Task {
                    if viewModel.isConnected {
                        await viewModel.disconnect()
                    }
                }
                onBack()
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Servers")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(isHoveringBack ? .axTextPrimary : .axTextTertiary)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isHoveringBack ? Color.axSurface : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringBack = $0 }
            .padding(.bottom, AXSpacing.lg)

            // Server identity card
            serverIdentityCard
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.md)
    }

    private var serverIdentityCard: some View {
        HStack(spacing: AXSpacing.md) {
            // Server icon with branded background
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [serverBrandColor, serverBrandColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: serverBrandColor.opacity(0.3), radius: 8, y: 4)

                Image(systemName: server.iconName.isEmpty ? (server.type == .remote ? "server.rack" : "desktopcomputer") : server.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 42, height: 42)
            .scaleEffect(serverIconHovered ? 1.05 : 1.0)
            .onHover { serverIconHovered = $0 }
            .animation(.spring(response: 0.3), value: serverIconHovered)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(server.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)

                HStack(spacing: AXSpacing.xs) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)

                    Text(server.host)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axBorder.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Navigation

    private var navigationSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AXSpacing.xl) {
                ForEach(DashboardTab.categorized, id: \.0) { category, tabs in
                    sidebarGroup(category: category, tabs: tabs)
                }

                // Plugin-injected sidebar tabs
                pluginSection
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.md)
        }
    }

    private func sidebarGroup(category: DashboardTabCategory, tabs: [DashboardTab]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            // Category label
            Text(category.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.axTextMuted.opacity(0.6))
                .tracking(1.2)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.bottom, AXSpacing.xxxs)

            ForEach(tabs) { tab in
                SidebarNavItem(
                    title: tab.rawValue,
                    icon: tab.icon,
                    accentColor: tab.accentColor,
                    isSelected: viewModel.selectedTab == tab && selectedPluginTabId == nil,
                    badge: badgeForTab(tab),
                    action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedPluginTabId = nil
                            viewModel.selectedPluginTab = nil
                            viewModel.selectedTab = tab
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var pluginSection: some View {
        let pluginTabs = hookRegistry.plugins(for: .sidebarTabs)
        if !pluginTabs.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text("EXTENSIONS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextMuted.opacity(0.6))
                    .tracking(1.2)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.bottom, AXSpacing.xxxs)

                ForEach(pluginTabs) { plugin in
                    SidebarNavItem(
                        title: plugin.name,
                        icon: plugin.icon ?? "puzzlepiece",
                        accentColor: .pink,
                        isSelected: selectedPluginTabId == plugin.id,
                        badge: nil,
                        isPlugin: true,
                        action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedPluginTabId = plugin.id
                                viewModel.selectedPluginTab = plugin
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: AXSpacing.sm) {
            // Thin separator
            Rectangle()
                .fill(Color.axBorder.opacity(0.2))
                .frame(height: 0.5)
                .padding(.horizontal, AXSpacing.md)

            // Connection status row
            HStack(spacing: AXSpacing.sm) {
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
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.isConnected ? .axError : .axSuccess)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxs)
                        .background(
                            Capsule()
                                .fill(viewModel.isConnected ? Color.axError.opacity(0.1) : Color.axSuccess.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.isConnected ? Color.axError.opacity(0.2) : Color.axSuccess.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isConnecting)
            }
            .padding(.horizontal, AXSpacing.lg)

            // Quick action buttons
            HStack(spacing: AXSpacing.sm) {
                SidebarQuickAction(icon: "terminal", label: "Terminal", color: .green, isEnabled: viewModel.isConnected) {
                    selectedPluginTabId = nil
                    viewModel.selectedPluginTab = nil
                    viewModel.selectedTab = .terminal
                }

                SidebarQuickAction(icon: "arrow.clockwise", label: "Restart", color: .axWarning, isEnabled: viewModel.isConnected) {
                    viewModel.isRestartConfirming = true
                }

                SidebarQuickAction(icon: "power", label: "Power", color: .axError, isEnabled: viewModel.isConnected) {
                    viewModel.isShutdownConfirming = true
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.bottom, AXSpacing.lg)
        }
        .padding(.top, AXSpacing.sm)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.axSurface.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch server.status {
        case .online: return .axSuccess
        case .offline: return .axTextMuted
        case .maintenance: return .axWarning
        case .error: return .axError
        }
    }

    private var serverBrandColor: Color {
        if !server.customColor.isEmpty {
            return colorFromHex(server.customColor)
        }
        return statusColor
    }

    private func colorFromHex(_ hex: String) -> Color {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard clean.count == 6, let val = UInt64(clean, radix: 16) else { return .axAccentBlue }
        return Color(
            red: Double((val >> 16) & 0xFF) / 255.0,
            green: Double((val >> 8) & 0xFF) / 255.0,
            blue: Double(val & 0xFF) / 255.0
        )
    }

    private func badgeForTab(_ tab: DashboardTab) -> String? {
        switch tab {
        case .websites:
            if viewModel.isConnected { return nil }
            return nil
        default: return nil
        }
    }
}

// MARK: - Sidebar Nav Item

private struct SidebarNavItem: View {
    let title: String
    let icon: String
    let accentColor: Color
    let isSelected: Bool
    var badge: String? = nil
    var isPlugin: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon with colored background when selected
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? accentColor.opacity(0.15) : (isHovered ? Color.axSurface : Color.clear))
                        .frame(width: 26, height: 26)

                    Image(systemName: icon)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? accentColor : (isHovered ? .axTextSecondary : .axTextMuted))
                }

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axTextPrimary : (isHovered ? .axTextSecondary : .axTextSecondary))

                Spacer(minLength: 0)

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(accentColor.opacity(0.12))
                        )
                }

                if isPlugin {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }

                if isSelected {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accentColor)
                        .frame(width: 3, height: 14)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? accentColor.opacity(0.06) : (isHovered ? Color.axSurface.opacity(0.5) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Sidebar Quick Action

private struct SidebarQuickAction: View {
    let icon: String
    let label: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isEnabled ? (isHovered ? color : .axTextSecondary) : .axTextMuted.opacity(0.3))

                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isEnabled ? (isHovered ? color : .axTextMuted) : .axTextMuted.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isHovered && isEnabled ? color.opacity(0.08) : Color.axSurface.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(isHovered && isEnabled ? color.opacity(0.2) : Color.axBorder.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Connection Status Indicator

struct DashboardConnectionStatusIndicator: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0.5 : 1.0)

            Text(statusText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
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
