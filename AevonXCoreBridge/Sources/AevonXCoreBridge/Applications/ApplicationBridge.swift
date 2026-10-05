//
//  ApplicationBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Application management operations.
//  All methods execute SSH internally via Go Core and return ready-to-display data.
//  Every method dispatches to a background queue to avoid blocking the main thread.
//

import Foundation
import AevonXCoreLib

public final class ApplicationBridge: @unchecked Sendable {

    public static let shared = ApplicationBridge()
    private let queue = DispatchQueue(label: "app.aevonx.bridge.applications", qos: .userInitiated, attributes: .concurrent)
    private init() {}

    // MARK: - Discovery

    public func discoverApps(serverID: String) async -> String {
        await run({ withCArgs { c in AppDiscoverApps(c.str(serverID)) } }, "discoverApps")
    }

    public func listAdapters() async -> String {
        await run { AppListAdapters() }
    }

    /// Invalidates the discovery cache for a server, forcing fresh SSH probe on next discoverApps call.
    public func invalidateDiscoveryCache(serverID: String) {
        withCArgs { c in AppInvalidateDiscoveryCache(c.str(serverID)) }
    }

    // MARK: - Lifecycle

    public func getStatus(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetStatus(c.str(serverID), c.str(appID)) } }, "getStatus")
    }

    public func start(serverID: String, appID: String) async -> String {
        await run { withCArgs { c in AppStart(c.str(serverID), c.str(appID)) } }
    }

    public func stop(serverID: String, appID: String) async -> String {
        await run { withCArgs { c in AppStop(c.str(serverID), c.str(appID)) } }
    }

    public func restart(serverID: String, appID: String) async -> String {
        await run { withCArgs { c in AppRestart(c.str(serverID), c.str(appID)) } }
    }

    public func reload(serverID: String, appID: String) async -> String {
        await run { withCArgs { c in AppReload(c.str(serverID), c.str(appID)) } }
    }

    // MARK: - Configuration

    public func getConfigs(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetConfigs(c.str(serverID), c.str(appID)) } }, "getConfigs")
    }

    public func readConfig(serverID: String, path: String) async -> String {
        await run { withCArgs { c in AppReadConfig(c.str(serverID), c.str(path)) } }
    }

    public func saveConfig(serverID: String, path: String, content: String) async -> String {
        await run { withCArgs { c in AppSaveConfig(c.str(serverID), c.str(path), c.str(content)) } }
    }

    public func configTest(serverID: String, appID: String) async -> String {
        await run { withCArgs { c in AppConfigTest(c.str(serverID), c.str(appID)) } }
    }

    // MARK: - Logs

    public func getLogs(serverID: String, appID: String, logType: String, lines: Int32) async -> String {
        await run { withCArgs { c in AppGetLogs(c.str(serverID), c.str(appID), c.str(logType), lines) } }
    }

    // MARK: - Versions

    public func getVersions(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetVersions(c.str(serverID), c.str(appID)) } }, "getVersions")
    }

    public func getAvailableVersions(appID: String) async -> String {
        await run({ withCArgs { c in AppGetAvailableVersions(c.str(appID)) } }, "getAvailableVersions")
    }

    public func installVersion(serverID: String, appID: String, version: String) async -> String {
        await run({ withCArgs { c in AppInstallVersion(c.str(serverID), c.str(appID), c.str(version)) } }, "installVersion")
    }

    public func switchVersion(serverID: String, appID: String, version: String) async -> String {
        await run({ withCArgs { c in AppSwitchVersion(c.str(serverID), c.str(appID), c.str(version)) } }, "switchVersion")
    }

    public func uninstallVersion(serverID: String, appID: String, version: String) async -> String {
        await run({ withCArgs { c in AppUninstallVersion(c.str(serverID), c.str(appID), c.str(version)) } }, "uninstallVersion")
    }

    // MARK: - Workers

    public func getWorkers(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetWorkers(c.str(serverID), c.str(appID)) } }, "getWorkers")
    }

    // MARK: - Modules

    public func getModules(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetModules(c.str(serverID), c.str(appID)) } }, "getModules")
    }

    // MARK: - Optimization

    public func getOptimization(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetOptimization(c.str(serverID), c.str(appID)) } }, "getOptimization")
    }

    public func saveOptimization(serverID: String, appID: String, settingsJSON: String) async -> String {
        await run({ withCArgs { c in AppSaveOptimization(c.str(serverID), c.str(appID), c.str(settingsJSON)) } }, "saveOptimization")
    }

    // MARK: - Security

    public func getSecurity(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetSecurity(c.str(serverID), c.str(appID)) } }, "getSecurity")
    }

    public func saveSecurityHeaders(serverID: String, appID: String, headersJSON: String) async -> String {
        await run({ withCArgs { c in AppSaveSecurityHeaders(c.str(serverID), c.str(appID), c.str(headersJSON)) } }, "saveSecurityHeaders")
    }

    public func saveRateLimit(serverID: String, appID: String, settingsJSON: String) async -> String {
        await run({ withCArgs { c in AppSaveRateLimit(c.str(serverID), c.str(appID), c.str(settingsJSON)) } }, "saveRateLimit")
    }

    // MARK: - Doctor & Performance Score

    public func runDoctor(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppRunDoctor(c.str(serverID), c.str(appID)) } }, "runDoctor")
    }

    public func getPerformanceScore(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetPerformanceScore(c.str(serverID), c.str(appID)) } }, "getPerformanceScore")
    }

    // MARK: - Snapshots

    public func listSnapshots(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppListSnapshots(c.str(serverID), c.str(appID)) } }, "listSnapshots")
    }

    public func createSnapshot(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppCreateSnapshot(c.str(serverID), c.str(appID)) } }, "createSnapshot")
    }

    public func restoreSnapshot(serverID: String, appID: String, id: String) async -> String {
        await run({ withCArgs { c in AppRestoreSnapshot(c.str(serverID), c.str(appID), c.str(id)) } }, "restoreSnapshot")
    }

    public func deleteSnapshot(serverID: String, appID: String, id: String) async -> String {
        await run({ withCArgs { c in AppDeleteSnapshot(c.str(serverID), c.str(appID), c.str(id)) } }, "deleteSnapshot")
    }

    public func diffSnapshot(serverID: String, appID: String, id: String) async -> String {
        await run({ withCArgs { c in AppDiffSnapshot(c.str(serverID), c.str(appID), c.str(id)) } }, "diffSnapshot")
    }

    // MARK: - Sites

    public func listSites(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppListSites(c.str(serverID), c.str(appID)) } }, "listSites")
    }

    public func enableSite(serverID: String, appID: String, name: String) async -> String {
        await run({ withCArgs { c in AppEnableSite(c.str(serverID), c.str(appID), c.str(name)) } }, "enableSite")
    }

    public func disableSite(serverID: String, appID: String, name: String) async -> String {
        await run({ withCArgs { c in AppDisableSite(c.str(serverID), c.str(appID), c.str(name)) } }, "disableSite")
    }

    // MARK: - Analytics

    public func getLogAnalytics(serverID: String, appID: String, lines: Int32) async -> String {
        await run({ withCArgs { c in AppGetLogAnalytics(c.str(serverID), c.str(appID), lines) } }, "getLogAnalytics")
    }

    // MARK: - Cache

    public func listCache(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppListCache(c.str(serverID), c.str(appID)) } }, "listCache")
    }

    public func purgeCache(serverID: String, appID: String, path: String) async -> String {
        await run({ withCArgs { c in AppPurgeCache(c.str(serverID), c.str(appID), c.str(path)) } }, "purgeCache")
    }

    // MARK: - Benchmark

    public func runBenchmark(serverID: String, appID: String, url: String, requests: Int32, concurrency: Int32) async -> String {
        await run({ withCArgs { c in AppRunBenchmark(c.str(serverID), c.str(appID), c.str(url), requests, concurrency) } }, "runBenchmark")
    }

    // MARK: - Upstreams

    public func listUpstreams(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppListUpstreams(c.str(serverID), c.str(appID)) } }, "listUpstreams")
    }

    public func writeUpstream(serverID: String, appID: String, upstreamJSON: String) async -> String {
        await run({ withCArgs { c in AppWriteUpstream(c.str(serverID), c.str(appID), c.str(upstreamJSON)) } }, "writeUpstream")
    }

    // MARK: - Full Batch (Single SSH Call)

    /// Returns ALL section data (status, configs, versions, workers, modules)
    /// in a single SSH roundtrip. Use this instead of calling individual methods.
    public func getFullData(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetFullData(c.str(serverID), c.str(appID)) } }, "getFullData")
    }

    // MARK: - PHP-Specific: Pools

    public func listPools(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppListPools(c.str(serverID), c.str(appID)) } }, "listPools")
    }

    public func createPool(serverID: String, appID: String, configJSON: String) async -> String {
        await run({ withCArgs { c in AppCreatePool(c.str(serverID), c.str(appID), c.str(configJSON)) } }, "createPool")
    }

    public func deletePool(serverID: String, appID: String, poolPath: String) async -> String {
        await run({ withCArgs { c in AppDeletePool(c.str(serverID), c.str(appID), c.str(poolPath)) } }, "deletePool")
    }

    public func enablePool(serverID: String, appID: String, poolPath: String) async -> String {
        await run({ withCArgs { c in AppEnablePool(c.str(serverID), c.str(appID), c.str(poolPath)) } }, "enablePool")
    }

    public func disablePool(serverID: String, appID: String, poolPath: String) async -> String {
        await run({ withCArgs { c in AppDisablePool(c.str(serverID), c.str(appID), c.str(poolPath)) } }, "disablePool")
    }

    // MARK: - PHP-Specific: Extensions

    public func listExtensions(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppListExtensions(c.str(serverID), c.str(appID)) } }, "listExtensions")
    }

    public func enableExtension(serverID: String, appID: String, name: String) async -> String {
        await run({ withCArgs { c in AppEnableExtension(c.str(serverID), c.str(appID), c.str(name)) } }, "enableExtension")
    }

    public func disableExtension(serverID: String, appID: String, name: String) async -> String {
        await run({ withCArgs { c in AppDisableExtension(c.str(serverID), c.str(appID), c.str(name)) } }, "disableExtension")
    }

    public func installExtension(serverID: String, appID: String, name: String) async -> String {
        await run({ withCArgs { c in AppInstallExtension(c.str(serverID), c.str(appID), c.str(name)) } }, "installExtension")
    }

    public func uninstallExtension(serverID: String, appID: String, name: String) async -> String {
        await run({ withCArgs { c in AppUninstallExtension(c.str(serverID), c.str(appID), c.str(name)) } }, "uninstallExtension")
    }

    public func extensionCatalog() -> String {
        let result = AppExtensionCatalog()
        return String(cString: result!)
    }

    // MARK: - PHP-Specific: OPcache

    public func getOPcacheStatus(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetOPcacheStatus(c.str(serverID), c.str(appID)) } }, "getOPcacheStatus")
    }

    public func resetOPcache(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppResetOPcache(c.str(serverID), c.str(appID)) } }, "resetOPcache")
    }

    // MARK: - PHP-Specific: Sessions

    public func getSessionInfo(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetSessionInfo(c.str(serverID), c.str(appID)) } }, "getSessionInfo")
    }

    public func cleanupSessions(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppCleanupSessions(c.str(serverID), c.str(appID)) } }, "cleanupSessions")
    }

    // MARK: - PHP-Specific: Xdebug

    public func getXdebugInfo(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetXdebugInfo(c.str(serverID), c.str(appID)) } }, "getXdebugInfo")
    }

    public func toggleXdebug(serverID: String, appID: String, enable: Bool) async -> String {
        await run({ withCArgs { c in AppToggleXdebug(c.str(serverID), c.str(appID), enable ? 1 : 0) } }, "toggleXdebug")
    }

    public func setXdebugMode(serverID: String, appID: String, mode: String) async -> String {
        await run({ withCArgs { c in AppSetXdebugMode(c.str(serverID), c.str(appID), c.str(mode)) } }, "setXdebugMode")
    }

    // MARK: - PHP-Specific: Composer

    public func getComposerInfo(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppGetComposerInfo(c.str(serverID), c.str(appID)) } }, "getComposerInfo")
    }

    public func composerAudit(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppComposerAudit(c.str(serverID), c.str(appID)) } }, "composerAudit")
    }

    public func installComposer(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppInstallComposer(c.str(serverID), c.str(appID)) } }, "installComposer")
    }

    // MARK: - Version Detection (SSH-based)

    public func detectAvailableVersions(serverID: String, appID: String) async -> String {
        await run({ withCArgs { c in AppDetectAvailableVersions(c.str(serverID), c.str(appID)) } }, "detectAvailableVersions")
    }

    // MARK: - Internal

    /// Runs a blocking C bridge call on a background queue, returning the result string.
    private func run(_ block: @escaping @Sendable () -> UnsafeMutablePointer<CChar>?, _ label: String = "unknown") async -> String {
        await withCheckedContinuation { continuation in
            queue.async {
                let start = CFAbsoluteTimeGetCurrent()
                let cStr = block()
                let result: String
                if let cStr = cStr {
                    result = String(cString: cStr)
                    CoreFreeString(cStr)
                } else {
                    result = ""
                }
                let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                print("[PERF-BRIDGE] ApplicationBridge.\(label): CGo call took \(ms)ms")
                continuation.resume(returning: result)
            }
        }
    }
}

