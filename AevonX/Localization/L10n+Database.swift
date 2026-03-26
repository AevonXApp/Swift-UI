import Foundation

extension L10n {

    // MARK: - Database (Database.strings)
    enum Database {
        private static let table = "Database"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // Actions
        static let createBackup = s("database.createBackup", "Create Backup")
        static let restore = s("database.restore", "Restore")
        static let importSQL = s("database.importSQL", "Import SQL")
        static let export = s("database.export", "Export")
        static let createTable = s("database.createTable", "Create Table")
        static let drop = s("database.drop", "Drop")
        static let truncate = s("database.truncate", "Truncate")
        static let optimize = s("database.optimize", "Optimize")
        static let repair = s("database.repair", "Repair")
        static let insertRow = s("database.insertRow", "Insert Row")
        static let updateRow = s("database.updateRow", "Update")
        static let deleteRow = s("database.deleteRow", "Delete")
        static let duplicateRow = s("database.duplicateRow", "Duplicate")
        static let editConfig = s("database.editConfig", "Edit Configuration")
        static let switchVersion = s("database.switchVersion", "Switch Version")
        static let installVersion = s("database.installVersion", "Install New Version")
        static let selectVersion = s("database.selectVersion", "Select Version")

        // Toast messages
        static let rowInserted = s("database.rowInserted", "Row inserted successfully")
        static let rowInsertFailed = s("database.rowInsertFailed", "Failed to insert row")
        static let rowUpdated = s("database.rowUpdated", "Row updated successfully")
        static let rowUpdateFailed = s("database.rowUpdateFailed", "Failed to update row")
        static let noPrimaryKey = s("database.noPrimaryKey", "Cannot determine primary key for this row")
        static let rowDeleted = s("database.rowDeleted", "Row deleted successfully")
        static let rowDeleteFailed = s("database.rowDeleteFailed", "Failed to delete row")
        static let noPrimaryKeys = s("database.noPrimaryKeys", "Cannot determine primary keys for selected rows")
        static let rowsDeleteFailed = s("database.rowsDeleteFailed", "Failed to delete rows")
        static let searchFailed = s("database.searchFailed", "Search failed")
        static let backupDeleted = s("database.backupDeleted", "Backup deleted")
        static let backupDeleteFailed = s("database.backupDeleteFailed", "Failed to delete backup")
        static let backupSaved = s("database.backupSaved", "Backup saved successfully")
        static let downloadFailed = s("database.downloadFailed", "Download failed")
        static let sqlEmpty = s("database.sqlEmpty", "SQL content is empty")
        static let sqlImported = s("database.sqlImported", "SQL imported successfully")
        static let importFailed = s("database.importFailed", "Import failed")
        static let encodePkFailed = s("database.encodePkFailed", "Failed to encode primary key")
        static let duplicateNotSupported = s("database.duplicateNotSupported", "Duplicate row not supported")
        static let duplicateFailed = s("database.duplicateFailed", "Duplicate failed")
        static let rowDuplicated = s("database.rowDuplicated", "Row duplicated")
        static let dropIndexNotSupported = s("database.dropIndexNotSupported", "Drop index not supported")
        static let dropIndexFailed = s("database.dropIndexFailed", "Drop index failed")
        static let renameNotSupported = s("database.renameNotSupported", "Rename table not supported")
        static let renameFailed = s("database.renameFailed", "Rename failed")
        static let backupRestored = s("database.backupRestored", "Backup restored successfully")
        static let restoreFailed = s("database.restoreFailed", "Restore failed")
        static let loadTablesFailed = s("database.loadTablesFailed", "Failed to load tables")
        static let loadStructureFailed = s("database.loadStructureFailed", "Failed to load table structure")
        static let loadDataFailed = s("database.loadDataFailed", "Failed to load data")
        static let backupCreated = s("database.backupCreated", "Backup created successfully")
        static let backupFailed = s("database.backupFailed", "Backup failed")
        static let createTableFailed = s("database.createTableFailed", "Failed to create table")

        // UI Labels
        static let deleteDatabase = s("database.deleteDatabase", "Delete Database")
        static let dropTable = s("database.dropTable", "Drop Table")
        static let truncateTable = s("database.truncateTable", "Truncate Table")
        static let dropColumn = s("database.dropColumn", "Drop Column")
        static let deleteSelectedRows = s("database.deleteSelectedRows", "Delete Selected Rows")
        static let deleteBackup = s("database.deleteBackup", "Delete Backup")
        static let dropIndex = s("database.dropIndex", "Drop Index")
        static let deleteRowTitle = s("database.deleteRowTitle", "Delete Row")
        static let restoreBackup = s("database.restoreBackup", "Restore Backup")
        static let cannotBeUndone = s("database.cannotBeUndone", "This action cannot be undone.")
        static let loadingDatabases = s("database.loadingDatabases", "Loading databases...")
        static let failedToLoadDatabases = s("database.failedToLoadDatabases", "Failed to Load Databases")
        static let newDatabase = s("database.newDatabase", "New Database")
        static let noDatabases = s("database.noDatabases", "No Databases")
        static let noEnginesInstalled = s("database.noEnginesInstalled", "No Database Engines Installed")
        static let noDatabasesFound = s("database.noDatabasesFound", "No Databases Found")
        static let createFirstDatabase = s("database.createFirstDatabase", "Create First Database")
        static let searchDatabases = s("database.searchDatabases", "Search databases...")
        static let manage = s("database.manage", "Manage")
        static let notInstalled = s("database.notInstalled", "Not Installed")
        static let openDetails = s("database.openDetails", "Open Details")
        static let databases = s("database.databases", "Databases")
        static let totalSize = s("database.totalSize", "Total Size")
        static let users = s("database.users", "Users")
        static let engines = s("database.engines", "Engines")
        static let all = s("database.all", "All")
        static let tables = s("database.tables", "Tables")
        static let size = s("database.size", "Size")
        static let actions = s("database.actions", "Actions")
        static let status = s("database.status", "Status")
        static let conns = s("database.conns", "Conns")
        static let noRecommendationsAvailable = s("database.noRecommendationsAvailable", "No recommendations available.")
        static let noEnginesDescription = s("database.noEnginesDescription", "Go to the Applications tab to install database engines like MySQL, PostgreSQL, or Redis. Installed engines will appear here automatically.")
        static let noDatabasesDescription = s("database.noDatabasesDescription", "You have database engines installed but haven't created any databases yet. Create your first database to get started.")
        static let notInstalledDescription = s("database.notInstalledDescription", "This database engine is not installed on your server. Install it to create and manage databases.")
        static let createDatabase = s("database.createDatabase", "Create Database")

        // Alert messages (interpolated — can't use s() helper)
        static func confirmDropTable(_ name: String) -> String {
            let dv: String.LocalizationValue = "Are you sure you want to drop '\(name)'? This will permanently delete the table and all its data. This action cannot be undone."
            return String(localized: "database.confirmDropTable", defaultValue: dv, table: table)
        }

        static func confirmTruncateTable(_ name: String) -> String {
            let dv: String.LocalizationValue = "Are you sure you want to truncate '\(name)'? This will remove all rows but keep the table structure."
            return String(localized: "database.confirmTruncateTable", defaultValue: dv, table: table)
        }

        static func confirmDeleteDatabase(_ name: String) -> String {
            let dv: String.LocalizationValue = "Are you sure you want to delete database '\(name)'? This cannot be undone."
            return String(localized: "database.confirmDeleteDatabase", defaultValue: dv, table: table)
        }

        static func confirmDropColumn(_ name: String) -> String {
            let dv: String.LocalizationValue = "Are you sure you want to drop column '\(name)'? Data in this column will be lost."
            return String(localized: "database.confirmDropColumn", defaultValue: dv, table: table)
        }

        static let confirmDeleteRow = s("database.confirmDeleteRow", "Are you sure you want to delete this row?")

        static func confirmDeleteSelectedRows(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Are you sure you want to delete \(count) selected rows?"
            return String(localized: "database.confirmDeleteSelectedRows", defaultValue: dv, table: table)
        }

        static let confirmDeleteBackup = s("database.confirmDeleteBackup", "Are you sure you want to delete this backup file?")

        static func confirmDropIndex(_ name: String) -> String {
            let dv: String.LocalizationValue = "Are you sure you want to drop index '\(name)'? This may affect query performance."
            return String(localized: "database.confirmDropIndex", defaultValue: dv, table: table)
        }

        static let confirmRestoreBackup = s("database.confirmRestoreBackup", "Are you sure you want to restore from this backup? This will overwrite the current database data.")

        static func backupCreatedFor(_ name: String) -> String {
            let dv: String.LocalizationValue = "Backup created for '\(name)'"
            return String(localized: "database.backupCreatedFor", defaultValue: dv, table: table)
        }

        static func noDatabasesFor(_ name: String) -> String {
            let dv: String.LocalizationValue = "No databases found for \(name). Create one to get started."
            return String(localized: "database.noDatabasesFor", defaultValue: dv, table: table)
        }

        static func typeNotInstalled(_ name: String) -> String {
            let dv: String.LocalizationValue = "\(name) Not Installed"
            return String(localized: "database.typeNotInstalled", defaultValue: dv, table: table)
        }

        static func goToApplicationsToInstall(_ name: String) -> String {
            let dv: String.LocalizationValue = "Go to the Applications tab to install \(name) on your server."
            return String(localized: "database.goToApplicationsToInstall", defaultValue: dv, table: table)
        }

        static func rowsDeleted(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) row(s) deleted successfully"
            return String(localized: "database.rowsDeleted", defaultValue: dv, table: table)
        }

        static func indexDropped(_ name: String) -> String {
            let dv: String.LocalizationValue = "Index '\(name)' dropped"
            return String(localized: "database.indexDropped", defaultValue: dv, table: table)
        }

        static func tableRenamed(_ name: String) -> String {
            let dv: String.LocalizationValue = "Table renamed to '\(name)'"
            return String(localized: "database.tableRenamed", defaultValue: dv, table: table)
        }

        static func tableCreated(_ name: String) -> String {
            let dv: String.LocalizationValue = "Table '\(name)' created successfully"
            return String(localized: "database.tableCreated", defaultValue: dv, table: table)
        }

        static func actionSuccessful(_ action: String) -> String {
            let dv: String.LocalizationValue = "\(action) successful"
            return String(localized: "database.actionSuccessful", defaultValue: dv, table: table)
        }

        static func actionFailed(_ action: String) -> String {
            let dv: String.LocalizationValue = "\(action) failed"
            return String(localized: "database.actionFailed", defaultValue: dv, table: table)
        }

        static func operationFailed(_ msg: String) -> String {
            let dv: String.LocalizationValue = "Operation failed: \(msg)"
            return String(localized: "database.operationFailed", defaultValue: dv, table: table)
        }
    }

    // MARK: - Engine (Database.strings)
    enum Engine {
        private static let table = "Database"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let engineManagement = s("engine.engineManagement", "Engine Management")
        static let serviceControl = s("engine.serviceControl", "Service Control")
        static let engineInfo = s("engine.engineInfo", "Engine Info")
        static let configuration = s("engine.configuration", "Configuration")
        static let noConfigLoaded = s("engine.noConfigLoaded", "No configuration loaded")
        static let serviceLogs = s("engine.serviceLogs", "Service Logs")
        static let versionManagement = s("engine.versionManagement", "Version Management")
        static let currentVersion = s("engine.currentVersion", "Current Version")
        static let engine = s("engine.engine", "Engine")
        static let versionColon = s("engine.versionColon", "Version:")
        static let pathColon = s("engine.pathColon", "Path:")
        static let version = s("engine.version", "Version")
        static let type = s("engine.type", "Type")
        static let relationalSQL = s("engine.relationalSQL", "Relational (SQL)")
        static let noSQL = s("engine.noSQL", "NoSQL")
        static let loadConfigFailed = s("engine.loadConfigFailed", "Failed to load configuration")
        static let updatePasswordFailed = s("engine.updatePasswordFailed", "Failed to update password")
        static let updateRedisPasswordFailed = s("engine.updateRedisPasswordFailed", "Failed to update Redis password")
        static let saveFailed = s("engine.saveFailed", "Failed to save")
        static let saveConfigFailed = s("engine.saveConfigFailed", "Failed to save configuration")
        static let fetchVersionsFailed = s("engine.fetchVersionsFailed", "Failed to fetch available versions")
        static let installFailed = s("engine.installFailed", "Installation failed")
        static let updateFailed = s("engine.updateFailed", "Update failed")
        static let analysisFailed = s("engine.analysisFailed", "Analysis failed")
        static let analyzePerformanceFailed = s("engine.analyzePerformanceFailed", "Failed to analyze performance")
        static let loadErrorLogFailed = s("engine.loadErrorLogFailed", "Failed to load error log")
        static let loadSlowLogFailed = s("engine.loadSlowLogFailed", "Failed to load slow query log")

        static func loadingData(_ name: String) -> String {
            let dv: String.LocalizationValue = "Loading \(name) data\u{2026}"
            return String(localized: "engine.loadingData", defaultValue: dv, table: table)
        }

        static func logViewerFor(_ name: String) -> String {
            let dv: String.LocalizationValue = "Log viewer for \(name)"
            return String(localized: "engine.logViewerFor", defaultValue: dv, table: table)
        }

        static func versionManagementFor(_ name: String) -> String {
            let dv: String.LocalizationValue = "Version management for \(name)"
            return String(localized: "engine.versionManagementFor", defaultValue: dv, table: table)
        }

        static func installVersionFailed(_ type: String, _ version: String) -> String {
            let dv: String.LocalizationValue = "Failed to install \(type) \(version)"
            return String(localized: "engine.installVersionFailed", defaultValue: dv, table: table)
        }

        static func updateTypeFailed(_ type: String) -> String {
            let dv: String.LocalizationValue = "Failed to update \(type)"
            return String(localized: "engine.updateTypeFailed", defaultValue: dv, table: table)
        }
    }

    // MARK: - Service Control (Database.strings)
    enum Service {
        private static let table = "Database"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let startFailed = s("service.startFailed", "Start failed")
        static let stopFailed = s("service.stopFailed", "Stop failed")
        static let restartFailed = s("service.restartFailed", "Restart failed")
        static let installFailed = s("service.installFailed", "Installation failed")
        static let uninstallFailed = s("service.uninstallFailed", "Uninstall failed")
        static let configUpdateFailed = s("service.configUpdateFailed", "Config update failed")
    }

    // MARK: - Installation (Database.strings)
    enum Install {
        private static let table = "Database"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let noRecommendationsAvailable = s("install.noRecommendationsAvailable", "No recommendations available.")
        static let cancelled = s("install.cancelled", "Installation was cancelled")
        static let noRecommendation = s("install.noRecommendation", "No installation recommendation available")

        static func stepFailed(_ step: String, _ reason: String) -> String {
            let dv: String.LocalizationValue = "Step '\(step)' failed: \(reason)"
            return String(localized: "install.stepFailed", defaultValue: dv, table: table)
        }

        static func validationFailed(_ step: String, _ reason: String) -> String {
            let dv: String.LocalizationValue = "Validation for '\(step)' failed: \(reason)"
            return String(localized: "install.validationFailed", defaultValue: dv, table: table)
        }
    }

    // MARK: - Error Resolution (Database.strings)
    enum ErrorResolution {
        private static let table = "Database"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("errorResolution.title", "Error Resolution")
        static let installationError = s("errorResolution.installationError", "Installation Error")
        static let analyzingError = s("errorResolution.analyzingError", "Analyzing Error...")
        static let aiDiagnosing = s("errorResolution.aiDiagnosing", "AI is diagnosing the issue and finding solutions")
        static let diagnosis = s("errorResolution.diagnosis", "Diagnosis")
        static let rootCause = s("errorResolution.rootCause", "Root Cause:")
        static let suggestedSolutions = s("errorResolution.suggestedSolutions", "Suggested Solutions")
        static let executingSolution = s("errorResolution.executingSolution", "Executing Solution...")
        static let issueResolved = s("errorResolution.issueResolved", "Issue Resolved")
        static let resumeInstallation = s("errorResolution.resumeInstallation", "Resume Installation")
        static let resolutionFailed = s("errorResolution.resolutionFailed", "Resolution Failed")
        static let autoFix = s("errorResolution.autoFix", "Auto-Fix")
        static let executeManually = s("errorResolution.executeManually", "Execute Manually")
        static let analyzeFailed = s("errorResolution.analyzeFailed", "Failed to analyze error")
        static let executeFailed = s("errorResolution.executeFailed", "Failed to execute solution")
        static let noContext = s("errorResolution.noContext", "No active error resolution context")
        static let solutionFailed = s("errorResolution.solutionFailed", "Solution execution failed")
    }
}
