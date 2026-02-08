//
//  ContentView.swift
//  AevonX
//
//  Main content view integrating all components with consistent padding
//

import SwiftUI
import AevonXCore

struct ContentView: View {
    @State private var selectedNavigation: NavigationItem = .remoteFleet
    @StateObject private var serverListViewModel = ServerListViewModel()
    @State private var selectedServer: Server? = nil
    @State private var showServerDashboard = false
    @State private var showAddServer = false
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Glassmorphism Sidebar
                SidebarView(
                    selectedItem: $selectedNavigation,
                    selectedServer: $selectedServer
                )
                
                Divider()
                    .background(Color.axBorder)
                
                // Main Content Area
                Group {
                    switch selectedNavigation {
                    case .remoteFleet:
                        RemoteFleetView(
                            viewModel: serverListViewModel,
                            selectedServer: $selectedServer,
                            showAddServer: $showAddServer,
                            showServerDashboard: $showServerDashboard
                        )
                        .navigationDestination(isPresented: $showServerDashboard) {
                            // Note: SwiftUI evaluates this content even when not presented
                            // selectedServer being nil during evaluation is expected, not an error
                            if let server = selectedServer {
                                ServerDashboardView(
                                    server: server,
                                    serverId: server.id.uuidString,
                                    serverListViewModel: serverListViewModel
                                )
                                .onAppear {
                                    print("[ContentView] Presenting ServerDashboardView for: \(server.name)")
                                }
                                .onDisappear {
                                    print("[ContentView] ServerDashboardView disappeared")
                                    selectedServer = nil
                                }
                            } else {
                                // This is normal during SwiftUI view evaluation
                                EmptyView()
                            }
                        }
                        
                    case .localWorkspace:
                        WorkspaceView()
                        
                    case .userProfile:
                        ProfileView()
                        
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axBackground)
            }
        }
        .background(Color.axBackground)
        .overlay(alignment: .topTrailing) {
            GlobalToastOverlay()
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddServer) {
            AddServerView { request in
                Task {
                    await serverListViewModel.addServer(request)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1400, height: 900)
}
