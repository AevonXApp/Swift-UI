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
        static let truncate = s("database.truncate", "Truncate")
        static let insertRow = s("database.insertRow", "Insert Row")
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
        static let deleteFailed = s("database.deleteFailed", "Failed to delete database")
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
        static let noEnginesDescription = s("database.noEnginesDescription", "Go to the Applications tab to install database engines like MySQL, PostgreSQL, or Redis. Installed engines will appear here automatically.")
        static let noDatabasesDescription = s("database.noDatabasesDescription", "You have database engines installed but haven't created any databases yet. Create your first database to get started.")
        static let notInstalledDescription = s("database.notInstalledDescription", "This database engine is not installed on your server. Install it to create and manage databases.")
        static let createDatabase = s("database.createDatabase", "Create Database")
        static let chooseSqlFile = s("database.chooseSqlFile", "Choose .sql File")
        static let orPasteSql = s("database.orPasteSql", "Or paste SQL content below:")
        static let importing = s("database.importing", "Importing...")

        // Backup Section
        static let backupAndImport = s("database.backupAndImport", "Backup & Import")
        static let totalBackups = s("database.totalBackups", "Total Backups")
        static let latest = s("database.latest", "Latest")
        static let never = s("database.never", "Never")
        static let dbSize = s("database.dbSize", "DB Size")
        static let creating = s("database.creating", "Creating...")
        static let importSqlSubtitle = s("database.importSqlSubtitle", "Import .sql file or paste SQL content")
        static let restoreSubtitle = s("database.restoreSubtitle", "Restore database from a previous backup file")
        static let noBackups = s("database.noBackups", "No Backups")
        static let recentBackups = s("database.recentBackups", "Recent Backups")
        static let noBackupsFound = s("database.noBackupsFound", "No backups found")
        static let createFirstBackup = s("database.createFirstBackup", "Create your first backup to get started")
        static let unknownDate = s("database.unknownDate", "Unknown date")
        static let download = s("database.download", "Download")
        static let copyPath = s("database.copyPath", "Copy Path")
        static let backupPathCopied = s("database.backupPathCopied", "Backup path copied")

        // Activity Log Section
        static let activityLog = s("database.activityLog", "Activity Log")
        static let filterInsert = s("database.filterInsert", "Insert")
        static let filterUpdate = s("database.filterUpdate", "Update")
        static let filterAlter = s("database.filterAlter", "Alter")
        static let filterQuery = s("database.filterQuery", "Query")
        static let filterBackup = s("database.filterBackup", "Backup")
        static let noMatchingEntries = s("database.noMatchingEntries", "No matching entries")
        static let clearFilter = s("database.clearFilter", "Clear Filter")
        static let noActivityYet = s("database.noActivityYet", "No Activity Yet")
        static let actionsLoggedHere = s("database.actionsLoggedHere", "Actions you perform will be logged here")
        static let copyEntry = s("database.copyEntry", "Copy Entry")
        static let logEntryCopied = s("database.logEntryCopied", "Log entry copied")
        static let copyError = s("database.copyError", "Copy Error")
        static let errorMessageCopied = s("database.errorMessageCopied", "Error message copied")

        // Overview Section
        static let connections = s("database.connections", "Connections")
        static let totalRows = s("database.totalRows", "Total Rows")
        static let indexed = s("database.indexed", "Indexed")
        static let avgRowSize = s("database.avgRowSize", "Avg Row Size")
        static let indexSize = s("database.indexSize", "Index Size")
        static let dataSize = s("database.dataSize", "Data Size")
        static let quickSQL = s("database.quickSQL", "QUICK SQL")
        static let cmdEnterToExecute = s("database.cmdEnterToExecute", "⌘+Enter to execute")
        static let typeSQLQuery = s("database.typeSQLQuery", "Type SQL query...")
        static let quickActions = s("database.quickActions", "QUICK ACTIONS")
        static let runQuery = s("database.runQuery", "Run Query")
        static let browseData = s("database.browseData", "Browse Data")
        static let serverInfoLabel = s("database.serverInfoLabel", "SERVER INFO")
        static let serverInfoCopied = s("database.serverInfoCopied", "Server info copied")
        static let charset = s("database.charset", "Charset")
        static let collation = s("database.collation", "Collation")
        static let connectionLabel = s("database.connectionLabel", "CONNECTION")
        static let database = s("database.database", "Database")
        static let connectionString = s("database.connectionString", "Connection String")
        static let connectionStringCopied = s("database.connectionStringCopied", "Connection string copied")
        static let tableSizeBreakdown = s("database.tableSizeBreakdown", "TABLE SIZE BREAKDOWN")
        static let noTablesToAnalyze = s("database.noTablesToAnalyze", "No tables to analyze")
        static let newTable = s("database.newTable", "New Table")
        static let rows = s("database.rows", "Rows")
        static let data = s("database.data", "Data")
        static let index = s("database.index", "Index")
        static let menuInfo = s("database.menuInfo", "Info")
        static let copyTableName = s("database.copyTableName", "Copy Table Name")
        static let tableNameCopied = s("database.tableNameCopied", "Table name copied")
        static let copySelectQuery = s("database.copySelectQuery", "Copy SELECT Query")
        static let selectQueryCopied = s("database.selectQueryCopied", "SELECT query copied")
        static let navigate = s("database.navigate", "Navigate")
        static let countRows = s("database.countRows", "Count Rows")
        static let describeTable = s("database.describeTable", "Describe Table")
        static let maintenance = s("database.maintenance", "Maintenance")
        static let optimizeTable = s("database.optimizeTable", "Optimize Table")
        static let checkTable = s("database.checkTable", "Check Table")
        static let noTablesYet = s("database.noTablesYet", "No tables yet")
        static let createFirstTable = s("database.createFirstTable", "Create First Table")

        static func portLabel(_ port: String) -> String {
            let dv: String.LocalizationValue = "Port \(port)"
            return String(localized: "database.portLabel", defaultValue: dv, table: table)
        }

        static func tableCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) tables"
            return String(localized: "database.tableCount", defaultValue: dv, table: table)
        }

        static func moreTablesCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "+ \(count) more tables"
            return String(localized: "database.moreTablesCount", defaultValue: dv, table: table)
        }

        static func exportBackupSubtitle(_ name: String) -> String {
            let dv: String.LocalizationValue = "Export '\(name)' to a SQL dump file"
            return String(localized: "database.exportBackupSubtitle", defaultValue: dv, table: table)
        }

        static func entriesCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) entries"
            return String(localized: "database.entriesCount", defaultValue: dv, table: table)
        }

        static func logEntriesCopied(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) log entries copied"
            return String(localized: "database.logEntriesCopied", defaultValue: dv, table: table)
        }

        // Dialog Labels & Section Headers
        static let sqlPreview = s("database.sqlPreview", "SQL Preview")
        static let sqlCopied = s("database.sqlCopied", "SQL copied")
        static let tableNameHeader = s("database.tableNameHeader", "TABLE NAME")
        static let tableNamePlaceholder = s("database.tableNamePlaceholder", "e.g. users, posts, orders")
        static let columnsHeader = s("database.columnsHeader", "COLUMNS")
        static let addColumn = s("database.addColumn", "Add Column")
        static let columnNameHeader = s("database.columnNameHeader", "COLUMN NAME")
        static let typeHeader = s("database.typeHeader", "TYPE")
        static let lengthHeader = s("database.lengthHeader", "LENGTH")
        static let constraintsHeader = s("database.constraintsHeader", "CONSTRAINTS")
        static let positionHeader = s("database.positionHeader", "POSITION")
        static let endOfTable = s("database.endOfTable", "End of table")
        static let previewHeader = s("database.previewHeader", "PREVIEW")
        static let ready = s("database.ready", "Ready")
        static let notNullLabel = s("database.notNullLabel", "Not Null")
        static let primaryKeyLabel = s("database.primaryKeyLabel", "Primary Key")
        static let autoIncrementLabel = s("database.autoIncrementLabel", "Auto Increment")
        static let uniqueLabel = s("database.uniqueLabel", "Unique")
        static let editRow = s("database.editRow", "Edit Row")
        static let modified = s("database.modified", "MODIFIED")
        static let adding = s("database.adding", "Adding...")
        static let inserting = s("database.inserting", "Inserting...")
        static let saving = s("database.saving", "Saving...")
        static let renaming = s("database.renaming", "Renaming...")
        static let renameTable = s("database.renameTable", "Rename Table")
        static let currentName = s("database.currentName", "Current Name")
        static let newName = s("database.newName", "New Name")
        static let tableNameNoSpaces = s("database.tableNameNoSpaces", "Table names should not contain spaces")
        static let rename = s("database.rename", "Rename")
        static let createIndex = s("database.createIndex", "Create Index")
        static let indexName = s("database.indexName", "Index Name")
        static let indexType = s("database.indexType", "Index Type")
        static let uniqueIndex = s("database.uniqueIndex", "Unique Index")
        static let uniqueIndexDesc = s("database.uniqueIndexDesc", "Enforce unique values across selected columns")
        static let columnsLabel = s("database.columnsLabel", "Columns")
        static let navigationHeader = s("database.navigationHeader", "NAVIGATION")
        static let tablesHeader = s("database.tablesHeader", "TABLES")
        static let newBackup = s("database.newBackup", "New Backup")
        static let filterTables = s("database.filterTables", "Filter tables...")
        static let databaseCreatedBanner = s("database.databaseCreatedBanner", "Database created!")
        static let noEngines = s("database.noEngines", "No Database Engines")
        static let installEngineFirst = s("database.installEngineFirst", "Install MySQL or PostgreSQL from the Applications tab first.")
        static let databaseEngine = s("database.databaseEngine", "Database Engine")
        static let databaseNameLabel = s("database.databaseNameLabel", "Database Name")
        static let encoding = s("database.encoding", "Encoding")
        static let createUser = s("database.createUser", "Create database user")
        static let hostAccess = s("database.hostAccess", "Host Access")
        static let securityLabel = s("database.securityLabel", "Security")
        static let requireSSL = s("database.requireSSL", "Require SSL")
        static let selectEngine = s("database.selectEngine", "Select an engine")
        static let anyHost = s("database.anyHost", "Any Host (%)")
        static let somethingWentWrong = s("database.somethingWentWrong", "Something went wrong")
        static let autoGenerated = s("database.autoGenerated", "(auto-generated)")
        static let enterValue = s("database.enterValue", "Enter value...")
        static let sqlPreviewHeader = s("database.sqlPreviewHeader", "SQL PREVIEW")

        static func inDatabase(_ name: String) -> String {
            let dv: String.LocalizationValue = "in \(name)"
            return String(localized: "database.inDatabase", defaultValue: dv, table: table)
        }

        static func toTable(_ name: String) -> String {
            let dv: String.LocalizationValue = "to \(name)"
            return String(localized: "database.toTable", defaultValue: dv, table: table)
        }

        static func afterColumnName(_ name: String) -> String {
            let dv: String.LocalizationValue = "After \(name)"
            return String(localized: "database.afterColumnName", defaultValue: dv, table: table)
        }

        static func columnsCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) columns"
            return String(localized: "database.columnsCount", defaultValue: dv, table: table)
        }

        static func columnCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) column\(count == 1 ? "" : "s")"
            return String(localized: "database.columnCount", defaultValue: dv, table: table)
        }

        static func changedCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) changed"
            return String(localized: "database.changedCount", defaultValue: dv, table: table)
        }

        static func fieldsModified(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) field\(count == 1 ? "" : "s") modified"
            return String(localized: "database.fieldsModified", defaultValue: dv, table: table)
        }

        static func selectedCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) selected"
            return String(localized: "database.selectedCount", defaultValue: dv, table: table)
        }

        static func tablesFooterCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) tables"
            return String(localized: "database.tablesFooterCount", defaultValue: dv, table: table)
        }

        // Table Browser
        static let searchTables = s("database.searchTables", "Search tables...")
        static let noTablesFound = s("database.noTablesFound", "No tables found")
        static let analyzeTable = s("database.analyzeTable", "Analyze Table")
        static let selectATable = s("database.selectATable", "Select a Table")
        static let selectTableHint = s("database.selectTableHint", "Choose a table from the sidebar to view its structure and data")
        static let openFirstTable = s("database.openFirstTable", "Open First Table")
        static let createNew = s("database.createNew", "Create New")

        // Table Data
        static let noData = s("database.noData", "No Data")
        static let tableIsEmpty = s("database.tableIsEmpty", "This table is empty")
        static let insertFirstRow = s("database.insertFirstRow", "Insert First Row")
        static let searchRows = s("database.searchRows", "Search rows...")
        static let addRow = s("database.addRow", "Add Row")
        static let rowsPerPage = s("database.rowsPerPage", "Rows:")
        static let sorted = s("database.sorted", "Sorted:")
        static let hideColumn = s("database.hideColumn", "Hide Column")
        static let showAllColumns = s("database.showAllColumns", "Show All Columns")
        static let copyRowValues = s("database.copyRowValues", "Copy Row Values")
        static let rowValuesCopied = s("database.rowValuesCopied", "Row values copied")
        static let insertCopied = s("database.insertCopied", "INSERT statement copied")
        static let updateCopied = s("database.updateCopied", "UPDATE statement copied")
        static let rowCopied = s("database.rowCopied", "Row copied")
        static let jsonViewer = s("database.jsonViewer", "JSON Viewer")
        static let jsonCopied = s("database.jsonCopied", "JSON copied")
        static let pageLabel = s("database.pageLabel", "Page")
        static let emptyValue = s("database.emptyValue", "Empty")
        static let copyAsCSV = s("database.copyAsCSV", "Copy as CSV")
        static let copyAsJSON = s("database.copyAsJSON", "Copy as JSON")
        static let copyAsSQLInsert = s("database.copyAsSQLInsert", "Copy as SQL INSERT")
        static let copyAsMarkdown = s("database.copyAsMarkdown", "Copy as Markdown")
        static let copyAsTSV = s("database.copyAsTSV", "Copy as TSV")
        static let copyAsINSERT = s("database.copyAsINSERT", "Copy as INSERT")
        static let copyAsUPDATE = s("database.copyAsUPDATE", "Copy as UPDATE")
        static let copiedAsMarkdownTable = s("database.copiedAsMarkdownTable", "Copied as Markdown table")
        static let deleteRowAction = s("database.deleteRowAction", "Delete Row")
        static let duplicateRowAction = s("database.duplicateRowAction", "Duplicate Row")
        static let copyRow = s("database.copyRow", "Copy Row")

        // Table Structure
        static let ddlCopied = s("database.ddlCopied", "DDL copied to clipboard")
        static let copyDDL = s("database.copyDDL", "Copy DDL")
        static let defaultColHeader = s("database.defaultColHeader", "Default")
        static let copyColumnName = s("database.copyColumnName", "Copy Column Name")
        static let columnNameCopied = s("database.columnNameCopied", "Column name copied")
        static let copyColumnDDL = s("database.copyColumnDDL", "Copy Column DDL")
        static let columnDDLCopied = s("database.columnDDLCopied", "Column DDL copied")

        // Table Indexes
        static let indexesHeader = s("database.indexesHeader", "Indexes")
        static let noIndexes = s("database.noIndexes", "No Indexes")
        static let noIndexesDefined = s("database.noIndexesDefined", "This table has no indexes defined")
        static let uniqueColHeader = s("database.uniqueColHeader", "Unique")
        static let copyIndexDDL = s("database.copyIndexDDL", "Copy Index DDL")
        static let indexDDLCopied = s("database.indexDDLCopied", "Index DDL copied")
        static let copyIndexName = s("database.copyIndexName", "Copy Index Name")
        static let indexNameCopied = s("database.indexNameCopied", "Index name copied")
        static let yesLabel = s("database.yesLabel", "YES")
        static let noLabel = s("database.noLabel", "NO")

        // SQL Console
        static let sqlConsole = s("database.sqlConsole", "SQL Console")
        static let clearHistory = s("database.clearHistory", "Clear History")
        static let quickActionLabel = s("database.quickActionLabel", "Quick:")
        static let listTables = s("database.listTables", "List Tables")
        static let describeChip = s("database.describeChip", "Describe")
        static let insertKeywordLabel = s("database.insertKeywordLabel", "Insert:")
        static let formatAction = s("database.formatAction", "Format")
        static let formatSQLHint = s("database.formatSQLHint", "Format & beautify SQL")
        static let explainAction = s("database.explainAction", "Explain")
        static let copyQueryHint = s("database.copyQueryHint", "Copy query")
        static let queryCopied = s("database.queryCopied", "Query copied")
        static let errorCopied = s("database.errorCopied", "Error copied")
        static let executeAction = s("database.executeAction", "Execute")
        static let runningAction = s("database.runningAction", "Running...")
        static let queryError = s("database.queryError", "Query Error")
        static let checkSQLHint = s("database.checkSQLHint", "Check your SQL syntax, table names, and column references")
        static let pressToExecute = s("database.pressToExecute", "Press \u{2318}+Enter to execute")
        static let useQuickActions = s("database.useQuickActions", "Use quick actions or type your own SQL")
        static let querySuccess = s("database.querySuccess", "Query executed successfully")
        static let recentHistory = s("database.recentHistory", "Recent")
        static let configChip = s("database.configChip", "Config")
        static let statusChip = s("database.statusChip", "Status")
        static let administration = s("database.administration", "Administration")

        static func rowCount(_ count: Int64) -> String {
            let dv: String.LocalizationValue = "\(count) rows"
            return String(localized: "database.rowCount", defaultValue: dv, table: table)
        }

        static func colCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) cols"
            return String(localized: "database.colCount", defaultValue: dv, table: table)
        }

        static func deleteCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Delete \(count)"
            return String(localized: "database.deleteCount", defaultValue: dv, table: table)
        }

        static func rowCountDisplay(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) rows"
            return String(localized: "database.rowCountDisplay", defaultValue: dv, table: table)
        }

        static func columnCountDisplay(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) columns"
            return String(localized: "database.columnCountDisplay", defaultValue: dv, table: table)
        }

        static func rowsAffected(_ count: Int64) -> String {
            let dv: String.LocalizationValue = "\(count) rows affected"
            return String(localized: "database.rowsAffected", defaultValue: dv, table: table)
        }

        static func copiedRowsAsCSV(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Copied \(count) rows as CSV"
            return String(localized: "database.copiedRowsAsCSV", defaultValue: dv, table: table)
        }

        static func copiedRowsAsJSON(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Copied \(count) rows as JSON"
            return String(localized: "database.copiedRowsAsJSON", defaultValue: dv, table: table)
        }

        static func copiedRowsAsSQLInsert(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Copied \(count) rows as SQL INSERT"
            return String(localized: "database.copiedRowsAsSQLInsert", defaultValue: dv, table: table)
        }

        static func copiedRowsAsTSV(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Copied \(count) rows as TSV"
            return String(localized: "database.copiedRowsAsTSV", defaultValue: dv, table: table)
        }

        static func copiedRowsAsINSERT(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Copied \(count) rows as INSERT"
            return String(localized: "database.copiedRowsAsINSERT", defaultValue: dv, table: table)
        }

        static func indexDDLsCopied(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) index DDLs copied"
            return String(localized: "database.indexDDLsCopied", defaultValue: dv, table: table)
        }

        static func showingRows(_ start: Int, _ end: Int, _ total: Int) -> String {
            let dv: String.LocalizationValue = "Showing \(start)-\(end) of \(total) rows"
            return String(localized: "database.showingRows", defaultValue: dv, table: table)
        }

        static func ofTotalPages(_ total: Int) -> String {
            let dv: String.LocalizationValue = "of \(total)"
            return String(localized: "database.ofTotalPages", defaultValue: dv, table: table)
        }

        static func editorLineInfo(_ lines: Int, _ chars: Int) -> String {
            let dv: String.LocalizationValue = "\(lines) lines \u{00B7} \(chars) chars"
            return String(localized: "database.editorLineInfo", defaultValue: dv, table: table)
        }

        static func copiedPrefix(_ prefix: String) -> String {
            let dv: String.LocalizationValue = "Copied: \(prefix)"
            return String(localized: "database.copiedPrefix", defaultValue: dv, table: table)
        }

        static func intoDatabase(_ name: String) -> String {
            let dv: String.LocalizationValue = "into \(name)"
            return String(localized: "database.intoDatabase", defaultValue: dv, table: table)
        }

        static func charCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) chars"
            return String(localized: "database.charCount", defaultValue: dv, table: table)
        }

        static func lineCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) lines"
            return String(localized: "database.lineCount", defaultValue: dv, table: table)
        }

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

        static func databaseCreated(_ name: String) -> String {
            let dv: String.LocalizationValue = "Database '\(name)' created successfully"
            return String(localized: "database.databaseCreated", defaultValue: dv, table: table)
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
        static let refresh = s("database.refresh", "Refresh")
        static let addUser = s("database.addUser", "Add User")
        static let noMysqlPostgresqlOrRedisDatabasesWereDetectedOnThisServer = s("database.noMysqlPostgresqlOrRedisDatabasesWereDetectedOnThisServer", "No MySQL, PostgreSQL, or Redis databases were detected on this server.")
        static let notConnected = s("database.notConnected", "Not Connected")
        static let connectToTheServerToViewDatabases = s("database.connectToTheServerToViewDatabases", "Connect to the server to view databases.")
        static let noUsersFound = s("database.noUsersFound", "No Users Found")
        static let connectToTheServerToViewDatabaseUsers = s("database.connectToTheServerToViewDatabaseUsers", "Connect to the server to view database users.")
        static let user = s("database.user", "User")
        static let host = s("database.host", "Host")
        static let privileges = s("database.privileges", "Privileges")
        static let lastActive = s("database.lastActive", "Last Active")
        static let console = s("database.console", "Console")
        static let backup = s("database.backup", "Backup")
        static let databaseName = s("database.databaseName", "Database Name")
        static let databaseType = s("database.databaseType", "Database Type")
        static let cancel = s("database.cancel", "Cancel")
        static let addDatabaseUser = s("database.addDatabaseUser", "Add Database User")
        static let username = s("database.username", "Username")
        static let password = s("database.password", "Password")
        static let useForAnyHostOrLocalhostForLocalAccessOnly = s("database.useForAnyHostOrLocalhostForLocalAccessOnly", "Use % for any host, or localhost for local access only.")
        static let configurationFile = s("database.configurationFile", "Configuration File")
        static let versionManagement = s("database.versionManagement", "Version Management")
        static let currentVersion = s("database.currentVersion", "Current Version")
        static let security = s("database.security", "Security")
        static let redisPasswordRequirepass = s("database.redisPasswordRequirepass", "Redis Password (requirepass)")
        static let settingAPasswordEnablesTheRequirepassDirectiveARestartIsRequired = s("database.settingAPasswordEnablesTheRequirepassDirectiveARestartIsRequired", "Setting a password enables the 'requirepass' directive. A restart is required.")
        static let performanceOptimization = s("database.performanceOptimization", "Performance Optimization")
        static let aiPoweredOptimizationRecommendationsWillAppearHere = s("database.aiPoweredOptimizationRecommendationsWillAppearHere", "AI-powered optimization recommendations will appear here.")
        static let quickPresets = s("database.quickPresets", "Quick Presets")
        static let engineInformation = s("database.engineInformation", "Engine Information")
        static let performanceStatistics = s("database.performanceStatistics", "Performance Statistics")
        static let aiAssistedInstallationWithOptimalConfiguration = s("database.aiAssistedInstallationWithOptimalConfiguration", "AI-assisted installation with optimal configuration")
        static let analyzingYourServer = s("database.analyzingYourServer", "Analyzing your server...")
        static let ourAiIsDeterminingTheBestDatabaseVersionAndConfigurationForYourSystem = s("database.ourAiIsDeterminingTheBestDatabaseVersionAndConfigurationForYourSystem", "Our AI is determining the best database version and configuration for your system")
        static let systemRequirements = s("database.systemRequirements", "System Requirements")
        static let recommendedVersions = s("database.recommendedVersions", "Recommended Versions")
        static let warnings = s("database.warnings", "Warnings")
        static let compatible = s("database.compatible", "Compatible")
        static let installationSuccessful = s("database.installationSuccessful", "Installation Successful!")
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
        static let configurationFile = s("engine.configurationFile", "Configuration File")
        static let security = s("engine.security", "Security")
        static let redisRequirepass = s("engine.redisRequirepass", "Redis Password (requirepass)")
        static let enterPassword = s("engine.enterPassword", "Enter password")
        static let requirepassHint = s("engine.requirepassHint", "Setting a password enables the 'requirepass' directive. A restart is required.")
        static let loadConfigFailed = s("engine.loadConfigFailed", "Failed to load configuration")
        static let updatePasswordFailed = s("engine.updatePasswordFailed", "Failed to update password")
        static let updateRedisPasswordFailed = s("engine.updateRedisPasswordFailed", "Failed to update Redis password")
        static let saveFailed = s("engine.saveFailed", "Failed to save")
        static let saveConfigFailed = s("engine.saveConfigFailed", "Failed to save configuration")
        static let versions = s("engine.versions", "Versions")
        static let availableVersions = s("engine.availableVersions", "Available Versions")
        static let updateToLatest = s("engine.updateToLatest", "Update to Latest")
        static let noVersionsFetched = s("engine.noVersionsFetched", "No versions fetched yet.")
        static let fetchAvailableVersions = s("engine.fetchAvailableVersions", "Fetch Available Versions")
        static let installed = s("engine.installed", "Installed")
        static let recommended = s("engine.recommended", "Recommended")
        static let fetchVersionsFailed = s("engine.fetchVersionsFailed", "Failed to fetch available versions")
        static let installFailed = s("engine.installFailed", "Installation failed")
        static let updateFailed = s("engine.updateFailed", "Update failed")
        static let analysisFailed = s("engine.analysisFailed", "Analysis failed")
        static let analyzePerformanceFailed = s("engine.analyzePerformanceFailed", "Failed to analyze performance")
        static let loadErrorLogFailed = s("engine.loadErrorLogFailed", "Failed to load error log")
        static let loadSlowLogFailed = s("engine.loadSlowLogFailed", "Failed to load slow query log")

        // MARK: - Overview Section
        static let overview = s("engine.overview", "Overview")
        static let loadingEngineData = s("engine.loadingEngineData", "Loading engine data...")
        static let dangerZone = s("engine.dangerZone", "Danger Zone")
        static let uninstallWarning = s("engine.uninstallWarning", "Uninstalling the engine will remove all binaries and may result in partial or total data loss if backups are not maintained.")
        static let engineInformation = s("engine.engineInformation", "Engine Information")
        static let performanceStatistics = s("engine.performanceStatistics", "Performance Statistics")

        // MARK: - Access Section
        static let accessPermissions = s("engine.accessPermissions", "Access & Permissions")
        static let databaseUsers = s("engine.databaseUsers", "Database Users")
        static let noUsersFound = s("engine.noUsersFound", "No users found or user listing not supported for this engine.")

        // MARK: - Optimization Section
        static let optimization = s("engine.optimization", "Optimization")
        static let performanceAnalysis = s("engine.performanceAnalysis", "Performance Analysis")
        static let aiOptimizationHint = s("engine.aiOptimizationHint", "AI-powered optimization recommendations will appear here based on your database usage patterns.")
        static let analyzePerformance = s("engine.analyzePerformance", "Analyze Performance")
        static let quickPresets = s("engine.quickPresets", "Quick Presets")
        static let presetWebApp = s("engine.presetWebApp", "Web Application")
        static let presetWebAppDesc = s("engine.presetWebAppDesc", "Optimized for web workloads with high read/write ratio")
        static let presetDataWarehouse = s("engine.presetDataWarehouse", "Data Warehouse")
        static let presetDataWarehouseDesc = s("engine.presetDataWarehouseDesc", "Optimized for analytics and reporting workloads")
        static let presetDevelopment = s("engine.presetDevelopment", "Development")
        static let presetDevelopmentDesc = s("engine.presetDevelopmentDesc", "Balanced configuration for development environments")

        // MARK: - Sidebar
        static let backToDatabases = s("engine.backToDatabases", "Back to Databases")

        // MARK: - Info Row Labels
        static let labelType = s("engine.labelType", "Type")
        static let labelVersion = s("engine.labelVersion", "Version")
        static let labelInstallPath = s("engine.labelInstallPath", "Install Path")
        static let labelStatus = s("engine.labelStatus", "Status")
        static let labelService = s("engine.labelService", "Service")
        static let labelBoot = s("engine.labelBoot", "Boot")
        static let labelConfigFile = s("engine.labelConfigFile", "Config File")

        // MARK: - Metrics Labels
        static let metricUptime = s("engine.metricUptime", "Uptime")
        static let metricConnections = s("engine.metricConnections", "Connections")
        static let metricMemory = s("engine.metricMemory", "Memory")
        static let metricTotalQueries = s("engine.metricTotalQueries", "Total Queries")
        static let metricAvgQueryTime = s("engine.metricAvgQueryTime", "Avg Query Time")
        static let metricMaxQueryTime = s("engine.metricMaxQueryTime", "Max Query Time")
        static let metricCacheHit = s("engine.metricCacheHit", "Cache Hit")

        // MARK: - Version Labels
        static let lts = s("engine.lts", "LTS")
        static let fetchingVersions = s("engine.fetchingVersions", "Fetching versions...")
        static let noVersionsAvailable = s("engine.noVersionsAvailable", "No versions available")
        static let couldNotFetchVersions = s("engine.couldNotFetchVersions", "Could not fetch version information.")

        static func uninstallEngine(_ name: String) -> String {
            let dv: String.LocalizationValue = "Uninstall \(name)"
            return String(localized: "engine.uninstallEngine", defaultValue: dv, table: table)
        }

        static func releasedDate(_ date: Date) -> String {
            return String(localized: "engine.releasedDate", defaultValue: "Released \(date, format: .dateTime.year().month().day())", table: table)
        }

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
        static let enableFailed = s("service.enableFailed", "Enable on boot failed")
        static let disableFailed = s("service.disableFailed", "Disable on boot failed")
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
