//
//  ContentView.swift
//  AevonX
//
//  Main content view integrating all components with consistent padding
//

import SwiftUI
import AevonXCoreBridge

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var updateService: AppUpdateService
    @State private var selectedNavigation: NavigationItem = .remoteFleet
    @StateObject private var serverListViewModel = ServerListViewModel()
    @State private var selectedServer: Server? = nil
    @State private var showServerDashboard = false
    @State private var showAddServer = false

    /// Update sheet binding
    private var showUpdateSheet: Binding<Bool> {
        Binding(
            get: { updateService.state == .updateAvailable && !updateService.isForceUpdate },
            set: { if !$0 { updateService.state = .idle } }
        )
    }

    /// Encryption key gate state
    @State private var hasEncryptionKey = false
    @State private var isCheckingKey = true
    
    var body: some View {
        Group {
            if isCheckingKey {
                // Brief loading while checking Keychain
                Color.axBackground
                    .overlay(ProgressView())
            } else if !hasEncryptionKey {
                // BLOCKING: No encryption key — force setup or sign out
                EncryptionGateView(
                    onComplete: {
                        // Delay transition to let VaultSetupView finish cleanup
                        DispatchQueue.main.async {
                            hasEncryptionKey = true
                        }
                    },
                    onSignOut: {
                        Task { await authViewModel.logout() }
                    }
                )
            } else if settings.appLockEnabled && settings.isLocked {
                // App is locked — show lock screen
                LockScreenView()
                    .environmentObject(settings)
            } else if updateService.isForceUpdate && updateService.state != .idle {
                // Force update — blocking, cannot dismiss
                ForceUpdateView(updateService: updateService)
            } else {
                // Normal app content
                mainContentView
            }
        }
        .sheet(isPresented: showUpdateSheet) {
            UpdateSheet(updateService: updateService)
        }
        .task {
            // Inject API fetcher + SSH BEFORE anything else (eliminates race condition)
            await SubscriptionManager.shared.setApiFetcher { baseURL, token in
                await APIBridge.shared.fetchSubscriptionStatusAsync(baseURL: baseURL, token: token)
            }
            await SystemControlService.shared.setSSHService(SSHBridge.shared)
            
            // Initialize Go Core engine
            CoreBridge.shared.initialize()
            print("🟢 Go Core v\(CoreBridge.shared.version()) initialized")

            // Sync network settings to Go bridge on launch
            AppSettingsManager.shared.syncNetworkSettingsToCore()

            await checkEncryptionKey()
        }
    }
    
    // MARK: - Encryption Key Check
    
    private func checkEncryptionKey() async {
        isCheckingKey = true
        hasEncryptionKey = EncryptionKeyStore.shared.hasKey()
        isCheckingKey = false
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
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
        .preferredColorScheme(ThemeEngine.shared.colorScheme)
        .onChange(of: serverListViewModel.needsLogin) { _, needsLogin in
            if needsLogin {
                selectedNavigation = .userProfile
                serverListViewModel.needsLogin = false
            }
        }
        .sheet(isPresented: $showAddServer) {
            AddServerView { request in
                Task {
                    await serverListViewModel.addServer(request)
                }
            }
        }
    }
}

// MARK: - Encryption Gate View

/// Full-screen blocking view shown when no encryption key exists.
/// Cannot be dismissed — user must set up key or sign out.
struct EncryptionGateView: View {
    var onComplete: () -> Void
    var onSignOut: () -> Void
    
    var body: some View {
        VaultSetupView(
            onComplete: onComplete,
            onSignOut: onSignOut
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
        .preferredColorScheme(ThemeEngine.shared.colorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .frame(width: 1400, height: 900)
}

