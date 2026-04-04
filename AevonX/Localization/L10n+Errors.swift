import Foundation

extension L10n {

    // MARK: - Errors (Errors.strings)
    enum Error {
        private static let table = "Errors"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let generic = s("error.generic", "Something went wrong. Please try again.")
        static let connectionFailed = s("error.connectionFailed", "Connection failed. Please check your server settings.")
        static let notConnected = s("error.notConnected", "Not connected to server.")
        static let timeout = s("error.timeout", "Connection timed out. Please try again.")
        static let networkError = s("error.networkError", "Network error. Check your internet connection.")
        static let networkUnreachable = s("error.networkUnreachable", "Network is unreachable. Check your connection.")
        static let alreadyConnected = s("error.alreadyConnected", "Already connected to this server.")
        static let authFailed = s("error.authFailed", "Authentication failed. Please try again.")
        static let sessionExpired = s("error.sessionExpired", "Your session has expired. Please log in again.")
        static let connectionSessionExpired = s("error.connectionSessionExpired", "Your connection session has expired. Please reconnect.")
        static let invalidCredentials = s("error.invalidCredentials", "Invalid credentials. Please check your username and password.")
        static let authRequired = s("error.authRequired", "Authentication required. Please log in.")
        static let hostKeyChanged = s("error.hostKeyChanged", "Server identity has changed. This may indicate a security issue.")
        static let securityCheck = s("error.securityCheck", "Security verification failed. Please reconnect.")
        static let securityThreat = s("error.securityThreat", "Security alert: Connection may be compromised. Do not proceed.")
        static let deviceChanged = s("error.deviceChanged", "Device verification failed. Please log in again.")
        static let encryptionFailed = s("error.encryptionFailed", "Encryption error. Please try again.")
        static let decryptionFailed = s("error.decryptionFailed", "Failed to decrypt data. Check your encryption key.")
        static let serverError = s("error.serverError", "Server error. Please try again later.")
        static let invalidApiUrl = s("error.invalidApiUrl", "Invalid server URL.")
        static let serverLimitReached = s("error.serverLimitReached", "Server limit reached. Upgrade your plan to add more.")
        static let serverNotAccessible = s("error.serverNotAccessible", "Server is not accessible. Check if it's online.")
        static let rateLimited = s("error.rateLimited", "Too many requests. Please wait a moment and try again.")
        static let deviceIdFailed = s("error.deviceIdFailed", "Unable to identify this device. Please try again.")
        static let commandFailed = s("error.commandFailed", "Operation failed. Check server configuration.")
        static let detectionFailed = s("error.detectionFailed", "Could not detect server configuration.")
        static let serviceNotInstalled = s("error.serviceNotInstalled", "This service is not installed on the server.")
        static let unsupportedOperation = s("error.unsupportedOperation", "This operation is not supported.")
        static let serviceConnectionFailed = s("error.serviceConnectionFailed", "Failed to connect to the service.")
        static let serverNotConfigured = s("error.serverNotConfigured", "Server not configured.")
        static let invalidInput = s("error.invalidInput", "Invalid input.")
        static let invalidResponse = s("error.invalidResponse", "Invalid response from server.")
        static let pluginNotFound = s("error.pluginNotFound", "Plugin not found.")
        static let pluginSetupMissing = s("error.pluginSetupMissing", "Plugin package is incomplete.")
        static let pluginSetupFailed = s("error.pluginSetupFailed", "Plugin setup failed. Please try again.")
        static let pluginBinaryMissing = s("error.pluginBinaryMissing", "Plugin binary not found on server.")
        static let pluginHealthFailed = s("error.pluginHealthFailed", "Plugin health check failed.")
        static let pluginIncompatible = s("error.pluginIncompatible", "Plugin version is not compatible with this app version.")
        static let aiUnavailable = s("error.aiUnavailable", "AI service is temporarily unavailable.")
        static let aiUnsupportedDB = s("error.aiUnsupportedDB", "This database type is not supported for AI installation.")
        static let downloadExpired = s("error.downloadExpired", "Download link has expired. Please try again.")
        static let downloadUsed = s("error.downloadUsed", "Download link already used. Please request a new one.")
        static let sslFailed = s("error.sslFailed", "SSL operation failed.")
        static let invalidConfig = s("error.invalidConfig", "Invalid configuration.")
        static let configUpdateFailed = s("error.configUpdateFailed", "Failed to update configuration.")
        static let installFailed = s("error.installFailed", "Installation failed. Please try again.")
        static let uninstallFailed = s("error.uninstallFailed", "Uninstall failed.")
        static let installCancelled = s("error.installCancelled", "Installation was cancelled.")
        static let extractFailed = s("error.extractFailed", "Failed to extract package.")
        static let sqlEmpty = s("error.sqlEmpty", "SQL content is empty.")
        static let nullResponse = s("error.nullResponse", "No response from server. Please try again.")
        static let invalidJSON = s("error.invalidJSON", "Invalid response format.")
        static let sshFailed = s("error.sshFailed", "SSH connection failed.")
        static let serverConfigNotFound = s("error.serverConfigNotFound", "Server configuration not found.")
        static let deviceIdentifyFailed = s("error.deviceIdentifyFailed", "Failed to identify device.")
        static let noAuthToken = s("error.noAuthToken", "No authentication token found.")
        static let decodeFailed = s("error.decodeFailed", "Failed to decode response.")

        static func operationFailed(_ operation: String) -> String {
            let dv: String.LocalizationValue = "\(operation) failed"
            return String(localized: "error.operationFailed", defaultValue: dv, table: table)
        }
    }

    // MARK: - Success Messages (Errors.strings)
    enum Success {
        private static let table = "Errors"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let rowInserted = s("success.rowInserted", "Row inserted successfully")
        static let rowUpdated = s("success.rowUpdated", "Row updated successfully")
        static let rowDeleted = s("success.rowDeleted", "Row deleted successfully")
        static let rowDuplicated = s("success.rowDuplicated", "Row duplicated")
        static let backupCreated = s("success.backupCreated", "Backup created successfully")
        static let backupDeleted = s("success.backupDeleted", "Backup deleted")
        static let backupSaved = s("success.backupSaved", "Backup saved successfully")
        static let backupRestored = s("success.backupRestored", "Backup restored successfully")
        static let sqlImported = s("success.sqlImported", "SQL imported successfully")
        static let passwordSaved = s("success.passwordSaved", "Password saved successfully")

        static func rowsDeleted(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) row(s) deleted successfully"
            return String(localized: "success.rowsDeleted", defaultValue: dv, table: table)
        }

        static func tableCreated(_ name: String) -> String {
            let dv: String.LocalizationValue = "Table '\(name)' created successfully"
            return String(localized: "success.tableCreated", defaultValue: dv, table: table)
        }

        static func tableRenamed(_ name: String) -> String {
            let dv: String.LocalizationValue = "Table renamed to '\(name)'"
            return String(localized: "success.tableRenamed", defaultValue: dv, table: table)
        }

        static func indexDropped(_ name: String) -> String {
            let dv: String.LocalizationValue = "Index '\(name)' dropped"
            return String(localized: "success.indexDropped", defaultValue: dv, table: table)
        }

        static func actionSuccessful(_ action: String) -> String {
            let dv: String.LocalizationValue = "\(action) successful"
            return String(localized: "success.actionSuccessful", defaultValue: dv, table: table)
        }
    }

    // MARK: - Validation (Errors.strings)
    enum Validation {
        private static let table = "Errors"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let required = s("validation.required", "This field is required.")
        static let invalidEmail = s("validation.invalidEmail", "Please enter a valid email address.")
        static let passwordTooShort = s("validation.passwordTooShort", "Password must be at least 8 characters.")
        static let passwordMismatch = s("validation.passwordMismatch", "Passwords do not match.")
        static let invalidPort = s("validation.invalidPort", "Port must be between 1 and 65535.")
        static let nameRequired = s("validation.nameRequired", "Name is required.")
    }
}
