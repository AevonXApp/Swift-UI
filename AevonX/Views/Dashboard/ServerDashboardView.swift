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
        HStack(spacing: 0) {
            // Left Global Sidebar
            DashboardSidebar(
                server: server,
                viewModel: viewModel,
                onBack: { dismiss() }
            )
            .frame(width: 260)
            .background(Color.axSurface.opacity(0.4))
            
            Divider()
                .background(Color.axBorder)
            
            // Right Content Area
            VStack(spacing: 0) {
                // Main Content
                ScrollView {
                    VStack(spacing: AXSpacing.xl) {
                        switch viewModel.selectedTab {
                        case .overview:
                            OverviewTab(server: server, serverId: serverId, viewModel: viewModel)
                        case .websites:
                            ModernWebsitesTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .databases:
                            ModernDatabasesTab(server: server, serverId: serverId, connectionViewModel: viewModel)
                        case .applications:
                            ApplicationsTab(server: server, serverId: serverId, connectionViewModel: viewModel)
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
