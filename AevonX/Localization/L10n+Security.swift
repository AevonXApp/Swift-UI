import Foundation

extension L10n {

    // MARK: - Security (Security.strings)
    enum Security {
        private static let table = "Security"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let authRequired = s("security.authRequired", "Authentication Required")
        static let unlockBiometrics = s("security.unlockBiometrics", "Unlock with Biometrics")
        static let usePassword = s("security.usePassword", "Use Password Instead")
        static let unlock = s("security.unlock", "Unlock")
        static let useBiometrics = s("security.useBiometrics", "Use Biometrics Instead")
        static let alert = s("security.alert", "Security Alert")
        static let hostKeyChanged = s("security.hostKeyChanged", "Host Key Changed")
        static let hostKeyWarning = s("security.hostKeyWarning", "The server's identity has changed. This could indicate a security issue.")
        static let expectedFingerprint = s("security.expectedFingerprint", "Expected Fingerprint:")
        static let actualFingerprint = s("security.actualFingerprint", "Actual Fingerprint:")
        static let trustWarning = s("security.trustWarning", "Only accept if you trust this change.")
        static let acceptNewKey = s("security.acceptNewKey", "Accept New Key")

        static func attemptsUsed(_ used: Int, _ max: Int) -> String {
            let dv: String.LocalizationValue = "\(used) of \(max) attempts used"
            return String(localized: "security.attemptsUsed", defaultValue: dv, table: table)
        }

        static func serverName(_ name: String) -> String {
            let dv: String.LocalizationValue = "Server: \(name)"
            return String(localized: "security.serverName", defaultValue: dv, table: table)
        }
    }

    // MARK: - Encryption (Security.strings)
    enum Encryption {
        private static let table = "Security"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let decryptionError = s("encryption.decryptionError", "Decryption Error")
        static let errorDetails = s("encryption.errorDetails", "Error Details:")
        static let whatCanYouDo = s("encryption.whatCanYouDo", "What can you do?")
        static let helpEnterKey = s("encryption.helpEnterKey", "Enter your Encryption Key if you have one")
        static let helpLogout = s("encryption.helpLogout", "Try logging out and logging back in")
        static let helpDeleteServers = s("encryption.helpDeleteServers", "Delete affected servers and re-add them")
        static let enterKey = s("encryption.enterKey", "Enter Encryption Key:")
        static let keyPlaceholder = s("encryption.keyPlaceholder", "XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX")
        static let keyProvidedHelp = s("encryption.keyProvidedHelp", "The encryption key was provided when you set up your account")
        static let verifyingIdentity = s("encryption.verifyingIdentity", "Verifying identity...")
        static let yourKey = s("encryption.yourKey", "Your Encryption Key")
        static let saveSecurely = s("encryption.saveSecurely", "Save this key securely. You will need it to recover your data.")
        static let keyHiddenOnClose = s("encryption.keyHiddenOnClose", "This key will be hidden when you close this window.")

        static func affectedServers(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Affected servers: \(count)"
            return String(localized: "encryption.affectedServers", defaultValue: dv, table: table)
        }
    }

    // MARK: - Connection Progress (Security.strings)
    enum Connection {
        private static let table = "Security"

        static func connectingTo(_ server: String) -> String {
            let dv: String.LocalizationValue = "Connecting to \(server)"
            return String(localized: "connection.connectingTo", defaultValue: dv, table: table)
        }

        static func attemptProgress(_ current: Int, _ max: Int) -> String {
            let dv: String.LocalizationValue = "Attempt \(current)/\(max)"
            return String(localized: "connection.attemptProgress", defaultValue: dv, table: table)
        }

        static func nextRetryIn(_ seconds: Int) -> String {
            let dv: String.LocalizationValue = "Next retry in \(seconds)s"
            return String(localized: "connection.nextRetryIn", defaultValue: dv, table: table)
        }
    }

    // MARK: - Installer (Security.strings)
    enum Installer {
        private static let table = "Security"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let allComplete = s("installer.allComplete", "All steps completed successfully")
        static let failed = s("installer.failed", "Installation failed")

        static func stepProgress(_ current: Int, _ total: Int) -> String {
            let dv: String.LocalizationValue = "Step \(current)/\(total)"
            return String(localized: "installer.stepProgress", defaultValue: dv, table: table)
        }
    }

    // MARK: - Confirmation (Security.strings)
    enum Confirm {
        private static let table = "Security"

        static func typeToConfirm(_ name: String) -> String {
            let dv: String.LocalizationValue = "Type **\(name)** to confirm:"
            return String(localized: "confirm.typeToConfirm", defaultValue: dv, table: table)
        }
    }
}
