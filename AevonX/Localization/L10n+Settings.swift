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
        static let madeWithPassionForServerEngineersWorldwide = s("settings.madeWithPassionForServerEngineersWorldwide", "Made with passion for server engineers worldwide")
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

        // Update sheet titles
        static let titleAvailable = s("update.titleAvailable", "Update Available")
        static let titleDownloading = s("update.titleDownloading", "Downloading Update")
        static let titleReady = s("update.titleReady", "Ready to Install")
        static let titleInstalling = s("update.titleInstalling", "Installing Update")
        static let titleError = s("update.titleError", "Update Error")
        static let titleGeneric = s("update.titleGeneric", "Update")

        // Version pills & info
        static let versionCurrent = s("update.versionCurrent", "Current")
        static let versionNew = s("update.versionNew", "New")
        static let infoSize = s("update.infoSize", "Size")
        static let infoReleased = s("update.infoReleased", "Released")
        static let badgeRequired = s("update.badgeRequired", "Required Update")

        // Move to Applications
        static let moveTitle = s("update.moveTitle", "Move to Applications")
        static let moveDescription = s("update.moveDescription", "For the best experience, move AevonX to your Applications folder. This enables automatic updates and Launch at Login.")
        static let moveButton = s("update.moveButton", "Move to Applications")
        static let moveKeep = s("update.moveKeep", "Keep Current Location")
        static let moveDMGWarning = s("update.moveDMGWarning", "Running from a disk image is not supported. Please move AevonX to Applications to continue.")
        static let moveFooter = s("update.moveFooter", "You can always move the app later by dragging it to Applications.")

        static func versionRequired(_ version: String) -> String {
            let dv: String.LocalizationValue = "AevonX \(version) is required to continue."
            return String(localized: "update.versionRequired", defaultValue: dv, table: table)
        }
    }

    // MARK: - About (Settings.strings)
    enum About {
        private static let table = "Settings"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let connect = s("about.connect", "Connect")
        static let legal = s("about.legal", "Legal")
        static let debugSupport = s("about.debugSupport", "Debug & Support")
        static let copyDebugInfo = s("about.copyDebugInfo", "Copy Debug Info")
        static let copyDebugInfoSub = s("about.copyDebugInfoSub", "Copy diagnostic information to clipboard")
        static let copyButton = s("about.copyButton", "Copy")
        static let openLogs = s("about.openLogs", "Open Logs Directory")
        static let openLogsSub = s("about.openLogsSub", "View application log files")
        static let openButton = s("about.openButton", "Open")
        static let checkUpdates = s("about.checkUpdates", "Check for Updates")
        static let checking = s("about.checking", "Checking...")
        static let checkNow = s("about.checkNow", "Check Now")
        static let upToDate = s("about.upToDate", "You're up to date")
        static let readyToInstall = s("about.readyToInstall", "Ready to install")

        static func versionAvailable(_ version: String) -> String {
            let dv: String.LocalizationValue = "Version \(version) available"
            return String(localized: "about.versionAvailable", defaultValue: dv, table: table)
        }
    }
}
