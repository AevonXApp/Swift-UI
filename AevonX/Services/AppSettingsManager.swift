//
//  AppSettingsManager.swift
//  AevonX
//
//  Central settings store with @AppStorage backing for all app settings
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Settings Keys

enum SettingsKey {
    // MARK: - Security
    static let appLockEnabled = "settings.security.appLockEnabled"
    static let appLockMethod = "settings.security.appLockMethod"
    static let requireAuthOnConnect = "settings.security.requireAuthOnConnect"
    static let requireAuthOnEdit = "settings.security.requireAuthOnEdit"
    static let requireAuthOnDelete = "settings.security.requireAuthOnDelete"
    static let autoLockTimeout = "settings.security.autoLockTimeout"
    static let lockOnSleep = "settings.security.lockOnSleep"
    static let clearClipboardOnExit = "settings.security.clearClipboardOnExit"
    static let maxFailedAttempts = "settings.security.maxFailedAttempts"
    static let lockOnMinimize = "settings.security.lockOnMinimize"

    // MARK: - Privacy
    static let maskServerInfo = "settings.privacy.maskServerInfo"
    static let maskIPAddresses = "settings.privacy.maskIPAddresses"
    static let maskUsernames = "settings.privacy.maskUsernames"
    static let maskDatabaseNames = "settings.privacy.maskDatabaseNames"
    static let maskPortNumbers = "settings.privacy.maskPortNumbers"
    static let showRealOnHover = "settings.privacy.showRealOnHover"
    static let maskInDashboard = "settings.privacy.maskInDashboard"

    // MARK: - Appearance
    static let theme = "settings.appearance.theme"

    // MARK: - Server List
    static let defaultViewMode = "settings.serverList.defaultViewMode"
    static let defaultSortOption = "settings.serverList.defaultSortOption"
    static let gridColumnCount = "settings.serverList.gridColumnCount"
    static let showServerTags = "settings.serverList.showServerTags"
    static let showServerOS = "settings.serverList.showServerOS"
    static let showPortInfo = "settings.serverList.showPortInfo"
    static let autoRefreshStatus = "settings.serverList.autoRefreshStatus"
    static let statusCheckInterval = "settings.serverList.statusCheckInterval"
    static let rememberLastFilter = "settings.serverList.rememberLastFilter"
    static let rememberLastSort = "settings.serverList.rememberLastSort"

    // MARK: - Dashboard
    static let defaultDashboardTab = "settings.dashboard.defaultTab"
    static let autoConnectOnOpen = "settings.dashboard.autoConnectOnOpen"
    static let showQuickVitals = "settings.dashboard.showQuickVitals"
    static let showQuickActions = "settings.dashboard.showQuickActions"
    static let showInventory = "settings.dashboard.showInventory"
    static let statsRefreshInterval = "settings.dashboard.statsRefreshInterval"
    static let showFreshServerBanner = "settings.dashboard.freshServerBanner"
    static let enableReconnection = "settings.dashboard.enableReconnection"
    static let maxReconnectAttempts = "settings.dashboard.maxReconnectAttempts"

    // MARK: - Terminal
    static let terminalBellSound = "settings.terminal.bellSound"
    static let terminalCopyOnSelect = "settings.terminal.copyOnSelect"

    // MARK: - Files
    static let showHiddenFiles = "settings.files.showHiddenFiles"
    static let fileSortOrder = "settings.files.sortOrder"
    static let showFileExtensions = "settings.files.showFileExtensions"

    // MARK: - Database
    static let dbQueryTimeout = "settings.database.queryTimeout"
    static let dbMaxRowsDisplay = "settings.database.maxRowsDisplay"
    static let dbAutoRefreshInterval = "settings.database.autoRefreshInterval"

    // MARK: - Network
    static let connectionTimeout = "settings.network.connectionTimeout"
    static let maxRetries = "settings.network.maxRetries"
    static let keepAliveInterval = "settings.network.keepAliveInterval"
    static let useProxy = "settings.network.useProxy"
    static let proxyHost = "settings.network.proxyHost"
    static let proxyPort = "settings.network.proxyPort"
    static let proxyType = "settings.network.proxyType"
    static let sshCompression = "settings.network.sshCompression"
    static let strictHostKeyChecking = "settings.network.strictHostKeyChecking"
    static let autoDisconnectIdle = "settings.network.autoDisconnectIdle"
    static let idleTimeout = "settings.network.idleTimeout"

    // MARK: - Notifications
    static let serverStatusAlerts = "settings.notifications.serverStatus"
    static let connectionAlerts = "settings.notifications.connection"
    static let securityAlerts = "settings.notifications.security"
    static let updateAlerts = "settings.notifications.updates"
    static let soundEnabled = "settings.notifications.soundEnabled"

    // MARK: - Delete Confirmations
    static let confirmDeleteServer = "settings.confirm.deleteServer"
    static let confirmDisconnectServer = "settings.confirm.disconnectServer"
    static let confirmDropDBTable = "settings.confirm.dropDBTable"
    static let confirmDropDBDatabase = "settings.confirm.dropDBDatabase"
    static let confirmDeleteDBRow = "settings.confirm.deleteDBRow"
    static let confirmDeleteFile2 = "settings.confirm.deleteFile"
    static let confirmDeleteFolder = "settings.confirm.deleteFolder"
    static let confirmDeleteWebsite = "settings.confirm.deleteWebsite"
    static let confirmDeleteDockerContainer = "settings.confirm.deleteDockerContainer"
    static let confirmDeleteDockerImage = "settings.confirm.deleteDockerImage"
    static let confirmDockerPrune = "settings.confirm.dockerPrune"
    static let confirmDeleteCronJob = "settings.confirm.deleteCronJob"
    static let confirmDeleteFTPUser = "settings.confirm.deleteFTPUser"
    static let confirmUninstallPlugin = "settings.confirm.uninstallPlugin"
    static let confirmDeleteSSHKey = "settings.confirm.deleteSSHKey"
    static let confirmTruncateTable = "settings.confirm.truncateTable"
    static let disableAllConfirmations = "settings.confirm.disableAll"

    // MARK: - General
    static let launchAtLogin = "settings.general.launchAtLogin"
    static let checkForUpdates = "settings.general.checkForUpdates"

    // MARK: - Updates
    static let updateChannel = "settings.general.updateChannel"
    static let autoDownloadUpdates = "settings.general.autoDownloadUpdates"
    static let skippedVersion = "settings.general.skippedVersion"
    static let updateCheckInterval = "settings.general.updateCheckInterval"
}

// MARK: - AppSettingsManager

@MainActor
class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()

    // MARK: - Security
    // CRITICAL: requireAuthOnConnect/Edit/Delete are stored in Keychain, not UserDefaults.
    // This prevents attackers from disabling biometric auth via `defaults write`.
    @AppStorage(SettingsKey.appLockEnabled) var appLockEnabled: Bool = true
    @AppStorage(SettingsKey.appLockMethod) var appLockMethod: String = "biometric"

    var requireAuthOnConnect: Bool {
        get { SecureSettingsStore.shared.getBool(SettingsKey.requireAuthOnConnect, default: true) }
        set { SecureSettingsStore.shared.setBool(SettingsKey.requireAuthOnConnect, value: newValue); objectWillChange.send() }
    }
    var requireAuthOnEdit: Bool {
        get { SecureSettingsStore.shared.getBool(SettingsKey.requireAuthOnEdit, default: true) }
        set { SecureSettingsStore.shared.setBool(SettingsKey.requireAuthOnEdit, value: newValue); objectWillChange.send() }
    }
    var requireAuthOnDelete: Bool {
        get { SecureSettingsStore.shared.getBool(SettingsKey.requireAuthOnDelete, default: true) }
        set { SecureSettingsStore.shared.setBool(SettingsKey.requireAuthOnDelete, value: newValue); objectWillChange.send() }
    }

    @AppStorage(SettingsKey.autoLockTimeout) var autoLockTimeout: Int = 5
    @AppStorage(SettingsKey.lockOnSleep) var lockOnSleep: Bool = true
    @AppStorage(SettingsKey.clearClipboardOnExit) var clearClipboardOnExit: Bool = false
    @AppStorage(SettingsKey.maxFailedAttempts) var maxFailedAttempts: Int = 5
    @AppStorage(SettingsKey.lockOnMinimize) var lockOnMinimize: Bool = false

    // MARK: - Privacy
    @AppStorage(SettingsKey.maskServerInfo) var maskServerInfo: Bool = false
    @AppStorage(SettingsKey.maskIPAddresses) var maskIPAddresses: Bool = false
    @AppStorage(SettingsKey.maskUsernames) var maskUsernames: Bool = false
    @AppStorage(SettingsKey.maskDatabaseNames) var maskDatabaseNames: Bool = false
    @AppStorage(SettingsKey.maskPortNumbers) var maskPortNumbers: Bool = false
    @AppStorage(SettingsKey.showRealOnHover) var showRealOnHover: Bool = true
    @AppStorage(SettingsKey.maskInDashboard) var maskInDashboard: Bool = true

    // MARK: - Appearance
    @AppStorage(SettingsKey.theme) var theme: String = "midnight"

    // MARK: - Server List
    @AppStorage(SettingsKey.defaultViewMode) var defaultViewMode: String = "grid"
    @AppStorage(SettingsKey.defaultSortOption) var defaultSortOption: String = "name_asc"
    @AppStorage(SettingsKey.gridColumnCount) var gridColumnCount: Int = 2
    @AppStorage(SettingsKey.showServerTags) var showServerTags: Bool = true
    @AppStorage(SettingsKey.showServerOS) var showServerOS: Bool = true
    @AppStorage(SettingsKey.showPortInfo) var showPortInfo: Bool = true
    @AppStorage(SettingsKey.autoRefreshStatus) var autoRefreshStatus: Bool = true
    @AppStorage(SettingsKey.statusCheckInterval) var statusCheckInterval: Int = 60
    @AppStorage(SettingsKey.rememberLastFilter) var rememberLastFilter: Bool = true
    @AppStorage(SettingsKey.rememberLastSort) var rememberLastSort: Bool = true

    // MARK: - Dashboard
    @AppStorage(SettingsKey.defaultDashboardTab) var defaultDashboardTab: String = "overview"
    @AppStorage(SettingsKey.autoConnectOnOpen) var autoConnectOnOpen: Bool = true
    @AppStorage(SettingsKey.showQuickVitals) var showQuickVitals: Bool = true
    @AppStorage(SettingsKey.showQuickActions) var showQuickActions: Bool = true
    @AppStorage(SettingsKey.showInventory) var showInventory: Bool = true
    @AppStorage(SettingsKey.statsRefreshInterval) var statsRefreshInterval: Int = 10
    @AppStorage(SettingsKey.showFreshServerBanner) var showFreshServerBanner: Bool = true
    @AppStorage(SettingsKey.enableReconnection) var enableReconnection: Bool = true
    @AppStorage(SettingsKey.maxReconnectAttempts) var maxReconnectAttempts: Int = 3

    // MARK: - Terminal
    @AppStorage(SettingsKey.terminalBellSound) var terminalBellSound: Bool = true
    @AppStorage(SettingsKey.terminalCopyOnSelect) var terminalCopyOnSelect: Bool = false

    // MARK: - Files
    @AppStorage(SettingsKey.showHiddenFiles) var showHiddenFiles: Bool = false
    @AppStorage(SettingsKey.fileSortOrder) var fileSortOrder: String = "name"
    @AppStorage(SettingsKey.showFileExtensions) var showFileExtensions: Bool = true

    // MARK: - Database
    @AppStorage(SettingsKey.dbQueryTimeout) var dbQueryTimeout: Int = 30
    @AppStorage(SettingsKey.dbMaxRowsDisplay) var dbMaxRowsDisplay: Int = 100
    @AppStorage(SettingsKey.dbAutoRefreshInterval) var dbAutoRefreshInterval: Int = 0

    // MARK: - Network
    @AppStorage(SettingsKey.connectionTimeout) var connectionTimeout: Int = 30
    @AppStorage(SettingsKey.maxRetries) var maxRetries: Int = 3
    @AppStorage(SettingsKey.keepAliveInterval) var keepAliveInterval: Int = 30
    // CRITICAL: Proxy settings in Keychain — prevents traffic redirect via `defaults write`.
    var useProxy: Bool {
        get { SecureSettingsStore.shared.getBool(SettingsKey.useProxy, default: false) }
        set { SecureSettingsStore.shared.setBool(SettingsKey.useProxy, value: newValue); objectWillChange.send() }
    }
    var proxyHost: String {
        get { SecureSettingsStore.shared.getString(SettingsKey.proxyHost, default: "") }
        set { SecureSettingsStore.shared.setString(SettingsKey.proxyHost, value: newValue); objectWillChange.send() }
    }
    var proxyPort: Int {
        get { SecureSettingsStore.shared.getInt(SettingsKey.proxyPort, default: 1080) }
        set { SecureSettingsStore.shared.setInt(SettingsKey.proxyPort, value: newValue); objectWillChange.send() }
    }
    var proxyType: String {
        get { SecureSettingsStore.shared.getString(SettingsKey.proxyType, default: "SOCKS5") }
        set { SecureSettingsStore.shared.setString(SettingsKey.proxyType, value: newValue); objectWillChange.send() }
    }
    @AppStorage(SettingsKey.sshCompression) var sshCompression: Bool = false
    @AppStorage(SettingsKey.strictHostKeyChecking) var strictHostKeyChecking: Bool = true
    @AppStorage(SettingsKey.autoDisconnectIdle) var autoDisconnectIdle: Bool = false
    @AppStorage(SettingsKey.idleTimeout) var idleTimeout: Int = 30

    // MARK: - Notifications
    @AppStorage(SettingsKey.serverStatusAlerts) var serverStatusAlerts: Bool = true
    @AppStorage(SettingsKey.connectionAlerts) var connectionAlerts: Bool = true
    @AppStorage(SettingsKey.securityAlerts) var securityAlerts: Bool = true
    @AppStorage(SettingsKey.updateAlerts) var updateAlerts: Bool = true
    @AppStorage(SettingsKey.soundEnabled) var soundEnabled: Bool = true

    // MARK: - Delete Confirmations
    @AppStorage(SettingsKey.confirmDeleteServer) var confirmDeleteServer: Bool = true
    @AppStorage(SettingsKey.confirmDisconnectServer) var confirmDisconnectServer: Bool = false
    @AppStorage(SettingsKey.confirmDropDBTable) var confirmDropDBTable: Bool = true
    @AppStorage(SettingsKey.confirmDropDBDatabase) var confirmDropDBDatabase: Bool = true
    @AppStorage(SettingsKey.confirmDeleteDBRow) var confirmDeleteDBRow: Bool = true
    @AppStorage(SettingsKey.confirmDeleteFile2) var confirmDeleteFile2: Bool = true
    @AppStorage(SettingsKey.confirmDeleteFolder) var confirmDeleteFolder: Bool = true
    @AppStorage(SettingsKey.confirmDeleteWebsite) var confirmDeleteWebsite: Bool = true
    @AppStorage(SettingsKey.confirmDeleteDockerContainer) var confirmDeleteDockerContainer: Bool = true
    @AppStorage(SettingsKey.confirmDeleteDockerImage) var confirmDeleteDockerImage: Bool = true
    @AppStorage(SettingsKey.confirmDockerPrune) var confirmDockerPrune: Bool = true
    @AppStorage(SettingsKey.confirmDeleteCronJob) var confirmDeleteCronJob: Bool = true
    @AppStorage(SettingsKey.confirmDeleteFTPUser) var confirmDeleteFTPUser: Bool = true
    @AppStorage(SettingsKey.confirmUninstallPlugin) var confirmUninstallPlugin: Bool = true
    @AppStorage(SettingsKey.confirmDeleteSSHKey) var confirmDeleteSSHKey: Bool = true
    @AppStorage(SettingsKey.confirmTruncateTable) var confirmTruncateTable: Bool = true
    @AppStorage(SettingsKey.disableAllConfirmations) var disableAllConfirmations: Bool = false

    // MARK: - General
    @AppStorage(SettingsKey.launchAtLogin) var launchAtLogin: Bool = false
    @AppStorage(SettingsKey.checkForUpdates) var checkForUpdates: Bool = true

    // MARK: - Updates
    @AppStorage(SettingsKey.updateChannel) var updateChannel: String = "stable"
    @AppStorage(SettingsKey.autoDownloadUpdates) var autoDownloadUpdates: Bool = true
    @AppStorage(SettingsKey.skippedVersion) var skippedVersion: String = ""
    @AppStorage(SettingsKey.updateCheckInterval) var updateCheckInterval: Int = 6

    // MARK: - Lock State (not persisted - runtime only)
    @Published var isLocked: Bool = true
    @Published var failedAttempts: Int = 0
    @Published var lastActiveTime: Date = Date()

    private init() {
        // On first launch with appLockEnabled = true, app starts locked
        isLocked = UserDefaults.standard.bool(forKey: SettingsKey.appLockEnabled)
    }

    // MARK: - Lock Management

    func unlock() {
        isLocked = false
        failedAttempts = 0
        lastActiveTime = Date()
    }

    func lock() {
        isLocked = true
    }

    func recordFailedAttempt() {
        failedAttempts += 1
    }

    func checkAutoLock() {
        guard appLockEnabled, autoLockTimeout > 0 else { return }
        let elapsed = Date().timeIntervalSince(lastActiveTime)
        if elapsed > TimeInterval(autoLockTimeout * 60) {
            lock()
        }
    }

    func updateLastActiveTime() {
        lastActiveTime = Date()
    }

    // MARK: - Confirmation Check

    func shouldConfirm(for key: String) -> Bool {
        if disableAllConfirmations { return false }
        return UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }

    // MARK: - Reset

    func resetToDefaults() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("settings.") }
        for key in allKeys {
            defaults.removeObject(forKey: key)
        }
        // Re-initialize lock state
        isLocked = true
        failedAttempts = 0
    }

    // MARK: - Export / Import

    func exportSettings() -> [String: Any] {
        let defaults = UserDefaults.standard
        var settings: [String: Any] = [:]
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.hasPrefix("settings.") {
                settings[key] = value
            }
        }
        return settings
    }

    func importSettings(_ settings: [String: Any]) {
        let defaults = UserDefaults.standard
        for (key, value) in settings {
            if key.hasPrefix("settings.") {
                defaults.set(value, forKey: key)
            }
        }
    }

    // MARK: - Sync Network Settings to Go Bridge

    func syncNetworkSettingsToCore() {
        SSHBridge.shared.applySettings(
            connectionTimeout: connectionTimeout,
            keepAliveInterval: keepAliveInterval,
            maxRetries: maxRetries,
            sshCompression: sshCompression,
            strictHostKeyChecking: strictHostKeyChecking,
            useProxy: useProxy,
            proxyHost: proxyHost,
            proxyPort: proxyPort,
            proxyType: proxyType,
            autoDisconnectIdle: autoDisconnectIdle,
            idleTimeout: idleTimeout
        )
    }
}
