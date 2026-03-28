import Foundation

extension L10n {

    // MARK: - Website (Websites.strings)
    enum Website {
        private static let table = "Websites"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let clone = s("website.clone", "Clone")
        static let redeploy = s("website.redeploy", "Redeploy")
        static let viewLogs = s("website.viewLogs", "View Logs")
        static let editConfig = s("website.editConfig", "Edit Configuration")
        static let issueLetsEncrypt = s("website.issueLetsEncrypt", "Issue Let's Encrypt Certificate")
        static let uploadCert = s("website.uploadCert", "Upload Custom Certificate")
        static let addRule = s("website.addRule", "Add Rule")
        static let browseTemplates = s("website.browseTemplates", "Browse Templates")
        static let createSchedule = s("website.createSchedule", "Create Schedule")
        static let backupNow = s("website.backupNow", "Backup Now")
        static let addAlias = s("website.addAlias", "Add Alias")
        static let createDomain = s("website.createDomain", "Create")
        static let lookup = s("website.lookup", "Lookup")
        static let templates = s("website.templates", "Templates")
        static let backups = s("website.backups", "Backups")
        static let restore = s("website.restore", "Restore")
        static let goUpLevel = s("website.goUpLevel", "Go up one level")
        static let selectCurrent = s("website.selectCurrent", "Select Current")

        // MARK: - Operations
        static let deletedSuccessfully = s("website.deletedSuccessfully", "Website deleted successfully")
        static let deleteFailed = s("website.deleteFailed", "Failed to delete website")
        static let phpFpmRestarted = s("website.phpFpmRestarted", "PHP-FPM restarted")
        static let pm2Restarted = s("website.pm2Restarted", "PM2 restarted")
        static let restartFailed = s("website.restartFailed", "Restart failed")
    }
}
