//
//  AevonXApp.swift
//  AevonX
//
//  Main app entry point with lifecycle handlers and SSHConnectionService integration
//

import SwiftUI
import AevonXCoreBridge

@main
struct AevonXApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsManager = AppSettingsManager.shared
    @StateObject private var updateService = AppUpdateService.shared
    @Environment(\.scenePhase) private var scenePhase

    // Go Core handles all SSH connections — CoreShutdown disconnects everything
    // No need to hold a local sshService reference

    init() {
        // Log app startup information
        debugLog("[AevonXApp] INFO: AevonX App Started - v\(BuildConfiguration.appVersion) (\(BuildConfiguration.buildNumber)) on \(BuildConfiguration.platform)")
        debugLog("[AevonXApp] INFO: API URL: \(AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL)")

        // Migrate security data from UserDefaults to Keychain (one-time)
        HostKeyStore.shared.migrateFromUserDefaults()
        SecureSettingsStore.shared.migrateFromUserDefaults()

        // Setup app lifecycle notifications
        setupLifecycleNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(settingsManager)
                .environmentObject(updateService)
                .onAppear {
                    // Initialize auth state when app appears (deferred from init)
                    authViewModel.initializeIfNeeded()
                    // Auto-check for updates on launch
                    updateService.checkOnLaunchIfNeeded()
                    updateService.startPeriodicCheck()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 900)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .commands {
            // App menu
            CommandGroup(replacing: .appInfo) {
                Button("About AevonX") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
                Button("Check for Updates...") {
                    Task { await updateService.checkForUpdate() }
                }
            }

            // Remove "Show Tab Bar" / "Show All Tabs"
            CommandGroup(replacing: .windowArrangement) {}

            // View → Navigation shortcuts (⌘1, ⌘2, ⌘,)
            CommandGroup(replacing: .sidebar) {
                Button("Remote Fleet") {
                    NotificationCenter.default.post(name: .navigateToItem, object: NavigationItem.remoteFleet)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Profile") {
                    NotificationCenter.default.post(name: .navigateToItem, object: NavigationItem.userProfile)
                }
                .keyboardShortcut("2", modifiers: .command)

                Divider()

                Button("Settings...") {
                    NotificationCenter.default.post(name: .navigateToItem, object: NavigationItem.settings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Help → Community (Reddit)
            CommandGroup(replacing: .help) {
                Button("AevonX Community") {
                    NSWorkspace.shared.open(AppURLs.reddit)
                }
                Button("Documentation") {
                    NSWorkspace.shared.open(AppURLs.docs)
                }
            }
        }
    }

    // MARK: - Lifecycle Management

    /// Handles scene phase changes (foreground/background)
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task {
                await appWillEnterForeground()
            }
        case .background:
            Task {
                await appDidEnterBackground()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    /// Called when app enters foreground
    private func appWillEnterForeground() async {
        CoreLogger.shared.info("App entering foreground", module: "AppLifecycle")
        await MainActor.run { AppSettingsManager.shared.checkAutoLock() }
        await resumeBackgroundOperations()
    }

    /// Called when app enters background
    private func appDidEnterBackground() async {
        CoreLogger.shared.info("App entering background", module: "AppLifecycle")
        await MainActor.run { AppSettingsManager.shared.updateLastActiveTime() }
        await pauseForegroundOperations()
    }

    /// Sets up platform-specific lifecycle notifications
    private func setupLifecycleNotifications() {
        #if os(macOS)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil, queue: .main
        ) { _ in
            Task { await self.deviceWillSleep() }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { _ in
            Task { await self.deviceDidWake() }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil, queue: .main
        ) { _ in
            Task { await self.appWillTerminate() }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMiniaturizeNotification,
            object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                let mgr = AppSettingsManager.shared
                if mgr.lockOnMinimize && mgr.appLockEnabled {
                    mgr.lock()
                }
            }
        }
        #endif

        setupAuthStateMonitoring()
    }

    /// Sets up monitoring for authentication state changes
    private func setupAuthStateMonitoring() {
        NotificationCenter.default.addObserver(
            forName: .init("AevonXUserDidLogout"),
            object: nil, queue: .main
        ) { _ in
            Task { await self.handleUserLogout() }
        }
    }

    // MARK: - Device Sleep/Wake

    private func deviceWillSleep() async {
        CoreLogger.shared.info("Device going to sleep — keeping connections alive", module: "AppLifecycle")
        let mgr = AppSettingsManager.shared
        if mgr.lockOnSleep && mgr.appLockEnabled {
            await MainActor.run { mgr.lock() }
        }
    }

    private func deviceDidWake() async {
        CoreLogger.shared.info("Device woke up - connections were disconnected during sleep", module: "AppLifecycle")
    }

    // MARK: - App Termination

    private func appWillTerminate() async {
        CoreLogger.shared.info("App terminating - cleaning up connections", module: "AppLifecycle")
        if AppSettingsManager.shared.clearClipboardOnExit {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            #endif
        }
        CoreBridge.shared.shutdown()
    }

    // MARK: - User Actions

    private func handleUserLogout() async {
        CoreLogger.shared.info("User logged out - clearing connections", module: "AppLifecycle")
        CoreBridge.shared.shutdown()
    }

    // MARK: - Operation Management

    private func resumeBackgroundOperations() async {
        CoreLogger.shared.debug("Resuming background operations", module: "AppLifecycle")
    }

    private func pauseForegroundOperations() async {
        CoreLogger.shared.debug("Pausing foreground operations", module: "AppLifecycle")
    }
}

// MARK: - Build Configuration

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
