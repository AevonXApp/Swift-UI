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
        static let discard = s("button.discard", "Discard")
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
        static let algorithm = s("field.algorithm", "Algorithm")
        static let comment = s("field.comment", "Comment")
        static let passphrase = s("field.passphrase", "Passphrase")
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
        static let active = s("status.active", "Active")
        static let inactive = s("status.inactive", "Inactive")
        static let online = s("status.online", "Online")
        static let offline = s("status.offline", "Offline")
        static let running = s("status.running", "Running")
        static let stopped = s("status.stopped", "Stopped")
        static let enabled = s("status.enabled", "Enabled")
        static let disabled = s("status.disabled", "Disabled")
        static let unknown = s("status.unknown", "Unknown")
        static let empty = s("status.empty", "Empty")
        static let error = s("status.error", "Error")
        static let failed = s("status.failed", "Failed")
        static let successful = s("status.successful", "Successful")

        static func percentage(_ value: Int) -> String {
            let dv: String.LocalizationValue = "\(value)%"
            return String(localized: "status.percentage", defaultValue: dv, table: table)
        }
    }

    // MARK: - Common UI Labels (Shared.strings)
    /// Short, all-caps section headers and badge text that appears across many
    /// screens. Keep the default values uppercase so existing visuals are
    /// preserved when the app runs in English.
    enum Label {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // Badges
        static let active = s("label.active", "ACTIVE")
        static let current = s("label.current", "CURRENT")
        static let main = s("label.main", "MAIN")
        static let primary = s("label.primary", "PRIMARY")
        static let success = s("label.success", "SUCCESS")
        static let down = s("label.down", "DOWN")
        static let banned = s("label.banned", "Banned")
        static let whitelisted = s("label.whitelisted", "Whitelisted")

        // Section headers / table column titles
        static let actions = s("label.actions", "ACTIONS")
        static let extensions = s("label.extensions", "EXTENSIONS")
        static let favorites = s("label.favorites", "FAVORITES")
        static let recent = s("label.recent", "RECENT")
        static let preview = s("label.preview", "PREVIEW")
        static let tools = s("label.tools", "TOOLS")
        static let target = s("label.target", "TARGET")
        static let results = s("label.results", "RESULTS")
        static let level = s("label.level", "LEVEL")
        static let time = s("label.time", "TIME")
        static let status = s("label.status", "STATUS")
        static let method = s("label.method", "METHOD")
        static let value = s("label.value", "VALUE")

        // Multi-line / multi-sentence empty-state and explainer copy.
        // Newlines are preserved literally; the localiser can re-flow them.
        static let ftpEmptyState = s("label.ftpEmptyState",
            "Create FTP accounts to allow file transfer access.\nUsers can connect using any FTP client.")
        static let pureFTPdMissing = s("label.pureFTPdMissing",
            "PureFTPd is required for FTP user management.\nInstall it now to enable FTP access on this server.")
        static let pm2EmptyState = s("label.pm2EmptyState",
            "PM2 is a process manager for Node.js applications.\nIt keeps your app running and auto-restarts on crashes.")
        static let gitEmptyState = s("label.gitEmptyState",
            "Clone an existing repository or initialize a new one.\nSupports GitHub, GitLab, Bitbucket, and any Git server.")

        // Strings with embedded quotes — kept escaped exactly as the original.
        static let invalidAppNameAvoidPaths = s("label.invalidAppNameAvoidPaths",
            "Invalid app name: avoid paths with \"..\" or shell characters")
        static let dockerLogsHint = s("label.dockerLogsHint",
            "Select containers above and click \"Fetch Logs\" to load aggregated logs")
        static let liteSpeedDoctorHint = s("label.liteSpeedDoctorHint",
            "Click \"Run Doctor\" to perform health checks")
        static let sslViewContentHint = s("label.sslViewContentHint",
            "Click \"View Content\" to load the certificate and private key PEM data")

        // Misc one-offs.
        static let configureSecurityHeaders = s("label.configureSecurityHeaders",
            "Configure security headers for your website.")
        static let dockerToolsVersion = s("label.dockerToolsVersion", "Docker Tools v1.0")
        static let skeletonLoadingStates = s("label.skeletonLoadingStates", "Skeleton Loading States")
    }

    // MARK: - Technical/protocol literals — DO NOT translate (Shared.strings)
    /// These look like translatable strings but are actually protocol or
    /// SQL keywords the user expects to see verbatim. Wrapped in an enum so
    /// future audits can grep for the wrapper rather than the bare literal.
    enum Literal {
        static let null    = "NULL"
        static let auto    = "AUTO"
        static let listen  = "LISTEN"
        static let cidr    = "CIDR"
        static let deny    = "DENY"
        static let sameOrigin = "SAMEORIGIN"
    }

    // MARK: - App Info (Shared.strings)
    enum App {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let name = s("app.name", "AevonX")
        static let tagline = s("app.tagline", "Server Management, Reimagined.")
    }
}

extension L10n {
    enum Shared {
        private static let table = "Shared"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }
        static let invalidInput = s("shared.invalidInput", "Invalid input")
        static let viewDetails = s("shared.viewDetails", "View Details")
    }
}
