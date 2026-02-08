//
//  ServerDashboardView.swift
//  AevonX
//
//  Server Management Dashboard with tab navigation
//  Integrated with ServerConnectionViewModel for real-time SSH connection
//

import SwiftUI
import AevonXCore

// DashboardTab is now defined in ServerConnectionViewModel.swift

struct ServerDashboardView: View {
    let server: Server
    let serverId: String
    @StateObject private var viewModel: ServerConnectionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    init(server: Server, serverId: String, serverListViewModel: ServerListViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        _viewModel = StateObject(wrappedValue: ServerConnectionViewModel(
            server: server,
            serverId: serverId,
            serverListViewModel: serverListViewModel
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with connection status
            DashboardHeader(
                server: server,
                viewModel: viewModel,
                dismiss: dismiss
            )
            
            // Tab Navigation
            DashboardTabBar(selectedTab: $viewModel.selectedTab)
            
            Divider()
                .background(Color.axBorder)
            
            // Content Area
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    switch viewModel.selectedTab {
                    case .overview:
                        OverviewTab(server: server, serverId: serverId, viewModel: viewModel)
                    case .websites:
                        WebsitesTab()
                    case .databases:
                        ModernDatabasesTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                    case .applications:
                        ApplicationsTab()
                    case .files:
                        FilesTab()
                    case .settings:
                        ServerSettingsTab(server: server)
                    }
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // Auto-connect when dashboard appears if not already connected
            print("[ServerDashboardView] onAppear - isConnected: \(viewModel.isConnected), isConnecting: \(viewModel.isConnecting)")
            Task {
                if !viewModel.isConnected && !viewModel.isConnecting {
                    print("[ServerDashboardView] Auto-connecting...")
                    await viewModel.connect()
                }
            }
        }
        .onDisappear {
            // Disconnect when dashboard closes
            Task {
                await viewModel.disconnect()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.appWillEnterForeground()
            case .background, .inactive:
                viewModel.appDidEnterBackground()
            @unknown default:
                break
            }
        }
        .alert("Connection Error", isPresented: $viewModel.showConnectionError) {
            Button("Retry") {
                Task {
                    await viewModel.connect()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.connectionError ?? "Unknown error")
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeader: View {
    let server: Server
    @ObservedObject var viewModel: ServerConnectionViewModel
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.lg) {
                // Back Button
                Button(action: { dismiss() }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .frame(height: 20)
                    .background(Color.axBorder)
                
                // Server Info
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: server.type == .remote ? "server.rack" : "desktopcomputer")
                            .font(.system(size: 18))
                            .foregroundColor(statusColor)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(server.name)
                            .font(AXTypography.title)
                            .foregroundColor(.axTextPrimary)
                        
                        HStack(spacing: AXSpacing.sm) {
                            // Connection Status Indicator
                            ConnectionStatusIndicator(viewModel: viewModel)
                            
                            Text("•")
                                .foregroundColor(.axTextMuted)
                            
                            Text(server.host)
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextTertiary)
                            
                            if let os = server.os {
                                Text("•")
                                    .foregroundColor(.axTextMuted)
                                
                                Text(os)
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextTertiary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Connection Status Badge
                ConnectionStatusBadge(viewModel: viewModel)
                    .padding(.trailing, AXSpacing.md)
                
                // Quick Actions
                HStack(spacing: AXSpacing.sm) {
                    Button(action: {
                        Task {
                            if viewModel.isConnected {
                                await viewModel.disconnect()
                            } else {
                                await viewModel.connect()
                            }
                        }
                    }) {
                        Image(systemName: viewModel.isConnected ? "xmark.circle" : "bolt.circle")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.isConnected ? .axError : .axSuccess)
                            .frame(width: 36, height: 36)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(viewModel.isConnected ? Color.axError : Color.axSuccess, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(viewModel.isConnected ? "Disconnect" : "Connect")
                    
                    Button(action: {}) {
                        Image(systemName: "terminal")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.isConnected ? .axTextSecondary : .axTextMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Open Terminal")
                    .disabled(!viewModel.isConnected)
                    
                    Button(action: {
                        Task {
                            await viewModel.refreshStats()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.isConnected ? .axTextSecondary : .axTextMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Refresh")
                    .disabled(!viewModel.isConnected)
                    
                    Button(action: {}) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "power")
                            Text("Reboot")
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axError)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axError.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axError.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!viewModel.isConnected)
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.lg)
            
            Divider()
                .background(Color.axBorder)
        }
        .background(Color.axBackground)
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

// MARK: - Connection Status Indicator

struct ConnectionStatusIndicator: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var isAnimating = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(connectionStatusColor.opacity(0.3), lineWidth: 2)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                )
            
            Text(connectionStatusText)
                .font(AXTypography.caption)
                .foregroundColor(connectionStatusColor)
        }
        .onChange(of: viewModel.isConnecting) { _, isConnecting in
            updateAnimation(isConnecting: isConnecting)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && viewModel.isConnecting {
                updateAnimation(isConnecting: true)
            } else if newPhase != .active {
                isAnimating = false
            }
        }
        .onAppear {
            updateAnimation(isConnecting: viewModel.isConnecting)
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    private func updateAnimation(isConnecting: Bool) {
        if isConnecting {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        } else {
            withAnimation(.default) {
                isAnimating = false
            }
        }
    }
    
    private var connectionStatusColor: Color {
        if viewModel.isConnected {
            return .axSuccess
        } else if viewModel.isConnecting {
            return .axWarning
        } else if viewModel.connectionError != nil {
            return .axError
        } else {
            return .axTextMuted
        }
    }
    
    private var connectionStatusText: String {
        if viewModel.isConnected {
            return "Connected"
        } else if viewModel.isConnecting {
            return viewModel.connectionStage.rawValue
        } else if viewModel.connectionError != nil {
            return "Failed"
        } else {
            return "Disconnected"
        }
    }
}

// MARK: - Connection Status Badge

struct ConnectionStatusBadge: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            if viewModel.isConnecting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .axWarning))
                    .scaleEffect(0.6)
                
                Text("\(Int(viewModel.connectionProgress * 100))%")
                    .font(AXTypography.caption)
                    .foregroundColor(.axWarning)
            } else if viewModel.isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.axSuccess)
                    .font(.system(size: 12))
                
                Text("Live")
                    .font(AXTypography.caption)
                    .foregroundColor(.axSuccess)
            } else if let _ = viewModel.connectionError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.axError)
                    .font(.system(size: 12))
                
                Text("Error")
                    .font(AXTypography.caption)
                    .foregroundColor(.axError)
            }
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(backgroundColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(backgroundColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var backgroundColor: Color {
        if viewModel.isConnected {
            return .axSuccess
        } else if viewModel.isConnecting {
            return .axWarning
        } else if viewModel.connectionError != nil {
            return .axError
        } else {
            return .axTextMuted
        }
    }
}

// MARK: - Dashboard Tab Bar

struct DashboardTabBar: View {
    @Binding var selectedTab: DashboardTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.xs) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    DashboardTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.sm)
        }
        .background(Color.axBackground)
    }
}

struct DashboardTabItem: View {
    let tab: DashboardTab
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch tab {
        case .overview: return "chart.line.uptrend.xyaxis"
        case .websites: return "globe"
        case .databases: return "cylinder.split.1x2"
        case .applications: return "square.stack.3d.up"
        case .files: return "folder"
        case .settings: return "gearshape"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(tab.rawValue)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axSurfaceHover : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axBorder : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ServerDashboardView(
        server: Server.placeholder(name: "Preview Server"),
        serverId: "preview-server-id"
    )
    .background(Color.axBackground)
}
