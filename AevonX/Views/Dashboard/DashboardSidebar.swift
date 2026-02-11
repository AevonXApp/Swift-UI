
import SwiftUI
import AevonXCore

struct DashboardSidebar: View {
    let server: Server
    @ObservedObject var viewModel: ServerConnectionViewModel
    let onBack: () -> Void
    
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
                    ForEach(DashboardTab.allCases) { tab in
                        SidebarNavRow(
                            title: tab.rawValue,
                            icon: tab.icon,
                            isSelected: viewModel.selectedTab == tab,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.selectedTab = tab
                                }
                            }
                        )
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
                    
                    // Connection Toggle
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
                        // Open Terminal
                    }
                    
                    SidebarActionBtn(icon: "arrow.clockwise", color: .axTextSecondary, isEnabled: viewModel.isConnected) {
                        Task { await viewModel.refreshStats() }
                    }
                    
                    SidebarActionBtn(icon: "power", color: .axError, isEnabled: viewModel.isConnected) {
                        // Reboot
                    }
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface.opacity(0.3))
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

private struct SidebarNavRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
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
                
                if isSelected {
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

// Minimal status indicator for sidebar
struct DashboardConnectionStatusIndicator: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(AXTypography.caption2)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        if viewModel.isConnected { return .axSuccess }
        if viewModel.isConnecting { return .axWarning }
        return .axTextMuted
    }
    
    private var statusText: String {
        if viewModel.isConnected { return "Connected" }
        if viewModel.isConnecting { return "Connecting..." }
        return "Disconnected"
    }
}
