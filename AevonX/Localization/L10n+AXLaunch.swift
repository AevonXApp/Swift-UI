import Foundation

extension L10n {

    // MARK: - AXLaunch (AXLaunch.strings)
    enum AXLaunch {
        private static let table = "AXLaunch"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // General
        static let title = s("axlaunch.title", "Launch Project")
        static let update = s("axlaunch.update", "Update")
        static let launchNow = s("axlaunch.launchNow", "Launch Now")
        static let updateNow = s("axlaunch.updateNow", "Update Now")
        static let cancelLaunch = s("axlaunch.cancelLaunch", "Cancel Launch")
        static let complete = s("axlaunch.complete", "Launched!")
        static let failed = s("axlaunch.failed", "Launch failed")
        static let launching = s("axlaunch.launching", "Launching")
        static let saveConfig = s("axlaunch.saveConfig", "Save config for this project")

        // Steps
        static let stepSelectSource = s("axlaunch.step.selectSource", "Select Project")
        static let stepDetect = s("axlaunch.step.detect", "Project Detected")
        static let stepConfigure = s("axlaunch.step.configure", "Configuration")
        static let stepDomain = s("axlaunch.step.domain", "Domain")
        static let stepDatabase = s("axlaunch.step.database", "Database")
        static let stepReview = s("axlaunch.step.review", "Review")
        static let stepProgress = s("axlaunch.step.progress", "Launching")

        // Step 1 — Source
        static let dragDrop = s("axlaunch.dragDrop", "Drag & drop your project folder here")
        static let chooseFolder = s("axlaunch.chooseFolder", "Choose Folder")
        static let or = s("axlaunch.or", "or")
        static let recentProjects = s("axlaunch.recentProjects", "Recent:")

        // Step 2 — Detection
        static let match = s("axlaunch.match", "match")
        static let notCorrect = s("axlaunch.notCorrect", "Not correct?")
        static let selectManually = s("axlaunch.selectManually", "Select manually")
        static let ignoreList = s("axlaunch.ignoreList", "Ignore list:")
        static let filesToTransfer = s("axlaunch.filesToTransfer", "files")
        static let toTransfer = s("axlaunch.toTransfer", "to transfer")

        // Step 3 — Configure
        static let remotePath = s("axlaunch.remotePath", "Remote Path")
        static let envVars = s("axlaunch.envVars", "Environment Variables")
        static let loadEnvExample = s("axlaunch.loadEnvExample", "Load .env.example")
        static let addVariable = s("axlaunch.addVariable", "Add Variable")
        static let postSteps = s("axlaunch.postSteps", "Post-Launch Steps")
        static let loadDefaults = s("axlaunch.loadDefaults", "Load defaults")
        static let stepInstallDeps = s("axlaunch.step.installDeps", "Install dependencies")
        static let stepRunMigrations = s("axlaunch.step.runMigrations", "Run database migrations")
        static let stepRunSeeders = s("axlaunch.step.runSeeders", "Run seeders")
        static let stepRunBuild = s("axlaunch.step.runBuild", "Build assets")
        static let stepClearCaches = s("axlaunch.step.clearCaches", "Clear & rebuild caches")
        static let stepRestartService = s("axlaunch.step.restartService", "Restart service")

        // Step 4 — Domain
        static let addNewDomain = s("axlaunch.addNewDomain", "Add new domain")
        static let useExistingDomain = s("axlaunch.useExistingDomain", "Use existing domain")
        static let skipDomain = s("axlaunch.skipDomain", "Skip domain setup")
        static let webServer = s("axlaunch.webServer", "Web Server")
        static let enableSSL = s("axlaunch.enableSSL", "Enable SSL (Let's Encrypt)")
        static let forceHTTPS = s("axlaunch.forceHTTPS", "Force HTTPS redirect")

        // Step 5 — Database
        enum DB {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: AXLaunch.table) }

            static let autoCreate = s("axlaunch.db.autoCreate", "Auto Create")
            static let autoCreateDesc = s("axlaunch.db.autoCreateDesc", "AXLaunch handles everything")
            static let manual = s("axlaunch.db.manual", "Manual Setup")
            static let manualDesc = s("axlaunch.db.manualDesc", "I'll specify the credentials")
            static let existing = s("axlaunch.db.existing", "Use Existing")
            static let existingDesc = s("axlaunch.db.existingDesc", "Connect to an existing database")
            static let none = s("axlaunch.db.none", "No Database")
            static let noneDesc = s("axlaunch.db.noneDesc", "This project doesn't need one")
            static let engine = s("axlaunch.db.engine", "Engine")
            static let name = s("axlaunch.db.name", "Database Name")
            static let username = s("axlaunch.db.username", "Username")
            static let password = s("axlaunch.db.password", "Password")
            static let host = s("axlaunch.db.host", "Host")
            static let port = s("axlaunch.db.port", "Port")
            static let testConnection = s("axlaunch.db.testConnection", "Test Connection")
            static let regenerate = s("axlaunch.db.regenerate", "Regenerate")
            static let selectDatabase = s("axlaunch.db.selectDatabase", "Select Database")
        }

        // Step 6 — Review
        enum Review {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: AXLaunch.table) }

            static let server = s("axlaunch.review.server", "Server")
            static let framework = s("axlaunch.review.framework", "Framework")
            static let path = s("axlaunch.review.path", "Path")
            static let domain = s("axlaunch.review.domain", "Domain")
            static let database = s("axlaunch.review.database", "Database")
            static let transfer = s("axlaunch.review.transfer", "Transfer")
            static let steps = s("axlaunch.review.steps", "Steps")
        }

        // Diff / Update
        enum Diff {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: AXLaunch.table) }

            static let modified = s("axlaunch.diff.modified", "Modified")
            static let added = s("axlaunch.diff.added", "Added")
            static let deleted = s("axlaunch.diff.deleted", "Deleted")
            static let transferSize = s("axlaunch.diff.transferSize", "Transfer size")
            static let newMigrations = s("axlaunch.diff.newMigrations", "new migration files detected")
            static let changesSince = s("axlaunch.diff.changesSince", "Changes since last launch:")
            static let viewFileList = s("axlaunch.diff.viewFileList", "View file list")
        }

        // Progress
        static let progressConnecting = s("axlaunch.progress.connecting", "Connecting to server")
        static let progressTransferring = s("axlaunch.progress.transferring", "Transferring")
        static let progressConfiguring = s("axlaunch.progress.configuring", "Configuring")

        // Fleet integration
        static let fleetButton = s("axlaunch.fleetButton", "Launch")
        static let contextMenuLaunch = s("axlaunch.contextMenu.launch", "Launch Project")
        static let dropHere = s("axlaunch.dropHere", "Drop here to launch")

        // History
        static let historyTitle = s("axlaunch.history.title", "Deploy History")
        static let historyNoHistory = s("axlaunch.history.noHistory", "No deploy history")

        // Errors
        static let errorNoFolder = s("axlaunch.error.noFolder", "Please select a project folder")
        static let errorDetectionFailed = s("axlaunch.error.detectionFailed", "Could not detect project type")
        static let errorAlreadyActive = s("axlaunch.error.alreadyActive", "A launch is already active on this server")

        // Dynamic strings
        static func stepOf(_ current: Int, _ total: Int) -> String {
            let dv: String.LocalizationValue = "Step \(current) of \(total)"
            return String(localized: "axlaunch.stepOf", defaultValue: dv, table: table)
        }

        static func matchPercent(_ percent: Int) -> String {
            let dv: String.LocalizationValue = "\(percent)% match"
            return String(localized: "axlaunch.matchPercent", defaultValue: dv, table: table)
        }

        static func filesCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) files"
            return String(localized: "axlaunch.filesCount", defaultValue: dv, table: table)
        }

        static func transferAmount(_ size: String) -> String {
            let dv: String.LocalizationValue = "~\(size) to transfer"
            return String(localized: "axlaunch.transferAmount", defaultValue: dv, table: table)
        }

        static func newMigrationsCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) new migration files detected"
            return String(localized: "axlaunch.newMigrationsCount", defaultValue: dv, table: table)
        }

        static func diffFiles(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) files"
            return String(localized: "axlaunch.diffFiles", defaultValue: dv, table: table)
        }
    }
}
