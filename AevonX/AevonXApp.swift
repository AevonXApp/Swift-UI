//
//  AevonXApp.swift
//  AevonX
//
//  Main app entry point with lifecycle handlers and SSHConnectionService integration
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

@main
struct AevonXApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    // Go Core handles all SSH connections — CoreShutdown disconnects everything
    // No need to hold a local sshService reference
    
    init() {
        // Log app startup information
        print("[AevonXApp] INFO: AevonX App Started - v\(BuildConfiguration.appVersion) (\(BuildConfiguration.buildNumber)) on \(BuildConfiguration.platform)")
        print("[AevonXApp] INFO: API URL: \(AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL)")
        
        // Inject API fetcher into AevonXCore.SubscriptionManager (breaks circular dependency)
        // Inject Go SSH into AevonXCore.SystemControlService
        Task {
            await AevonXCore.SubscriptionManager.shared.setApiFetcher { baseURL, token in
                await APIBridge.shared.fetchSubscriptionStatusAsync(baseURL: baseURL, token: token)
            }
            await AevonXCore.SystemControlService.shared.setSSHService(SSHBridge.shared)
        }
        
        // Setup app lifecycle notifications
        setupLifecycleNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Initialize auth state when app appears (deferred from init)
                    authViewModel.initializeIfNeeded()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 900)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About AevonX") {
                    // Show about panel
                }
            }
            
            CommandMenu("Server") {
                Button("Connect") {
                    // Connect to selected server
                }
                .keyboardShortcut("N", modifiers: .command)
                
                Button("Disconnect") {
                    // Disconnect from server
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Open Terminal") {
                    // Open terminal for selected server
                }
                .keyboardShortcut("T", modifiers: .command)
            }
            
            CommandMenu("View") {
                Button("Remote Fleet") {
                    // Switch to remote fleet view
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Local Workspace") {
                    // Switch to workspace view
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Profile") {
                    // Switch to profile view
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Divider()
                
                Button("Settings...") {
                    // Open settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    // MARK: - Lifecycle Management
    
    /// Handles scene phase changes (foreground/background)
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App is in foreground
            Task {
                await appWillEnterForeground()
            }
            
        case .background:
            // App is in background
            Task {
                await appDidEnterBackground()
            }
            
        case .inactive:
            // App is inactive (transitioning)
            break
            
        @unknown default:
            break
        }
    }
    
    /// Called when app enters foreground
    private func appWillEnterForeground() async {
        AevonXCore.CoreLogger.shared.info("App entering foreground", module: "AppLifecycle")
        
        // Resume any suspended operations
        await resumeBackgroundOperations()
    }
    
    /// Called when app enters background
    private func appDidEnterBackground() async {
        AevonXCore.CoreLogger.shared.info("App entering background", module: "AppLifecycle")
        
        // Pause non-essential operations
        await pauseForegroundOperations()
    }
    
    /// Sets up platform-specific lifecycle notifications
    private func setupLifecycleNotifications() {
        #if os(macOS)
        // macOS sleep/wake notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.deviceWillSleep()
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.deviceDidWake()
            }
        }
        
        // App termination
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.appWillTerminate()
            }
        }
        #endif
        
        // Handle authentication state changes
        setupAuthStateMonitoring()
    }
    
    /// Sets up monitoring for authentication state changes
    private func setupAuthStateMonitoring() {
        // Monitor for logout events to clean up connections
        NotificationCenter.default.addObserver(
            forName: .init("AevonXUserDidLogout"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.handleUserLogout()
            }
        }
    }
    
    // MARK: - Device Sleep/Wake
    
    /// Called when device is going to sleep.
    /// We do NOT disconnect here — the SSH session may survive short sleeps.
    /// If the connection dies during sleep, ConnectionHealthMonitor will detect
    /// it on wake and trigger automatic reconnection.
    private func deviceWillSleep() async {
        AevonXCore.CoreLogger.shared.info("Device going to sleep — keeping connections alive", module: "AppLifecycle")
    }
    
    /// Called when device wakes up
    /// Note: Connections will need to be manually reconnected by the user
    private func deviceDidWake() async {
        AevonXCore.CoreLogger.shared.info("Device woke up - connections were disconnected during sleep", module: "AppLifecycle")
        // TODO: Implement suspend/resume in SSHConnectionService if needed
        // For now, connections were disconnected during sleep and need manual reconnection
    }
    
    // MARK: - App Termination
    
    /// Called when app is about to terminate
    private func appWillTerminate() async {
        AevonXCore.CoreLogger.shared.info("App terminating - cleaning up connections", module: "AppLifecycle")
        
        // Disconnect all SSH connections via Go Core
        CoreBridge.shared.shutdown()
    }
    
    // MARK: - User Actions
    
    /// Called when user logs out
    private func handleUserLogout() async {
        AevonXCore.CoreLogger.shared.info("User logged out - clearing connections", module: "AppLifecycle")
        
        // Disconnect all SSH connections via Go Core
        CoreBridge.shared.shutdown()
    }
    
    // MARK: - Operation Management
    
    /// Resumes operations that were paused in background
    private func resumeBackgroundOperations() async {
        // Resume stats polling, etc.
        AevonXCore.CoreLogger.shared.debug("Resuming background operations", module: "AppLifecycle")
    }
    
    /// Pauses operations when entering background
    private func pauseForegroundOperations() async {
        // Pause stats polling, etc.
        AevonXCore.CoreLogger.shared.debug("Pausing foreground operations", module: "AppLifecycle")
    }
}

// MARK: - Build Configuration

/// Build configuration information
enum BuildConfiguration {
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var platform: String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #else
        return "Unknown"
        #endif
    }
}
