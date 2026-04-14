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
            if authViewModel.isCheckingAuth {
                // Show loading while checking Keychain token on launch
                Color.axBackground
                    .overlay(ProgressView())
            } else if AppLocationService.shared.shouldPrompt {
                // First: prompt to move to /Applications (from DMG or Downloads)
                MoveToApplicationsView()
            } else if !authViewModel.isAuthenticated {
                // Not logged in — show profile view with login/register
                ProfileView()
            } else if isCheckingKey {
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
            // Inject API fetcher + SSH BEFORE anything else
            await SubscriptionManager.shared.setApiFetcher { baseURL, token in
                await APIBridge.shared.fetchSubscriptionStatusAsync(baseURL: baseURL, token: token)
            }
            await SystemControlService.shared.setSSHService(SSHBridge.shared)

            // Initialize Go Core engine
            CoreBridge.shared.initialize()
            debugLog("🟢 Go Core v\(CoreBridge.shared.version()) initialized")

            // Sync network settings to Go bridge on launch
            AppSettingsManager.shared.syncNetworkSettingsToCore()

            // Set device fingerprint early so key refresh works from any code path
            if let deviceFP = await DeviceIdentifier.shared.getDeviceID() {
                await DeviceKeyManager.shared.setDeviceFingerprint(deviceFP)
            }

            // Configure device key manager and load cached keys
            await DeviceKeyManager.shared.setApiFetcher { endpoint, deviceFP in
                let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
                guard let token = await AuthService.shared.getToken() else { return "" }
                return await APIBridge.shared.fetchDeviceKeysAsync(
                    baseURL: baseURL, token: token, fingerprint: deviceFP
                )
            }
            let cachedCount = await DeviceKeyManager.shared.loadCachedKeys()
            if cachedCount > 0 {
                debugLog("🔑 Loaded \(cachedCount) cached device keys into Go Core")
            }

            await checkEncryptionKey()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                Task { await checkEncryptionKey() }
            }
        }
        // Listen for menu bar navigation commands (⌘1, ⌘2, ⌘,)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToItem)) { notification in
            if let item = notification.object as? NavigationItem {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedNavigation = item
                }
            }
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
                                    debugLog("[ContentView] Presenting ServerDashboardView for: \(server.name)")
                                }
                                .onDisappear {
                                    debugLog("[ContentView] ServerDashboardView disappeared")
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

// MARK: - Navigation Notification

extension Notification.Name {
    static let navigateToItem = Notification.Name("AevonXNavigateToItem")
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
