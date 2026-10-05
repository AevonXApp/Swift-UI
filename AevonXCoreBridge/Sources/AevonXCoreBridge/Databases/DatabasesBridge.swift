//
//  DatabasesBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Database management operations.
//  Covers all 9 engines with unified adapter-routing API.
//  40+ methods spanning detection, lifecycle, users, tables, rows, config, backup.
//

import Foundation
import AevonXCoreLib

// MARK: - Databases Bridge

/// Bridge to Go Core Database operations.
/// All methods accept an engine type string to route to the correct adapter.
public final class DatabasesBridge: @unchecked Sendable {

    public static let shared = DatabasesBridge()
    private init() {}

    // MARK: - Detection

    public func isInstalledCmd(engine: String) -> String {
        withCArgs { c in extract(DBIsInstalledCmd(c.str(engine))) }
    }

    public func getVersionCmd(engine: String) -> String {
        withCArgs { c in extract(DBGetVersionCmd(c.str(engine))) }
    }

    public func getInstallPathCmd(engine: String) -> String {
        withCArgs { c in extract(DBGetInstallPathCmd(c.str(engine))) }
    }

    public func detectAllCmd() -> String {
        extract(DBDetectAllCmd())
    }

    // MARK: - Service Control

    public func startCmd(engine: String) -> String { withCArgs { c in extract(DBStartCmd(c.str(engine))) } }
    public func stopCmd(engine: String) -> String { withCArgs { c in extract(DBStopCmd(c.str(engine))) } }
    public func restartCmd(engine: String) -> String { withCArgs { c in extract(DBRestartCmd(c.str(engine))) } }
    public func statusCmd(engine: String) -> String { withCArgs { c in extract(DBStatusCmd(c.str(engine))) } }
    public func uninstallCmd(engine: String) -> String { withCArgs { c in extract(DBUninstallCmd(c.str(engine))) } }
    public func installCmd(engine: String, version: String = "") -> String {
        withCArgs { c in extract(DBInstallCmd(c.str(engine), c.str(version))) }
    }
    public func enableOnBootCmd(engine: String) -> String { withCArgs { c in extract(DBEnableOnBootCmd(c.str(engine))) } }
    public func disableOnBootCmd(engine: String) -> String { withCArgs { c in extract(DBDisableOnBootCmd(c.str(engine))) } }

    /// Returns the service name and display name for an engine.
    public func serviceInfo(engine: String) -> (serviceName: String, displayName: String) {
        let cStr = withCArgs { c in DBServiceNameCmd(c.str(engine)) }
        defer { if let cStr { CoreFreeString(cStr) } }
        guard let cStr,
              let data = String(cString: cStr).data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = resp["data"] as? [String: Any] else { return ("", "") }
        return (inner["service_name"] as? String ?? "", inner["display_name"] as? String ?? "")
    }

    // MARK: - Database Lifecycle

    public func listDatabasesCmd(engine: String) -> String {
        withCArgs { c in extract(DBListDatabasesCmd(c.str(engine))) }
    }

    public func createDatabaseCmd(engine: String, name: String, charset: String = "", collation: String = "") -> String {
        withCArgs { c in extract(DBCreateDatabaseCmd(c.str(engine), c.str(name), c.str(charset), c.str(collation))) }
    }

    public func dropDatabaseCmd(engine: String, name: String) -> String {
        withCArgs { c in extract(DBDropDatabaseCmd(c.str(engine), c.str(name))) }
    }

    // MARK: - User Management

    public func listUsersCmd(engine: String) -> String {
        withCArgs { c in extract(DBListUsersCmd(c.str(engine))) }
    }

    public func createUserCmd(engine: String, username: String, password: String, host: String = "%") -> String {
        withCArgs { c in extract(DBCreateUserCmd(c.str(engine), c.str(username), c.str(password), c.str(host))) }
    }

    public func dropUserCmd(engine: String, username: String, host: String = "%") -> String {
        withCArgs { c in extract(DBDropUserCmd(c.str(engine), c.str(username), c.str(host))) }
    }

    public func grantPrivilegesCmd(engine: String, username: String, host: String, database: String, privileges: String = "") -> String {
        withCArgs { c in extract(DBGrantPrivilegesCmd(c.str(engine), c.str(username), c.str(host), c.str(database), c.str(privileges))) }
    }

    public func revokePrivilegesCmd(engine: String, username: String, host: String, database: String, privileges: String = "") -> String {
        withCArgs { c in extract(DBRevokePrivilegesCmd(c.str(engine), c.str(username), c.str(host), c.str(database), c.str(privileges))) }
    }

    // MARK: - Table Management

    public func listTablesCmd(engine: String, database: String) -> String {
        withCArgs { c in extract(DBListTablesCmd(c.str(engine), c.str(database))) }
    }

    public func describeTableCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBDescribeTableCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func getTableIndexesCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBGetTableIndexesCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func dropTableCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBDropTableCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func truncateTableCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBTruncateTableCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func optimizeTableCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBOptimizeTableCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func analyzeTableCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBAnalyzeTableCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func createTableCmd(engine: String, database: String, table: String, columnsJSON: String) -> String {
        withCArgs { c in extract(DBCreateTableCmd(c.str(engine), c.str(database), c.str(table), c.str(columnsJSON))) }
    }

    public func addColumnCmd(engine: String, database: String, table: String, name: String, type colType: String, length: String = "", nullable: Bool = true, primaryKey: Bool = false, autoIncrement: Bool = false, unique: Bool = false, defaultValue: String = "", afterColumn: String = "") -> String {
        withCArgs { c in extract(DBAddColumnCmd(c.str(engine), c.str(database), c.str(table), c.str(name), c.str(colType), c.str(length), nullable ? 1 : 0, primaryKey ? 1 : 0, autoIncrement ? 1 : 0, unique ? 1 : 0, c.str(defaultValue), c.str(afterColumn))) }
    }

    public func dropColumnCmd(engine: String, database: String, table: String, column: String) -> String {
        withCArgs { c in extract(DBDropColumnCmd(c.str(engine), c.str(database), c.str(table), c.str(column))) }
    }

    // MARK: - Row Management

    public func insertRowCmd(engine: String, database: String, table: String, valuesJSON: String) -> String {
        withCArgs { c in extract(DBInsertRowCmd(c.str(engine), c.str(database), c.str(table), c.str(valuesJSON))) }
    }

    public func updateRowCmd(engine: String, database: String, table: String, primaryKeyJSON: String, valuesJSON: String) -> String {
        withCArgs { c in extract(DBUpdateRowCmd(c.str(engine), c.str(database), c.str(table), c.str(primaryKeyJSON), c.str(valuesJSON))) }
    }

    public func deleteRowCmd(engine: String, database: String, table: String, primaryKeyJSON: String) -> String {
        withCArgs { c in extract(DBDeleteRowCmd(c.str(engine), c.str(database), c.str(table), c.str(primaryKeyJSON))) }
    }

    public func deleteRowsCmd(engine: String, database: String, table: String, primaryKeysJSON: String) -> String {
        withCArgs { c in extract(DBDeleteRowsCmd(c.str(engine), c.str(database), c.str(table), c.str(primaryKeysJSON))) }
    }

    public func searchRowsCmd(engine: String, database: String, table: String, search: String, page: Int = 1, pageSize: Int = 50, orderBy: String = "", ascending: Bool = true) -> String {
        withCArgs { c in extract(DBSearchRowsCmd(c.str(engine), c.str(database), c.str(table), c.str(search), Int32(page), Int32(pageSize), c.str(orderBy), ascending ? 1 : 0)) }
    }

    // MARK: - Query Execution

    public func executeQueryCmd(engine: String, database: String, query: String) -> String {
        withCArgs { c in extract(DBExecuteQueryCmd(c.str(engine), c.str(database), c.str(query))) }
    }

    public func browseRowsCmd(engine: String, database: String, table: String, page: Int, pageSize: Int, orderBy: String = "", ascending: Bool = true) -> String {
        withCArgs { c in extract(DBBrowseRowsCmd(c.str(engine), c.str(database), c.str(table), Int32(page), Int32(pageSize), c.str(orderBy), ascending ? 1 : 0)) }
    }

    // MARK: - Logs

    public func errorLogCmd(engine: String, lines: Int = 100) -> String {
        withCArgs { c in extract(DBErrorLogCmd(c.str(engine), Int32(lines))) }
    }

    public func slowQueryLogCmd(engine: String, lines: Int = 100) -> String {
        withCArgs { c in extract(DBSlowQueryLogCmd(c.str(engine), Int32(lines))) }
    }

    // MARK: - Metrics & Config

    public func metricsCmd(engine: String) -> String { withCArgs { c in extract(DBMetricsCmd(c.str(engine))) } }
    public func performanceStatsCmd(engine: String) -> String { withCArgs { c in extract(DBPerformanceStatsCmd(c.str(engine))) } }
    public func configPathCmd(engine: String) -> String { withCArgs { c in extract(DBConfigPathCmd(c.str(engine))) } }
    public func readConfigCmd(engine: String) -> String { withCArgs { c in extract(DBReadConfigCmd(c.str(engine))) } }

    public func writeConfigCmd(engine: String, content: String) -> String {
        withCArgs { c in extract(DBWriteConfigCmd(c.str(engine), c.str(content))) }
    }

    // MARK: - Backup

    public func createBackupCmd(engine: String, database: String) -> String {
        withCArgs { c in extract(DBCreateBackupCmd(c.str(engine), c.str(database))) }
    }

    public func listBackupsCmd(engine: String) -> String {
        withCArgs { c in extract(DBListBackupsCmd(c.str(engine))) }
    }

    public func restoreBackupCmd(engine: String, backupPath: String, database: String) -> String {
        withCArgs { c in extract(DBRestoreBackupCmd(c.str(engine), c.str(backupPath), c.str(database))) }
    }

    public func deleteBackupCmd(engine: String, backupPath: String) -> String {
        withCArgs { c in extract(DBDeleteBackupCmd(c.str(engine), c.str(backupPath))) }
    }

    public func importSQLCmd(engine: String, database: String, sqlContent: String) -> String {
        withCArgs { c in extract(DBImportSQLCmd(c.str(engine), c.str(database), c.str(sqlContent))) }
    }

    // MARK: - Query Analysis

    public func explainQueryCmd(engine: String, database: String, query: String) -> String {
        withCArgs { c in extract(DBExplainQueryCmd(c.str(engine), c.str(database), c.str(query))) }
    }

    public func showProcessListCmd(engine: String) -> String {
        withCArgs { c in extract(DBShowProcessListCmd(c.str(engine))) }
    }

    // MARK: - DDL Inspection

    public func showCreateTableCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBShowCreateTableCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func exportSchemaCmd(engine: String, database: String) -> String {
        withCArgs { c in extract(DBExportSchemaCmd(c.str(engine), c.str(database))) }
    }

    // MARK: - Index Management

    public func createIndexCmd(engine: String, database: String, table: String, indexName: String, columns: [String], unique: Bool = false) -> String {
        let csv = columns.joined(separator: ",")
        return withCArgs { c in extract(DBCreateIndexCmd(c.str(engine), c.str(database), c.str(table), c.str(indexName), c.str(csv), unique ? 1 : 0)) }
    }

    public func dropIndexCmd(engine: String, database: String, table: String, indexName: String) -> String {
        withCArgs { c in extract(DBDropIndexCmd(c.str(engine), c.str(database), c.str(table), c.str(indexName))) }
    }

    // MARK: - Column Operations

    public func modifyColumnCmd(engine: String, database: String, table: String, name: String, type colType: String, length: String = "", nullable: Bool = true, defaultValue: String = "") -> String {
        withCArgs { c in extract(DBModifyColumnCmd(c.str(engine), c.str(database), c.str(table), c.str(name), c.str(colType), c.str(length), nullable ? 1 : 0, c.str(defaultValue))) }
    }

    // MARK: - Table Operations

    public func renameTableCmd(engine: String, database: String, oldName: String, newName: String) -> String {
        withCArgs { c in extract(DBRenameTableCmd(c.str(engine), c.str(database), c.str(oldName), c.str(newName))) }
    }

    // MARK: - Statistics & Metadata

    public func tableStatsCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBTableStatsCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    public func columnStatsCmd(engine: String, database: String, table: String, column: String) -> String {
        withCArgs { c in extract(DBColumnStatsCmd(c.str(engine), c.str(database), c.str(table), c.str(column))) }
    }

    public func foreignKeysCmd(engine: String, database: String, table: String) -> String {
        withCArgs { c in extract(DBForeignKeysCmd(c.str(engine), c.str(database), c.str(table))) }
    }

    // MARK: - Row Operations (Advanced)

    public func duplicateRowCmd(engine: String, database: String, table: String, primaryKeyJSON: String) -> String {
        withCArgs { c in extract(DBDuplicateRowCmd(c.str(engine), c.str(database), c.str(table), c.str(primaryKeyJSON))) }
    }

    // MARK: - Backup (Advanced)

    public func downloadBackupCmd(engine: String, backupPath: String) -> String {
        withCArgs { c in extract(DBDownloadBackupCmd(c.str(engine), c.str(backupPath))) }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let value = innerData["command"] as? String else { return "" }
        return value
    }
}
