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
        static let sshService = s("security.sshService", "SSH Service")
        static let totalSuccess = s("security.totalSuccess", "Total Success")
        static let totalFailed = s("security.totalFailed", "Total Failed")
        static let todayFailed = s("security.todayFailed", "Today Failed")
        static let portUpdatedSshRestarting = s("security.portUpdatedSshRestarting", "Port updated — SSH restarting...")
        static let defaultPortIsChangingItWillRestartSshAndMayDisconnectYou = s("security.defaultPortIsChangingItWillRestartSshAndMayDisconnectYou", "Default port is 22. Changing it will restart SSH and may disconnect you.")
        static let sshKeyPairExists = s("security.sshKeyPairExists", "SSH key pair exists")
        static let downloadKey = s("security.downloadKey", "Download Key")
        static let noSshKeyPairFound = s("security.noSshKeyPairFound", "No SSH key pair found")
        static let generateANewEd25519SshKeyPairToEnableKeyBasedAuthentication = s("security.generateANewEd25519SshKeyPairToEnableKeyBasedAuthentication", "Generate a new ED25519 SSH key pair to enable key-based authentication.")
        static let pasteAPublicSshKeyEGSshEd25519AaaaUserHost = s("security.pasteAPublicSshKeyEGSshEd25519AaaaUserHost", "Paste a public SSH key (e.g. ssh-ed25519 AAAA... user@host)")
        static let addKey = s("security.addKey", "Add Key")
        static let authorizedKeys = s("security.authorizedKeys", "Authorized Keys")
        static let noAuthorizedKeysFound = s("security.noAuthorizedKeysFound", "No authorized keys found")
        static let thisDevice = s("security.thisDevice", "This device")
        static let current = s("security.current", "Current")
        static let firewall = s("security.firewall", "Firewall")
        static let blockIcmp = s("security.blockIcmp", "Block ICMP")
        static let quickTemplates = s("security.quickTemplates", "Quick Templates")
        static let oneClickRuleGroups = s("security.oneClickRuleGroups", "One-click rule groups")
        static let applyingRules = s("security.applyingRules", "Applying rules…")
        static let addPortRule = s("security.addPortRule", "Add Port Rule")
        static let templates = s("security.templates", "Templates")
        static let noRule = s("security.noRule", "No Rule")
        static let block = s("security.block", "Block")
        static let allow = s("security.allow", "Allow")
        static let intrusionDetectionPrevention = s("security.intrusionDetectionPrevention", "Intrusion Detection & Prevention")
        static let installFail2banToEnableIntrusionDetectionAndAutomaticIpBanning = s("security.installFail2banToEnableIntrusionDetectionAndAutomaticIpBanning", "Install fail2ban to enable intrusion detection and automatic IP banning.")
        static let currently = s("security.currently", "Currently:")
        static let total = s("security.total", "Total:")
        static let ipAddress = s("security.ipAddress", "IP Address")
        static let action = s("security.action", "Action")
        static let bruteForceProtection = s("security.bruteForceProtection", "Brute Force Protection")
        static let installFail2banOnYourServerToEnableBruteForceProtection = s("security.installFail2banOnYourServerToEnableBruteForceProtection", "Install fail2ban on your server to enable brute force protection.")
        static let maxFailedAttempts = s("security.maxFailedAttempts", "Max Failed Attempts")
        static let banDuration = s("security.banDuration", "Ban Duration")
        static let permanent = s("security.permanent", "Permanent")
        static let unbanAll = s("security.unbanAll", "Unban All")
        static let remove = s("security.remove", "Remove")
        static let aiSecurityAssistant = s("security.aiSecurityAssistant", "AI Security Assistant")
        static let aiPoweredAnalysisOfYourServerSecurityPosture = s("security.aiPoweredAnalysisOfYourServerSecurityPosture", "AI-powered analysis of your server security posture")
        static let scanControls = s("security.scanControls", "Scan Controls")
        static let installClamav = s("security.installClamav", "Install ClamAV")
        static let quickScan = s("security.quickScan", "Quick Scan")
        static let fullScan = s("security.fullScan", "Full Scan")
        static let checkingClamav = s("security.checkingClamav", "Checking ClamAV…")
        static let securityScore = s("security.securityScore", "Security Score")
        static let protectionStatus = s("security.protectionStatus", "Protection Status")
        static let securityCenter = s("security.securityCenter", "Security Center")
        static let protected = s("security.protected", "Protected")
        static let securityCompliance = s("security.securityCompliance", "Security Compliance")
        static let basedOnKernelParametersSshConfigAndSecurityServices = s("security.basedOnKernelParametersSshConfigAndSecurityServices", "Based on kernel parameters, SSH config, and security services")
        static let reScan = s("security.reScan", "Re-scan")
        static let scanningSystemSecurity = s("security.scanningSystemSecurity", "Scanning system security…")
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
