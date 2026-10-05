//
//  WebsitesBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Websites operations.
//  Covers all 80+ Go bridge exports across 3 export files.
//

import Foundation
import AevonXCoreLib

// MARK: - Websites Bridge

/// Bridge to Go Core Websites operations.
/// Provides async, type-safe Swift APIs over the C bridge.
public final class WebsitesBridge: @unchecked Sendable {

    public static let shared = WebsitesBridge()
    private init() {}

    // ─── Engine Detection ────────────────────────────────────────────

    /// Get the command to detect web server engine.
    public func detectEngineCmd() -> String {
        let result = WebsitesDetectEngineCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Parse engine type from output.
    public func parseEngineType(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseEngineType(c.str(output))
            defer { CoreFreeString(result) }
            return extractString(result, key: "engine") ?? "nginx"
        }
    }

    // ─── Engine-Aware Sites CRUD ────────────────────────────────────

    /// Get command to list sites for the given engine type ("nginx", "apache", or "both").
    public func listAllSitesCmd(engine: String) -> String {
        withCArgs { c in
            let result = WebsitesListAllSitesCmd(c.str(engine))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get commands to create a site on the specified engine.
    public func createSiteCmd(engine: String, serverID: String, configJSON: String) -> [String] {
        withCArgs { c in
            let result = WebsitesCreateSiteCmd(c.str(engine), c.str(serverID), c.str(configJSON))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get commands to delete a site on the specified engine.
    public func deleteSiteCmd(engine: String, serverID: String, domain: String, pathsJSON: String) -> [String] {
        withCArgs { c in
            let result = WebsitesDeleteSiteCmd(c.str(engine), c.str(serverID), c.str(domain), c.str(pathsJSON))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get the command to enable a site on the specified engine.
    public func enableSiteCmd(engine: String, serverID: String, domain: String, pathsJSON: String) -> String {
        withCArgs { c in
            let result = WebsitesEnableSiteCmd(c.str(engine), c.str(serverID), c.str(domain), c.str(pathsJSON))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to disable a site on the specified engine.
    public func disableSiteCmd(engine: String, serverID: String, domain: String, pathsJSON: String) -> String {
        withCArgs { c in
            let result = WebsitesDisableSiteCmd(c.str(engine), c.str(serverID), c.str(domain), c.str(pathsJSON))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the config test command for the specified engine.
    public func testConfigCmd(engine: String, serverID: String) -> String {
        withCArgs { c in
            let result = WebsitesTestConfigCmd(c.str(engine), c.str(serverID))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the reload command for the specified engine.
    public func reloadEngineCmd(engine: String, serverID: String) -> String {
        withCArgs { c in
            let result = WebsitesReloadEngineCmd(c.str(engine), c.str(serverID))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the config path command for the specified engine.
    public func getConfigPathCmd(engine: String, serverID: String, domain: String) -> String {
        withCArgs { c in
            let result = WebsitesGetConfigPathCmd(c.str(engine), c.str(serverID), c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Nginx Sites CRUD (Deprecated — use engine-aware methods above) ─

    /// Get the command to list nginx sites.
    public func nginxListCmd(serverID: String) -> String {
        withCArgs { c in
            let result = WebsitesNginxListCmd(c.str(serverID))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse nginx sites output into JSON.
    public func parseNginxSites(output: String) -> String {
        withCArgs { c in
            let result = WebsitesNginxParseSites(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get commands to create a nginx site.
    public func createSiteCmd(serverID: String, configJSON: String) -> [String] {
        withCArgs { c in
            let result = WebsitesNginxCreateCmd(c.str(serverID), c.str(configJSON))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get commands to delete a nginx site.
    public func deleteSiteCmd(serverID: String, domain: String, sitesAvailable: String = "/etc/nginx/sites-available", sitesEnabled: String = "/etc/nginx/sites-enabled") -> [String] {
        withCArgs { c in
            let result = WebsitesNginxDeleteCmd(c.str(serverID), c.str(domain), c.str(sitesAvailable), c.str(sitesEnabled))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get the command to enable a site.
    public func enableSiteCmd(serverID: String, domain: String, sitesAvailable: String = "/etc/nginx/sites-available", sitesEnabled: String = "/etc/nginx/sites-enabled") -> String {
        withCArgs { c in
            let result = WebsitesNginxEnableCmd(c.str(serverID), c.str(domain), c.str(sitesAvailable), c.str(sitesEnabled))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to disable a site.
    public func disableSiteCmd(serverID: String, domain: String, sitesEnabled: String = "/etc/nginx/sites-enabled") -> String {
        withCArgs { c in
            let result = WebsitesNginxDisableCmd(c.str(serverID), c.str(domain), c.str(sitesEnabled))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Aware SSL ─────────────────────────────────────────────

    /// Get SSL issue commands for the specified engine ("nginx" or "apache").
    public func issueSSLCmd(engine: String, domain: String) -> [String] {
        withCArgs { c in
            let result = WebsitesIssueSSLCmdRouted(c.str(engine), c.str(domain))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get SSL revoke commands for the specified engine.
    public func revokeSSLCmd(engine: String, domain: String) -> [String] {
        withCArgs { c in
            let result = WebsitesRevokeSSLCmdRouted(c.str(engine), c.str(domain))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get SSL renew command for the specified engine.
    public func renewSSLCmd(engine: String, domain: String) -> String {
        withCArgs { c in
            let result = WebsitesRenewSSLCmdRouted(c.str(engine), c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get force SSL command for the specified engine.
    public func enableForceSSLCmd(engine: String, configPath: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesEnableForceSSLCmdRouted(c.str(engine), c.str(configPath), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get disable force SSL command for the specified engine.
    public func disableForceSSLCmd(engine: String, configPath: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesDisableForceSSLCmdRouted(c.str(engine), c.str(configPath), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get HSTS configuration command for the specified engine.
    public func configureHSTSCmd(engine: String, configPath: String, maxAge: Int, includeSubdomains: Bool) -> String {
        withCArgs { c in
            let result = WebsitesConfigureHSTSCmdRouted(c.str(engine), c.str(configPath), Int32(maxAge), includeSubdomains ? 1 : 0)
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get commands to upload a custom SSL certificate for the specified engine.
    public func uploadCustomCertCmds(engine: String, domain: String, cert: String, key: String, chain: String?, configPath: String, docRoot: String = "") -> [String] {
        withCArgs { c in
            let result = WebsitesUploadCustomCertCmdsRouted(
                c.str(engine), c.str(domain), c.str(cert), c.str(key),
                c.str(chain ?? ""), c.str(configPath), c.str(docRoot)
            )
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // ─── Engine-Routed Config ───────────────────────────────────────

    /// Get command to read site config for the specified engine.
    public func readConfigCmdRouted(engine: String, configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesReadConfigCmdRouted(c.str(engine), c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get commands to save config with backup for the specified engine.
    public func saveConfigCmdsRouted(engine: String, configPath: String, content: String, domain: String, timestamp: String, backupDir: String) -> [String] {
        withCArgs { c in
            let result = WebsitesSaveConfigCmdsRouted(c.str(engine), c.str(configPath), c.str(content), c.str(domain), c.str(timestamp), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get config validation command for the specified engine.
    public func validateConfigCmdRouted(engine: String) -> String {
        withCArgs { c in
            let result = WebsitesValidateConfigCmdRouted(c.str(engine))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Security ─────────────────────────────────────

    /// Get security detection command for the specified engine.
    public func detectSecurityCmdRouted(engine: String, configPath: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesDetectSecurityCmdRouted(c.str(engine), c.str(configPath), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get hotlink toggle command for the specified engine.
    public func toggleHotlinkCmdRouted(engine: String, enable: Bool, domain: String, configPath: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesToggleHotlinkCmdRouted(c.str(engine), enable ? 1 : 0, c.str(domain), c.str(configPath), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get sensitive files block command for the specified engine.
    public func toggleSensitiveBlockCmdRouted(engine: String, enable: Bool, configPath: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesToggleSensitiveBlockCmdRouted(c.str(engine), enable ? 1 : 0, c.str(configPath), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Performance ──────────────────────────────────

    /// Get performance reading command for the specified engine.
    public func readPerfCmdRouted(engine: String, configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesReadPerfCmdRouted(c.str(engine), c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to apply a performance setting for the specified engine.
    public func applyPerfSettingCmdRouted(engine: String, configPath: String, directive: String, value: String) -> String {
        withCArgs { c in
            let result = WebsitesApplyPerfSettingCmdRouted(c.str(engine), c.str(configPath), c.str(directive), c.str(value))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Headers ──────────────────────────────────────

    /// Get header loading command for the specified engine.
    public func loadHeadersCmdRouted(engine: String, configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesLoadHeadersCmdRouted(c.str(engine), c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get recommended headers command for the specified engine.
    public func applyRecommendedHeadersCmdRouted(engine: String, configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesApplyRecommendedHeadersCmdRouted(c.str(engine), c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Cache ────────────────────────────────────────

    /// Get cache purge command for the specified engine.
    public func purgeAllCachesCmdRouted(engine: String, cacheDir: String) -> String {
        withCArgs { c in
            let result = WebsitesPurgeAllCachesCmdRouted(c.str(engine), c.str(cacheDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Rewrite Rules ────────────────────────────────

    /// Get rewrite rules listing command for the specified engine.
    public func listRewriteCmdRouted(engine: String, configPath: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesListRewriteCmdRouted(c.str(engine), c.str(configPath), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to add a rewrite rule for the specified engine.
    public func addRewriteCmdRouted(engine: String, configPath: String, docRoot: String, pattern: String, target: String, flags: String) -> String {
        withCArgs { c in
            let result = WebsitesAddRewriteCmdRouted(c.str(engine), c.str(configPath), c.str(docRoot), c.str(pattern), c.str(target), c.str(flags))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Logs ─────────────────────────────────────────

    /// Get access log discovery command for the specified engine.
    public func findAccessLogCmdRouted(engine: String, domain: String, sitesAvailable: String, logDir: String) -> String {
        withCArgs { c in
            let result = WebsitesFindAccessLogCmdRouted(c.str(engine), c.str(domain), c.str(sitesAvailable), c.str(logDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get error log discovery command for the specified engine.
    public func findErrorLogCmdRouted(engine: String, domain: String, sitesAvailable: String, logDir: String) -> String {
        withCArgs { c in
            let result = WebsitesFindErrorLogCmdRouted(c.str(engine), c.str(domain), c.str(sitesAvailable), c.str(logDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine-Routed Lifecycle ────────────────────────────────────

    /// Get start command for the specified engine.
    public func startEngineCmdRouted(engine: String) -> String {
        withCArgs { c in
            let result = WebsitesStartEngineCmdRouted(c.str(engine))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get stop command for the specified engine.
    public func stopEngineCmdRouted(engine: String) -> String {
        withCArgs { c in
            let result = WebsitesStopEngineCmdRouted(c.str(engine))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get restart command for the specified engine.
    public func restartEngineCmdRouted(engine: String) -> String {
        withCArgs { c in
            let result = WebsitesRestartEngineCmdRouted(c.str(engine))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Apache Modules ─────────────────────────────────────────────

    /// Get command to list Apache modules.
    public func listModulesCmd(engine: String) -> String {
        withCArgs { c in
            let result = WebsitesListModulesCmd(c.str(engine))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to enable an Apache module.
    public func enableModuleCmd(engine: String, module: String) -> String {
        withCArgs { c in
            let result = WebsitesEnableModuleCmd(c.str(engine), c.str(module))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to disable an Apache module.
    public func disableModuleCmd(engine: String, module: String) -> String {
        withCArgs { c in
            let result = WebsitesDisableModuleCmd(c.str(engine), c.str(module))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Engine Migration ─────────────────────────────────────────────

    /// Get migration commands to move a site from one engine to another.
    /// Returns full JSON with preflight_cmds, migration_cmds, rollback_cmds, cleanup_cmds.
    public func migrateSiteCmds(sourceEngine: String, targetEngine: String, domain: String, docRoot: String, pathsJSON: String) -> String {
        withCArgs { c in
            let result = WebsitesMigrateSiteCmds(
                c.str(sourceEngine), c.str(targetEngine),
                c.str(domain), c.str(docRoot), c.str(pathsJSON)
            )
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    // ─── SSL (Deprecated — use engine-aware methods above) ──────────

    /// Get SSL details command.
    public func sslDetailsCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesSSLDetailsCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse SSL details output into JSON.
    public func parseSSLDetails(domain: String, output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseSSLDetails(c.str(domain), c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get SSL issue commands.
    public func issueSSLCmd(domain: String) -> [String] {
        withCArgs { c in
            let result = WebsitesIssueSSLCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get SSL revoke commands.
    public func revokeSSLCmd(domain: String) -> [String] {
        withCArgs { c in
            let result = WebsitesRevokeSSLCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get SSL renew command.
    public func renewSSLCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesRenewSSLCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Lifecycle ───────────────────────────────────────────────────

    /// Get nginx start command.
    public func startNginxCmd() -> String {
        let result = WebsitesStartNginxCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get nginx stop command.
    public func stopNginxCmd() -> String {
        let result = WebsitesStopNginxCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get nginx reload command.
    public func reloadNginxCmd() -> String {
        let result = WebsitesReloadNginxCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to get disk usage of a directory.
    public func getDiskUsageCmd(docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesGetDiskUsageCmd(c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get nginx restart command.
    public func restartNginxCmd() -> String {
        let result = WebsitesRestartNginxCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // ─── List ────────────────────────────────────────────────────────

    /// Get command to list sites with details (disk usage, SSL, etc.).
    public func listWithDetailsCmd() -> String {
        let result = WebsitesListWithDetailsCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Parse detailed site list output into JSON.
    public func parseListWithDetails(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseListWithDetails(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    // ─── Logs ────────────────────────────────────────────────────────

    /// Get command to read access log.
    public func readAccessLogCmd(logPath: String, lines: Int) -> String {
        withCArgs { c in
            let result = WebsitesReadAccessLogCmd(c.str(logPath), Int32(lines))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to find access log path for a domain.
    public func findAccessLogCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesFindAccessLogCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }


    // ─── Analytics ───────────────────────────────────────────────────

    /// Get bandwidth analysis command.
    public func bandwidthCmd(logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesBandwidthCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get request count command.
    public func requestCountCmd(logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesRequestCountCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get top pages command.
    public func topPagesCmd(logPath: String, limit: Int) -> String {
        withCArgs { c in
            let result = WebsitesTopPagesCmd(c.str(logPath), Int32(limit))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get error rate command.
    public func errorRateCmd(logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesErrorRateCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Rewrite Rules ───────────────────────────────────────────────

    /// Get command to list rewrite rules.
    public func listRewriteCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesListRewriteCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse rewrite rules output into JSON.
    public func parseRewriteRules(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseRewriteRules(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get command to add a rewrite rule.
    public func addRewriteCmd(configPath: String, pattern: String, target: String, ruleType: String) -> String {
        withCArgs { c in
            let result = WebsitesAddRewriteCmd(c.str(configPath), c.str(pattern), c.str(target), c.str(ruleType))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Backup ──────────────────────────────────────────────────────

    /// Get backup commands.
    public func backupSiteCmds(domain: String, docRoot: String, backupDir: String = "") -> [String] {
        withCArgs { c in
            let result = WebsitesBackupSiteCmds(c.str(domain), c.str(docRoot), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get list backups command.
    public func listBackupsCmd(domain: String, backupDir: String = "") -> String {
        withCArgs { c in
            let result = WebsitesListBackupsCmd(c.str(domain), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse backup listing output into JSON.
    public func parseBackups(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseBackups(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get restore backup command.
    public func restoreBackupCmd(domain: String, backupFile: String, docRoot: String, backupDir: String = "") -> String {
        withCArgs { c in
            let result = WebsitesRestoreBackupCmd(c.str(domain), c.str(backupFile), c.str(docRoot), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Domain ──────────────────────────────────────────────────────

    /// Get DNS check command.
    public func checkDNSCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesCheckDNSCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse DNS check output into JSON.
    public func parseDNS(domain: String, output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseDNS(c.str(domain), c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get list subdomains command.
    public func listSubdomainsCmd(domain: String, sitesEnabled: String) -> String {
        withCArgs { c in
            let result = WebsitesListSubdomainsCmd(c.str(domain), c.str(sitesEnabled))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get add redirect command.
    public func addRedirectCmd(configPath: String, from: String, to: String) -> String {
        withCArgs { c in
            let result = WebsitesAddRedirectCmd(c.str(configPath), c.str(from), c.str(to))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Cloning ─────────────────────────────────────────────────────

    /// Get clone site commands.
    public func cloneSiteCmds(source: String, target: String, docRoot: String, sitesAvailable: String, sitesEnabled: String, webOwnership: String = "") -> [String] {
        withCArgs { c in
            let result = WebsitesCloneSiteCmds(c.str(source), c.str(target), c.str(docRoot), c.str(sitesAvailable), c.str(sitesEnabled), c.str(webOwnership))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // ─── Headers ─────────────────────────────────────────────────────

    /// Get command to load HTTP headers from config.
    public func loadHeadersCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesLoadHeadersCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse header directives output into JSON.
    public func parseHeaders(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseHeaders(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get command to audit security headers.
    public func auditHeadersCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesAuditHeadersCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse header audit output into JSON.
    public func parseHeaderAudit(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseHeaderAudit(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get command to apply recommended security headers.
    public func applyRecommendedHeadersCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesApplyRecommendedHeadersCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Monitoring ──────────────────────────────────────────────────

    /// Get health check command.
    public func healthCheckCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesHealthCheckCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get response time command.
    public func responseTimeCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesResponseTimeCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get find large files command.
    public func findLargeFilesCmd(docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesFindLargeFilesCmd(c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get bot traffic analysis command.
    public func botTrafficCmd(logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesBotTrafficCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Security ────────────────────────────────────────────────────

    /// Get command to detect security status from config.
    public func detectSecurityCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesDetectSecurityCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse security status from config content.
    public func parseSecurityStatus(content: String) -> String {
        withCArgs { c in
            let result = WebsitesParseSecurityStatus(c.str(content))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get hotlink protection toggle command.
    public func toggleHotlinkCmd(enable: Bool, domain: String, configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesToggleHotlinkCmd(enable ? 1 : 0, c.str(domain), c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get malware scan command.
    public func malwareScanCmd(docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesRunMalwareScanCmd(c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse malware scan output into JSON.
    public func parseMalwareScan(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParseMalwareScan(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get fix permissions command.
    public func fixPermissionsCmd(docRoot: String, webOwnership: String = "") -> String {
        withCArgs { c in
            let result = WebsitesFixPermissionsCmd(c.str(docRoot), c.str(webOwnership))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Performance ─────────────────────────────────────────────────

    /// Get command to read performance settings.
    public func readPerfCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesReadPerfCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Parse performance settings from config content.
    public func parsePerfSettings(content: String) -> String {
        withCArgs { c in
            let result = WebsitesParsePerfSettings(c.str(content))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    /// Get command to apply a single performance setting.
    public func applyPerfSettingCmd(configPath: String, directive: String, value: String) -> String {
        withCArgs { c in
            let result = WebsitesApplyPerfSettingCmd(c.str(configPath), c.str(directive), c.str(value))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get commands to apply a performance preset.
    public func applyPresetCmds(configPath: String, preset: String) -> [String] {
        withCArgs { c in
            let result = WebsitesApplyPerfPresetCmds(c.str(configPath), c.str(preset))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // ─── Cache ───────────────────────────────────────────────────────

    /// Get purge all caches command.
    public func purgeAllCachesCmd(cacheDir: String = "") -> String {
        withCArgs { c in
            let result = WebsitesPurgeAllCachesCmd(c.str(cacheDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get purge FastCGI cache command.
    public func purgeFastCGICmd(cacheDir: String = "") -> String {
        withCArgs { c in
            let result = WebsitesPurgeFastCGICmd(c.str(cacheDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Nginx Config ────────────────────────────────────────────────

    /// Get command to load nginx config file.
    public func loadNginxConfigCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesLoadNginxConfigCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Generate a template nginx config.
    public func generateTemplateConfig(template: String, domain: String, docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesGenerateTemplateConfig(c.str(template), c.str(domain), c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "config") ?? ""
        }
    }

    // ─── Quick Actions ───────────────────────────────────────────────

    /// Get restart PHP-FPM command.
    public func restartPHPCmd(version: String) -> String {
        withCArgs { c in
            let result = WebsitesRestartPHPCmd(c.str(version))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get clear app cache command.
    public func clearAppCacheCmd(docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesClearAppCacheCmd(c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get fix ownership command.
    public func fixOwnershipCmd(docRoot: String, webOwnership: String = "") -> String {
        withCArgs { c in
            let result = WebsitesFixOwnershipCmd(c.str(docRoot), c.str(webOwnership))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Scheduled Backups ───────────────────────────────────────────

    /// Get command to list scheduled backups.
    public func listScheduledCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesListScheduledCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to create a scheduled backup.
    public func createScheduledCmd(domain: String, docRoot: String, frequency: String, retention: Int, includeDB: Bool, backupDir: String = "") -> String {
        withCArgs { c in
            let result = WebsitesCreateScheduledCmd(c.str(domain), c.str(docRoot), c.str(frequency), c.str(backupDir), Int32(retention), includeDB ? 1 : 0)
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to delete a scheduled backup.
    public func deleteScheduledCmd(domain: String, frequency: String) -> String {
        withCArgs { c in
            let result = WebsitesDeleteScheduledCmd(c.str(domain), c.str(frequency))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get command to run backup now.
    public func runBackupNowCmd(domain: String, docRoot: String, timestamp: String, backupDir: String = "") -> String {
        withCArgs { c in
            let result = WebsitesRunBackupNowCmd(c.str(domain), c.str(docRoot), c.str(timestamp), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Deployment ──────────────────────────────────────────────────

    /// Get git deploy commands.
    public func gitDeployCmds(repo: String, branch: String, docRoot: String, webOwnership: String = "") -> [String] {
        withCArgs { c in
            let result = WebsitesGitDeployCmds(c.str(repo), c.str(branch), c.str(docRoot), c.str(webOwnership))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // ─── Domain Operations (Go Core Wrappers) ──────────────────────

    // MARK: - Aliases

    public func listAliasesCmd(domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesListAliasesCmd(c.str("\(sitesAvailable)/\(domain)"), c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func parseAliases(output: String) -> String {
        let aliases = output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let data = try? JSONSerialization.data(withJSONObject: ["success": true, "data": aliases])
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{\"success\":true,\"data\":[]}"
    }

    public func addAliasCmd(alias: String, domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesAddAliasCmd(c.str("\(sitesAvailable)/\(domain)"), c.str(alias))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func removeAliasCmd(alias: String, domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesRemoveAliasCmd(c.str("\(sitesAvailable)/\(domain)"), c.str(alias))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // MARK: - Subdomains

    public func createSubdomainCmds(subdomain: String, domain: String, docRoot: String, sitesAvailable: String, sitesEnabled: String, webOwnership: String) -> [String] {
        withCArgs { c in
            let result = WebsitesCreateSubdomainCmds(
                c.str(subdomain), c.str(domain), c.str(docRoot),
                c.str(sitesAvailable), c.str(sitesEnabled), c.str(webOwnership)
            )
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // MARK: - DNS & Redirects

    public func dnsLookupCmd(domain: String) -> String {
        checkDNSCmd(domain: domain)
    }

    public func parseDNSRecords(domain: String, output: String) -> String {
        parseDNS(domain: domain, output: output)
    }

    public func setWWWRedirectCmd(domain: String, confD: String = "/etc/nginx/conf.d", toWWW: Bool) -> String {
        withCArgs { c in
            let result = WebsitesSetWWWRedirectCmd(toWWW ? 1 : 0, c.str(domain), c.str("\(confD)/\(domain)-www-redirect.conf"))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // MARK: - SSL Management

    public func sslStatusCmd(domain: String) -> String {
        sslDetailsCmd(domain: domain)
    }

    public func parseSSLStatus(domain: String, output: String) -> String {
        parseSSLDetails(domain: domain, output: output)
    }

    public func enableForceSSLCmd(domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesEnableForceSSLCmd(c.str("\(sitesAvailable)/\(domain)"))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func disableForceSSLCmd(domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesDisableForceSSLCmd(c.str("\(sitesAvailable)/\(domain)"))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func configureHSTSCmd(domain: String, maxAge: Int, includeSubdomains: Bool, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesConfigureHSTSCmd(c.str("\(sitesAvailable)/\(domain)"), Int32(maxAge), includeSubdomains ? 1 : 0)
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func uploadCustomCertCmds(domain: String, cert: String, key: String, chain: String?, sitesAvailable: String = "/etc/nginx/sites-available", docRoot: String = "") -> [String] {
        withCArgs { c in
            let result = WebsitesUploadCustomCertCmds(
                c.str(domain), c.str(cert), c.str(key),
                c.str(chain ?? ""), c.str("\(sitesAvailable)/\(domain)"), c.str(docRoot)
            )
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // MARK: - Security

    public func securityScanCmd(domain: String, docRoot: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        detectSecurityCmd(configPath: "\(sitesAvailable)/\(domain)")
    }

    public func parseSecurityScan(output: String) -> String {
        parseSecurityStatus(content: output)
    }

    public func toggleSensitiveBlockCmd(enable: Bool, domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesToggleSensitiveBlockCmd(enable ? 1 : 0, c.str("\(sitesAvailable)/\(domain)"))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func permissionAuditCmd(docRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesRunPermissionAuditCmd(c.str(docRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func parsePermissionAudit(output: String) -> String {
        withCArgs { c in
            let result = WebsitesParsePermissionAudit(c.str(output))
            defer { CoreFreeString(result) }
            return cStringToSwift(result)
        }
    }

    // MARK: - Monitoring & Traffic

    public func analyzeTrafficCmd(domain: String, logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesAnalyzeTrafficCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func parseTrafficAnalysis(output: String) -> String { output }
    public func parseHealthCheck(output: String) -> String { output }

    // MARK: - Analytics

    public func requestStatsCmd(domain: String, timeRange: String, logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesRequestStatsCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func parseRequestStats(output: String) -> String { output }

    public func parseBandwidth(output: String) -> String { output }

    public func topEndpointsCmd(domain: String, limit: Int, logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesTopPagesCmd(c.str(logPath), Int32(limit))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func parseTopEndpoints(output: String) -> String { output }

    // MARK: - Log Discovery

    public func discoverLogFilesCmd(domain: String, configPath: String = "") -> String {
        withCArgs { c in
            let result = WebsitesDiscoverLogFilesCmd(c.str(domain), c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func parseLogFiles(output: String) -> String {
        // Go DiscoverLogFilesCmd outputs: "access_log /path/to/file" or "error_log /path/to/file"
        let lines = output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var files: [[String: String]] = []
        var seen = Set<String>()
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").filter { !$0.isEmpty }
            guard parts.count >= 2 else { continue }
            let path = parts[1]
            guard !seen.contains(path) else { continue }
            seen.insert(path)
            let logType = parts[0].lowercased().contains("error") ? "error" : "access"
            let filename = (path as NSString).lastPathComponent
            files.append([
                "path": path,
                "type": logType,
                "size": "",
                "filename": filename
            ])
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: ["success": true, "data": files]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{\"success\":true,\"data\":[]}"
    }

    // MARK: - Backup Parsing

    public func parseBackupList(output: String) -> String {
        parseBackups(output: output)
    }

    public func deleteBackupCmd(filename: String, domain: String = "", backupDir: String = "/var/backups/aevonx") -> String {
        withCArgs { c in
            let result = WebsitesDeleteBackupFileCmd(c.str(domain), c.str(filename), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // MARK: - Rewrite Rules (convenience wrappers)

    public func getRewriteRulesCmd(domain: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        listRewriteCmd(configPath: "\(sitesAvailable)/\(domain)")
    }

    public func addRewriteRuleCmd(domain: String, source: String, destination: String, flags: String, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        addRewriteCmd(configPath: "\(sitesAvailable)/\(domain)", pattern: source, target: destination, ruleType: flags.isEmpty ? "301" : flags)
    }

    public func deleteRewriteRuleCmd(domain: String, ruleIndex: Int, sitesAvailable: String = "/etc/nginx/sites-available") -> String {
        withCArgs { c in
            let result = WebsitesDeleteRewriteCmd(c.str("\(sitesAvailable)/\(domain)"), c.str("\(ruleIndex + 1)"))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    public func testRewriteCmd(domain: String, testURL: String) -> String {
        let safeURL = testURL.replacingOccurrences(of: "'", with: "'\\''")
        return "CODE=$(curl -sI -o /dev/null -w '%{http_code}|%{redirect_url}' --max-time 10 '\(safeURL)' 2>/dev/null); HTTP=$(echo \"$CODE\" | cut -d'|' -f1); RURL=$(echo \"$CODE\" | cut -d'|' -f2-); if [ -n \"$RURL\" ]; then echo '{\"success\":true,\"data\":{\"was_rewritten\":true,\"result_url\":\"'\"$RURL\"'\"}}'; else echo '{\"success\":true,\"data\":{\"was_rewritten\":false,\"result_url\":\"\"}}'; fi"
    }

    public func parseTestRewrite(output: String) -> String { output }

    // MARK: - Maintenance Mode

    public func enableMaintenanceCmd(domain: String, docRoot: String, sitesAvailable: String = "/etc/nginx/sites-available") -> [String] {
        withCArgs { c in
            let result = WebsitesEnableMaintenanceCmds(c.str(domain), c.str(docRoot), c.str(sitesAvailable))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    public func disableMaintenanceCmd(domain: String, docRoot: String, sitesAvailable: String = "/etc/nginx/sites-available") -> [String] {
        withCArgs { c in
            let result = WebsitesDisableMaintenanceCmds(c.str(domain), c.str(docRoot), c.str(sitesAvailable))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    // MARK: - Scheduled Backups (convenience wrappers)

    public func listScheduledBackupsCmd(domain: String) -> String {
        listScheduledCmd(domain: domain)
    }

    public func parseScheduledBackups(output: String) -> String {
        // Go ListScheduledBackupsCmd outputs cron lines like:
        // 0 3 * * * ... # aevonx_backup_domain_daily
        let lines = output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var items: [[String: Any]] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") { continue }
            let parts = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
            guard parts.count >= 6 else { continue }
            let cronExpr = parts[0...4].joined(separator: " ")
            let frequency: String
            switch cronExpr {
            case "0 3 * * *": frequency = "daily"
            case "0 3 * * 0": frequency = "weekly"
            case "0 3 1 * *": frequency = "monthly"
            default: frequency = "custom"
            }
            let includesDB = trimmed.contains("mysqldump")
            items.append([
                "frequency": frequency,
                "cron_expression": cronExpr,
                "includes_database": includesDB,
                "display_text": frequency.capitalized + " Backup"
            ] as [String: Any])
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: ["success": true, "data": items]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{\"success\":true,\"data\":[]}"
    }

    public func createScheduledBackupCmd(domain: String, docRoot: String, frequency: String, retentionDays: Int, includeDB: Bool) -> String {
        createScheduledCmd(domain: domain, docRoot: docRoot, frequency: frequency, retention: retentionDays, includeDB: includeDB)
    }

    public func deleteScheduledBackupCmd(domain: String, frequency: String) -> String {
        deleteScheduledCmd(domain: domain, frequency: frequency)
    }

    private func applySetting(configPath: String, directive: String, value: String) -> String {
        applyPerfSettingCmd(configPath: configPath, directive: directive, value: value)
    }

    private func applyPresetCmds(preset: String, configPath: String) -> [String] {
        switch preset {
        case "performance":
            return [
                applySetting(configPath: configPath, directive: "gzip", value: "on"),
                applySetting(configPath: configPath, directive: "keepalive_timeout", value: "65"),
                applySetting(configPath: configPath, directive: "client_max_body_size", value: "100m"),
            ]
        case "security":
            return [
                applySetting(configPath: configPath, directive: "client_max_body_size", value: "10m"),
                applySetting(configPath: configPath, directive: "keepalive_timeout", value: "30"),
            ]
        default: // balanced
            return [
                applySetting(configPath: configPath, directive: "gzip", value: "on"),
                applySetting(configPath: configPath, directive: "keepalive_timeout", value: "45"),
                applySetting(configPath: configPath, directive: "client_max_body_size", value: "50m"),
            ]
        }
    }

    // ─── SSL Helpers ──────────────────────────────────────────────────

    /// Get the command to check if force SSL redirect is enabled in nginx config.
    public func checkForceSSLCmd(configPath: String) -> String {
        withCArgs { c in
            let result = WebsitesCheckForceSSLCmd(c.str(configPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to check if force SSL redirect is enabled for a domain.
    /// Searches ALL nginx configs for the domain, not just one file.
    public func checkForceSSLDomainCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesCheckForceSSLDomainCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to read the SSL certificate file.
    public func readCertificateCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesReadCertificateCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to read the SSL private key file.
    public func readPrivateKeyCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesReadPrivateKeyCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to discover which nginx config file has SSL directives for a domain.
    public func findSSLConfigCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesFindSSLConfigCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to verify the uploaded cert is actually served on port 443.
    public func verifyCertActiveCmd(domain: String) -> String {
        withCArgs { c in
            let result = WebsitesVerifyCertActiveCmd(c.str(domain))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Nginx Config Validation ────────────────────────────────────

    /// Get the command to test nginx config (sudo nginx -t).
    public func validateNginxCmd() -> String {
        let result = WebsitesValidateNginxCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // ─── Site Config Editing ─────────────────────────────────────────

    /// Get the command to switch PHP version in nginx config.
    public func switchPHPVersionCmd(configPath: String, oldVersion: String, newVersion: String) -> String {
        withCArgs { c in
            let result = WebsitesSwitchPHPVersionCmd(c.str(configPath), c.str(oldVersion), c.str(newVersion))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to update the document root in nginx config.
    public func updateDocRootCmd(configPath: String, oldRoot: String, newRoot: String) -> String {
        withCArgs { c in
            let result = WebsitesUpdateDocRootCmd(c.str(configPath), c.str(oldRoot), c.str(newRoot))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to update the listen port in nginx config.
    public func updatePortCmd(configPath: String, port: Int) -> String {
        withCArgs { c in
            let result = WebsitesUpdatePortCmd(c.str(configPath), Int32(port))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Site Monitoring ─────────────────────────────────────────────

    /// Get the command to count active HTTP/HTTPS connections.
    public func activeConnectionsCmd() -> String {
        let result = WebsitesActiveConnectionsCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // ─── PHP Detection ───────────────────────────────────────────────

    /// Get the command to list installed PHP versions.
    public func installedPHPVersionsCmd(phpConfDir: String = "/etc/php") -> String {
        withCArgs { c in
            let result = WebsitesInstalledPHPVersionsCmd(c.str(phpConfDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Directory Browsing ──────────────────────────────────────────

    /// Get the command to list subdirectories of a path.
    public func listDirectoriesCmd(path: String) -> String {
        withCArgs { c in
            let result = WebsitesListDirectoriesCmd(c.str(path))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Quick Actions (Phase 3) ────────────────────────────────────

    /// Get the command to restart all PHP-FPM instances (systemd + BT Panel fallback).
    public func restartAllPHPCmd() -> String {
        let result = WebsitesRestartAllPHPCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to restart all PM2 processes.
    public func restartPM2AllCmd() -> String {
        let result = WebsitesRestartPM2AllCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to detect installed runtimes (php, node, python).
    public func detectRuntimesCmd() -> String {
        let result = WebsitesDetectRuntimesCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to detect Node.js version.
    public func getNodeVersionCmd() -> String {
        let result = WebsitesGetNodeVersionCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to detect Python version.
    public func getPythonVersionCmd() -> String {
        let result = WebsitesGetPythonVersionCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to create a directory.
    public func createDirectoryCmd(path: String) -> String {
        withCArgs { c in
            let result = WebsitesCreateDirectoryCmd(c.str(path))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to clear/truncate a site log file.
    public func clearSiteLogCmd(logPath: String) -> String {
        withCArgs { c in
            let result = WebsitesClearSiteLogCmd(c.str(logPath))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get commands to export a site for migration.
    public func exportMigrationCmds(domain: String, docRoot: String, sitesAvailable: String, timestamp: String) -> [String] {
        withCArgs { c in
            let result = WebsitesExportMigrationCmds(c.str(domain), c.str(docRoot), c.str(sitesAvailable), c.str(timestamp))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get the command to check FastCGI cache status.
    public func fastCGICacheStatusCmd() -> String {
        let result = WebsitesFastCGICacheStatusCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    /// Get the command to read nginx worker info (cpu cores, worker_processes, worker_connections).
    public func readWorkerInfoCmd(nginxMainConf: String) -> String {
        withCArgs { c in
            let result = WebsitesReadWorkerInfoCmd(c.str(nginxMainConf))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get commands to save nginx config with auto-backup.
    public func saveConfigCmds(configPath: String, content: String, domain: String, timestamp: String, backupDir: String) -> [String] {
        withCArgs { c in
            let result = WebsitesSaveConfigCmds(c.str(configPath), c.str(content), c.str(domain), c.str(timestamp), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractStringArray(result, key: "commands")
        }
    }

    /// Get the command to list config backups.
    public func listConfigBackupsCmd(domain: String, backupDir: String) -> String {
        withCArgs { c in
            let result = WebsitesListConfigBackupsCmd(c.str(domain), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    /// Get the command to restore a config backup.
    public func restoreConfigBackupCmd(configPath: String, backupFilename: String, backupDir: String) -> String {
        withCArgs { c in
            let result = WebsitesRestoreConfigBackupCmd(c.str(configPath), c.str(backupFilename), c.str(backupDir))
            defer { CoreFreeString(result) }
            return extractString(result, key: "command") ?? ""
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────

    private func cStringToSwift(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "{}" }
        return String(cString: cStr)
    }

    private func extractString(_ cStr: UnsafeMutablePointer<CChar>?, key: String) -> String? {
        guard let cStr = cStr else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let value = innerData[key] as? String else { return nil }
        return value
    }

    private func extractStringArray(_ cStr: UnsafeMutablePointer<CChar>?, key: String) -> [String] {
        guard let cStr = cStr else { return [] }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let array = innerData[key] as? [String] else { return [] }
        return array
    }
}

