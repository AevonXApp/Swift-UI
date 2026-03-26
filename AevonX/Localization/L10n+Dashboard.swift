import Foundation

extension L10n {

    // MARK: - Dashboard (Dashboard.strings)
    enum Dashboard {
        private static let table = "Dashboard"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let connectionError = s("dashboard.connectionError", "Connection Error")
        static let snapshotCreateFailed = s("dashboard.snapshotCreateFailed", "Failed to create snapshot")
        static let snapshotRestoreFailed = s("dashboard.snapshotRestoreFailed", "Failed to restore snapshot")
        static let snapshotDeleteFailed = s("dashboard.snapshotDeleteFailed", "Failed to delete snapshot")
        static let encodeSettingsFailed = s("dashboard.encodeSettingsFailed", "Failed to encode settings")
        static let applySecurityFailed = s("dashboard.applySecurityFailed", "Failed to apply security settings")
        static let saveConfigFailed = s("dashboard.saveConfigFailed", "Failed to save config")
        static let pm2InstallFailed = s("dashboard.pm2InstallFailed", "Failed to install PM2")
        static let pm2StartFailed = s("dashboard.pm2StartFailed", "Start failed")
        static let pm2StopFailed = s("dashboard.pm2StopFailed", "Stop failed")
        static let pm2RestartFailed = s("dashboard.pm2RestartFailed", "Restart failed")
        static let pm2DeleteFailed = s("dashboard.pm2DeleteFailed", "Delete failed")
        static let pm2SaveFailed = s("dashboard.pm2SaveFailed", "Save failed")
        static let envSaveFailed = s("dashboard.envSaveFailed", "Failed to save")
        static let nodeSwitchFailed = s("dashboard.nodeSwitchFailed", "Switch failed")
        static let phpXdebugFailed = s("dashboard.phpXdebugFailed", "Failed to toggle Xdebug")
        static let phpAuditFailed = s("dashboard.phpAuditFailed", "Audit failed")
        static let phpCleanSessionsFailed = s("dashboard.phpCleanSessionsFailed", "Failed to clean sessions")
        static let phpOpcacheResetFailed = s("dashboard.phpOpcacheResetFailed", "Failed to reset OPcache")

        static func appInstallFailed(_ app: String, _ version: String) -> String {
            let dv: String.LocalizationValue = "Failed to install \(app) \(version)"
            return String(localized: "dashboard.appInstallFailed", defaultValue: dv, table: table)
        }
    }
}
