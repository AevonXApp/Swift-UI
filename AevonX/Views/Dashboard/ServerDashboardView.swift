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
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    init(server: Server, serverId: String, serverListViewModel: ServerListViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        let vm = ServerConnectionViewModel(
            server: server,
            serverId: serverId
        )
        vm.serverListViewModel = serverListViewModel
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Left Global Sidebar
            DashboardSidebar(
                server: server,
                viewModel: viewModel,
                onBack: { dismiss() }
            )
            .frame(minWidth: 260)
            .background(Color.axSurface.opacity(0.4))
        } detail: {
            // Right Content Area — renders directly, no NavigationStack,
            // to avoid macOS safe-area gap from NavigationStack's implicit toolbar.
            if let configPlugin = viewModel.activeConfigPlugin {
                PluginConfigurationView(
                    viewModel: PluginConfigurationViewModel(plugin: configPlugin, serverId: serverId),
                    onBack: { viewModel.activeConfigPlugin = nil }
                )
            } else {
                VStack(spacing: 0) {
                    if let pluginTab = viewModel.selectedPluginTab {
                        if pluginTab.component == .dataTable || pluginTab.component == .chart {
                            PluginComponentRenderer(
                                plugin: pluginTab,
                                serverId: serverId,
                                context: [:]
                            )
                        } else {
                            PluginPageComponent(
                                plugin: pluginTab,
                                serverId: serverId,
                                context: [:]
                            )
                        }
                    } else {
                        switch viewModel.selectedTab {
                        case .overview:
                            OverviewTab(server: server, serverId: serverId, viewModel: viewModel)
                        case .websites:
                            ModernWebsitesTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .databases:
                            ModernDatabasesTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .applications:
                            ApplicationsTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .docker:
                            DockerDetailView(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .terminal:
                            TerminalTab(server: server, serverId: serverId, viewModel: viewModel)
                        case .files:
                            FilesTab(serverId: serverId, connectionViewModel: viewModel)
                        case .security:
                            SecurityTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .cron:
                            CronTab(serverId: serverId, connectionViewModel: viewModel)
                        case .plugins:
                            PluginsTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .settings:
                            ServerSettingsTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axBackground)
                #if os(macOS)
                .navigationTitle("")
                .toolbar(.hidden)
                .toolbarBackground(.hidden)
                .ignoresSafeArea(.all, edges: .top)
                #endif
            }
        }
        .background(Color.axBackground)
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: viewModel.selectedTab) { old, newValue in
            viewModel.activeConfigPlugin = nil
            viewModel.selectedPluginTab = nil
        }
        .onAppear {
            // Auto-connect when dashboard appears if not already connected
            CoreLogger.shared.debug("onAppear - isConnected: \(viewModel.isConnected), isConnecting: \(viewModel.isConnecting)", module: "ServerDashboardView")
            Task {
                if !viewModel.isConnected && !viewModel.isConnecting {
                    CoreLogger.shared.debug("Auto-connecting...", module: "ServerDashboardView")
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
        .overlay {
            if viewModel.isRestartConfirming {
                AXConfirmationDialog(
                    title: "Restart Server?",
                    message: "This will reboot the host machine. All active sessions and services will be disconnected.",
                    icon: "arrow.clockwise",
                    iconColor: .axWarning,
                    actionTitle: "Restart",
                    actionColor: .axWarning,
                    note: "The server will be unavailable for 2-3 minutes during reboot.",
                    onConfirm: {
                        viewModel.isRestartConfirming = false
                        Task { await viewModel.rebootServer() }
                    },
                    onCancel: { viewModel.isRestartConfirming = false }
                )
            }
            
            if viewModel.isShutdownConfirming {
                AXConfirmationDialog(
                    title: "Shutdown Server?",
                    message: "This will power off the host machine. You will need manual access to power it back on.",
                    icon: "power",
                    iconColor: .axError,
                    actionTitle: "Shutdown",
                    actionColor: .axError,
                    note: "Ensure you have out-of-band management access to restart the server.",
                    onConfirm: {
                        viewModel.isShutdownConfirming = false
                        Task { await viewModel.shutdownServer() }
                    },
                    onCancel: { viewModel.isShutdownConfirming = false }
                )
            }
        }
    }
}

// MARK: - Shared Connection Status Components

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

#Preview {
    ServerDashboardView(
        server: Server.placeholder(name: "Preview Server"),
        serverId: "preview-server-id"
    )
    .background(Color.axBackground)
}
