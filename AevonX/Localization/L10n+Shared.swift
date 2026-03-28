import Foundation

extension L10n {

    // MARK: - Buttons (Shared.strings)
    enum Button {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let cancel = s("button.cancel", "Cancel")
        static let save = s("button.save", "Save")
        static let retry = s("button.retry", "Retry")
        static let close = s("button.close", "Close")
        static let delete = s("button.delete", "Delete")
        static let create = s("button.create", "Create")
        static let edit = s("button.edit", "Edit")
        static let connect = s("button.connect", "Connect")
        static let disconnect = s("button.disconnect", "Disconnect")
        static let upgrade = s("button.upgrade", "Upgrade")
        static let upgradeNow = s("button.upgradeNow", "Upgrade Now")
        static let apply = s("button.apply", "Apply")
        static let done = s("button.done", "Done")
        static let later = s("button.later", "Later")
        static let skip = s("button.skip", "Skip")
        static let notNow = s("button.notNow", "Not Now")
        static let tryAgain = s("button.tryAgain", "Try Again")
        static let maybeLater = s("button.maybeLater", "Maybe Later")
        static let change = s("button.change", "Change")
        static let renew = s("button.renew", "Renew")
        static let `continue` = s("button.continue", "Continue")
        static let back = s("button.back", "Back")
        static let saveChanges = s("button.saveChanges", "Save Changes")
        static let cancelConnection = s("button.cancelConnection", "Cancel Connection")
        static let openDashboard = s("button.openDashboard", "Open Dashboard")
        static let restoreKeys = s("button.restoreKeys", "Restore Keys")
        static let subscribeNow = s("button.subscribeNow", "Subscribe Now")
        static let start = s("button.start", "Start")
        static let stop = s("button.stop", "Stop")
        static let restart = s("button.restart", "Restart")
        static let install = s("button.install", "Install")
        static let uninstall = s("button.uninstall", "Uninstall")
        static let refresh = s("button.refresh", "Refresh")
        static let copy = s("button.copy", "Copy")
        static let remove = s("button.remove", "Remove")
        static let confirm = s("button.confirm", "Confirm")
        static let add = s("button.add", "Add")
        static let clear = s("button.clear", "Clear")
        static let search = s("button.search", "Search")
        static let select = s("button.select", "Select")
    }

    // MARK: - Form Fields (Shared.strings)
    enum Field {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let username = s("field.username", "Username")
        static let password = s("field.password", "Password")
        static let email = s("field.email", "Email")
        static let host = s("field.host", "Host")
        static let port = s("field.port", "Port")
        static let serverName = s("field.serverName", "Server Name")
        static let icon = s("field.icon", "Icon")
        static let color = s("field.color", "Color")
        static let tags = s("field.tags", "Tags (optional)")
        static let hostPlaceholder = s("field.hostPlaceholder", "server.example.com")
        static let usernamePlaceholder = s("field.usernamePlaceholder", "root")
        static let privateKey = s("field.privateKey", "Private Key")
        static let keyPassphrase = s("field.keyPassphrase", "Key Passphrase (optional)")
        static let fullName = s("field.fullName", "Full Name")
        static let yourName = s("field.yourName", "Your name")
        static let name = s("field.name", "Name")
        static let description = s("field.description", "Description")
        static let value = s("field.value", "Value")
        static let path = s("field.path", "Path")
    }

    // MARK: - Status (Shared.strings)
    enum Status {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let connecting = s("status.connecting", "Connecting...")
        static let connected = s("status.connected", "Connected")
        static let disconnected = s("status.disconnected", "Disconnected")
        static let loading = s("status.loading", "Loading...")
        static let pleaseWait = s("status.pleaseWait", "Please wait...")
        static let connectionFailed = s("status.connectionFailed", "Connection Failed")
        static let readyToConnect = s("status.readyToConnect", "Ready to Connect")
        static let requestingAuth = s("status.requestingAuth", "Requesting Authorization")
        static let encryptingAuth = s("status.encryptingAuth", "Encrypting Authorization")
        static let validatingAuth = s("status.validatingAuth", "Validating Authorization")
        static let authenticating = s("status.authenticating", "Authenticating")
        static let decryptingCreds = s("status.decryptingCreds", "Decrypting Credentials")
        static let verifyingHost = s("status.verifyingHost", "Verifying Host Key")
        static let establishingSSH = s("status.establishingSSH", "Establishing SSH Connection")
        static let disconnecting = s("status.disconnecting", "Disconnecting")
        static let active = s("status.active", "Active")
        static let inactive = s("status.inactive", "Inactive")
        static let online = s("status.online", "Online")
        static let offline = s("status.offline", "Offline")
        static let running = s("status.running", "Running")
        static let stopped = s("status.stopped", "Stopped")
        static let enabled = s("status.enabled", "Enabled")
        static let disabled = s("status.disabled", "Disabled")
        static let unknown = s("status.unknown", "Unknown")
        static let error = s("status.error", "Error")
        static let failed = s("status.failed", "Failed")

        static func percentage(_ value: Int) -> String {
            let dv: String.LocalizationValue = "\(value)%"
            return String(localized: "status.percentage", defaultValue: dv, table: table)
        }
    }

    // MARK: - App Info (Shared.strings)
    enum App {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let name = s("app.name", "AevonX")
        static let tagline = s("app.tagline", "Server Management, Reimagined.")
    }
}
