import Foundation

extension L10n {

    // MARK: - Settings (Settings.strings)
    enum Settings {
        private static let table = "Settings"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("settings.title", "Settings")
        static let tabGeneral = s("settings.tab.general", "General")
        static let tabSecurity = s("settings.tab.security", "Security")
        static let tabPrivacy = s("settings.tab.privacy", "Privacy")
        static let tabAppearance = s("settings.tab.appearance", "Appearance")
        static let tabServerList = s("settings.tab.serverList", "Server List")
        static let tabDashboard = s("settings.tab.dashboard", "Dashboard")
        static let tabTerminal = s("settings.tab.terminal", "Terminal")
        static let tabFileManager = s("settings.tab.fileManager", "File Manager")
        static let tabDatabase = s("settings.tab.database", "Database")
        static let tabNetwork = s("settings.tab.network", "Network")
        static let tabNotifications = s("settings.tab.notifications", "Notifications")
        static let tabConfirmations = s("settings.tab.confirmations", "Confirmations")
        static let tabKeyboard = s("settings.tab.keyboard", "Keyboard")
        static let tabDataStorage = s("settings.tab.dataStorage", "Data & Storage")
        static let tabAbout = s("settings.tab.about", "About")
        static let networkProxyHost = s("settings.network.proxyHost", "Proxy Host")
        static let networkPort = s("settings.network.port", "Port")
        static let securityKeychainInfo = s("settings.security.keychainInfo", "Password is stored securely in your Keychain")
        static let securityPasswordSaved = s("settings.security.passwordSaved", "Password saved successfully")
    }

    // MARK: - Update (Settings.strings)
    enum Update {
        private static let table = "Settings"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let whatsNew = s("update.whatsNew", "What's New")
        static let required = s("update.required", "Update Required")
        static let downloadInstall = s("update.downloadInstall", "Download & Install")
        static let downloading = s("update.downloading", "Downloading...")
        static let installRestart = s("update.installRestart", "Install & Restart")
        static let installing = s("update.installing", "Installing...")
        static let installingUpdate = s("update.installingUpdate", "Installing update...")
        static let requiredReason = s("update.requiredReason", "This update is required for security and compatibility.")

        static func versionRequired(_ version: String) -> String {
            let dv: String.LocalizationValue = "AevonX \(version) is required to continue."
            return String(localized: "update.versionRequired", defaultValue: dv, table: table)
        }
    }
}
