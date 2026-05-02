import Foundation

extension L10n {

    // MARK: - Auth (Auth.strings)
    enum Auth {
        private static let table = "Auth"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let createAccount = s("auth.createAccount", "Create your account")
        static let forgotPassword = s("auth.forgotPassword", "Forgot Password?")
        static let resetPasswordInfo = s("auth.resetPasswordInfo", "We'll send you a link to reset your password.")
        static let backToSignIn = s("auth.backToSignIn", "Back to Sign In")
        static let noAccountSignUp = s("auth.noAccountSignUp", "Don't have an account? Sign Up")
        static let hasAccountSignIn = s("auth.hasAccountSignIn", "Already have an account? Sign In")
        static let checkingTrial = s("auth.checkingTrial", "Checking trial eligibility...")
        static let passwordStrength = s("auth.passwordStrength", "Password Strength:")
        static let signIn = s("auth.signIn", "Sign In")
        static let sendResetLink = s("auth.sendResetLink", "Send Reset Link")
    }

    // MARK: - Profile (Auth.strings)
    enum Profile {
        private static let table = "Auth"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("profile.title", "Profile")
        static let signOut = s("profile.signOut", "Sign Out")
        static let edit = s("profile.edit", "Edit Profile")
        static let changePasswordDesc = s("profile.changePasswordDesc", "Change your account password")
        static let noSessions = s("profile.noSessions", "No sessions found")
        static let signOutAll = s("profile.signOutAll", "Sign Out All Devices")
        static let currentDevice = s("profile.currentDevice", "Current")
        static let currentPlan = s("profile.currentPlan", "Current Plan")
        static let manageSubscription = s("profile.manageSubscription", "Manage Subscription")
        static let changePassword = s("profile.changePassword", "Change Password")
        static let recentActivity = s("profile.recentActivity", "Recent Activity")
        static let noActivity = s("profile.noActivity", "No activity recorded yet.")
        static let encryptionKey = s("profile.encryptionKey", "Encryption Key")
        static let zeroKnowledgeActive = s("profile.zeroKnowledgeActive", "Zero-Knowledge Encryption Active")
        static let encryptionDescription = s("profile.encryptionDescription", "Your server credentials are encrypted with your personal key.")
        static let backupKey = s("profile.backupKey", "Backup Key")
        static let backupKeyDesc = s("profile.backupKeyDesc", "View and copy your encryption key for safekeeping.")
        static let encryptionKeyWarning = s("profile.encryptionKeyWarning", "If you lose your Encryption Key, your encrypted data cannot be recovered.")
        static let apiKeysAreNotAvailableAevonxDoesNotOfferAPublicDeveloperApiAtThisTime = s("profile.apiKeysNotice", "API Keys are not available. AevonX does not offer a public developer API at this time.")
        static let storeThisKeyInAPhysicalSafeOrASecurePasswordManagerIfYouLoseThisKeyYourServerCredentialsWillBePermanentlyLostAevonxIsAZeroKnowledgePlatformAndHasNoWayToRecoverIt = s("profile.storeKeyWarning", "Store this key in a physical safe or a secure password manager. If you lose this key, your server credentials will be permanently lost. AevonX is a zero-knowledge platform and has NO way to recover it.")
        static let yourEncryptionKeyIsSafelyLockedInYourDevicesSecureStorageYourServerCredentialsAreProtectedByZeroKnowledgeEncryption = s("profile.encryptionKeyLockedNotice", "Your encryption key is safely locked in your device's secure storage. Your server credentials are protected by zero-knowledge encryption.")
    }

    // MARK: - Subscription (Auth.strings)
    enum Subscription {
        private static let table = "Auth"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let trialActive = s("subscription.trialActive", "Trial Active")
        static let trialExpired = s("subscription.trialExpired", "Trial Expired")
        static let upgradeToContinue = s("subscription.upgradeToContinue", "Upgrade to continue")
        static let freePlan = s("subscription.freePlan", "Free Plan")
        static let trial = s("subscription.trial", "TRIAL")

        static func daysRemaining(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) days remaining"
            return String(localized: "subscription.daysRemaining", defaultValue: dv, table: table)
        }
    }

    // MARK: - Vault (Auth.strings)
    enum Vault {
        private static let table = "Auth"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let keyDescription = s("vault.keyDescription", "This 256-bit key is the ONLY way to recover your encrypted data.")
        static let secureStorageRequired = s("vault.secureStorageRequired", "SECURE STORAGE REQUIRED")
        static let finishSetup = s("vault.finishSetup", "Finish Setup")
        static let enterRecoveryKey = s("vault.enterRecoveryKey", "Enter Recovery Key")
        static let enterKeyInstruction = s("vault.enterKeyInstruction", "Enter the 256-bit Recovery Key you saved during setup.")
        static let zeroKnowledge = s("vault.zeroKnowledge", "Zero-Knowledge Security")
        static let verifyLocally = s("vault.verifyLocally", "Your key will be verified locally on this device.")
        static let verifyUnlock = s("vault.verifyUnlock", "Verify & Unlock")
        static let secured = s("vault.secured", "Vault Secured")
        static let enterApp = s("vault.enterApp", "Enter AevonX")
    }

    // MARK: - Recovery (Auth.strings)
    enum Recovery {
        private static let table = "Auth"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("recovery.title", "Your Recovery Key")
        static let writeDownNow = s("recovery.writeDownNow", "Write this down now. You will never see it again.")
        static let criticalWarning = s("recovery.criticalWarning", "CRITICAL WARNING")
        static let lossWarning = s("recovery.lossWarning", "If you lose this Recovery Key, your encrypted data CANNOT be recovered. There is no reset option.")
        static let generate = s("recovery.generate", "Generate Recovery Key")
        static let storedSecurely = s("recovery.storedSecurely", "I have securely saved my Recovery Key")
        static let understandLoss = s("recovery.understandLoss", "I understand that if I lose it, my data is lost forever")
        static let readWarning = s("recovery.readWarning", "I've read the warning")
    }
}
