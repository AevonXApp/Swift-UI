//
//  CerberusManager.swift
//  AevonXCoreBridge
//
//  Bridge actor wrapping Go Core AXCerberus CGo exports.
//  Provides async/await Swift API for WAF stats and management.
//

import Foundation
import AevonXCoreLib

// MARK: - Cerberus Error

public enum CerberusError: Error, LocalizedError {
    case fetchFailed(action: String, detail: String)
    case decodeFailed(action: String, detail: String)
    case operationFailed(action: String, detail: String)
    case notInstalled
    case timeout(action: String)

    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "AXCerberus is not installed on this server. Please install the plugin first."
        case .fetchFailed(let a, let d):
            return "Cerberus \(a) failed: \(Self.sanitize(d))"
        case .decodeFailed(let a, let d):
            return "Cerberus \(a) decode error: \(d)"
        case .operationFailed(let a, let d):
            return "Cerberus \(a) failed: \(Self.sanitize(d))"
        case .timeout(let a):
            return "Cerberus \(a) timed out"
        }
    }

    private static func sanitize(_ detail: String) -> String {
        if detail.contains("command not found") || detail.contains("No such file or directory") {
            return "AXCerberus binary not found on server — reinstall the plugin"
        }
        if detail.contains("service axcerberus not found") || detail.contains("Unit axcerberus.service not found") {
            return "AXCerberus service not configured — reinstall the plugin"
        }
        if detail.contains("Connection refused") || detail.contains("connection refused") {
            return "WAF daemon is not running — start the service first"
        }
        return detail
    }
}

// MARK: - Cerberus Manager

public actor CerberusManager {

    public static let shared = CerberusManager()

    private init() {}

    // MARK: - Dashboard Bundle

    /// Fetches all dashboard data in a single SSH call (overview, timeline, ddos, service,
    /// credential, countries, block log, qps, anomaly). Replaces 9 concurrent SSH sessions.
    public func getDashboardBundle(on serverId: String) async throws -> CerberusDashboardBundle {
        try await decodeData("dashboard_bundle") { serverId.withMutableCString { CerberusGetDashboardBundle($0) } }
    }

    // MARK: - Stats

    public func getOverview(on serverId: String) async throws -> WAFOverview {
        try await decodeData("overview") { serverId.withMutableCString { CerberusGetOverview($0) } }
    }

    public func getTimeline(on serverId: String) async throws -> [TimelineEntry] {
        try await decodeData("timeline") { serverId.withMutableCString { CerberusGetTimeline($0) } }
    }

    public func getAttackTypes(on serverId: String) async throws -> [AttackTypeStats] {
        try await decodeData("attack_types") { serverId.withMutableCString { CerberusGetAttackTypes($0) } }
    }

    public func getCountries(on serverId: String) async throws -> [CountryStats] {
        try await decodeData("countries") { serverId.withMutableCString { CerberusGetCountries($0) } }
    }

    public func getTopAttackers(on serverId: String) async throws -> [AttackerInfo] {
        try await decodeData("top_attackers") { serverId.withMutableCString { CerberusGetTopAttackers($0) } }
    }

    public func getTopURIs(on serverId: String) async throws -> [URIStats] {
        try await decodeData("top_uris") { serverId.withMutableCString { CerberusGetTopURIs($0) } }
    }

    public func getDomainStats(on serverId: String) async throws -> [String: DomainStats] {
        try await decodeData("domains") { serverId.withMutableCString { CerberusGetDomainStats($0) } }
    }

    public func getQPS(on serverId: String) async throws -> Double {
        let json = await callGo { serverId.withMutableCString { CerberusGetQPS($0) } }
        guard isSuccess(json) else {
            throw CerberusError.fetchFailed(action: "qps", detail: extractError(json))
        }
        guard let data = extractData(json),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let qps = (obj["qps"] as? NSNumber)?.doubleValue else {
            throw CerberusError.decodeFailed(action: "qps", detail: "invalid response")
        }
        return qps
    }

    // MARK: - Module Status

    public func getDDoSStatus(on serverId: String) async throws -> DDoSStatus {
        try await decodeData("ddos") { serverId.withMutableCString { CerberusGetDDoSStatus($0) } }
    }

    public func getHoneypotHits(on serverId: String) async throws -> [HoneypotHit] {
        try await decodeData("honeypot") { serverId.withMutableCString { CerberusGetHoneypotHits($0) } }
    }

    public func getCredentialStatus(on serverId: String) async throws -> CredentialStatus {
        try await decodeData("credential") { serverId.withMutableCString { CerberusGetCredentialStatus($0) } }
    }

    public func getServiceStatus(on serverId: String) async throws -> WAFServiceStatus {
        try await decodeData("service") { serverId.withMutableCString { CerberusGetServiceStatus($0) } }
    }

    // MARK: - IP Management

    public func listBlockedIPs(on serverId: String) async throws -> [String] {
        try await decodeData("blocklist") { serverId.withMutableCString { CerberusListBlockedIPs($0) } }
    }

    public func blockIP(_ ip: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in ip.withMutableCString { i in CerberusBlockIP(s, i) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "blockIP", detail: extractError(json))
        }
    }

    public func unblockIP(_ ip: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in ip.withMutableCString { i in CerberusUnblockIP(s, i) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "unblockIP", detail: extractError(json))
        }
    }

    public func listAllowedIPs(on serverId: String) async throws -> [String] {
        try await decodeData("allowlist") { serverId.withMutableCString { CerberusListAllowedIPs($0) } }
    }

    public func allowIP(_ ip: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in ip.withMutableCString { i in CerberusAllowIP(s, i) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "allowIP", detail: extractError(json))
        }
    }

    public func removeAllowedIP(_ ip: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in ip.withMutableCString { i in CerberusRemoveAllowedIP(s, i) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "removeAllowedIP", detail: extractError(json))
        }
    }

    // MARK: - Extended Stats

    public func getResponseTimes(on serverId: String) async throws -> WAFResponseTimes {
        try await decodeData("response_times") { serverId.withMutableCString { CerberusGetResponseTimes($0) } }
    }

    public func getStatusCodes(on serverId: String) async throws -> [WAFStatusCode] {
        try await decodeData("status_codes") { serverId.withMutableCString { CerberusGetStatusCodes($0) } }
    }

    public func getBotDetails(on serverId: String) async throws -> WAFBotDetails {
        try await decodeData("bot_details") { serverId.withMutableCString { CerberusGetBotDetails($0) } }
    }

    public func getRecentAlerts(on serverId: String) async throws -> [WAFAlertEvent] {
        try await decodeData("alerts") { serverId.withMutableCString { CerberusGetRecentAlerts($0) } }
    }

    // MARK: - Request Logs

    public func getAccessLog(on serverId: String) async throws -> WAFAccessLogResponse {
        try await decodeData("access_log") { serverId.withMutableCString { CerberusGetAccessLog($0) } }
    }

    public func getBlockLog(on serverId: String) async throws -> WAFBlockLogResponse {
        try await decodeData("block_log") { serverId.withMutableCString { CerberusGetBlockLog($0) } }
    }

    // MARK: - Service Lifecycle

    public func serviceStart(on serverId: String) async throws -> WAFServiceActionResult {
        try await decodeData("service.start") { serverId.withMutableCString { CerberusServiceStart($0) } }
    }

    public func serviceStop(on serverId: String) async throws -> WAFServiceActionResult {
        try await decodeData("service.stop") { serverId.withMutableCString { CerberusServiceStop($0) } }
    }

    public func serviceRestart(on serverId: String) async throws -> WAFServiceActionResult {
        try await decodeData("service.restart") { serverId.withMutableCString { CerberusServiceRestart($0) } }
    }

    public func serviceReload(on serverId: String) async throws -> WAFServiceActionResult {
        try await decodeData("service.reload") { serverId.withMutableCString { CerberusServiceReload($0) } }
    }

    // MARK: - Domain Management

    public func listDomains(on serverId: String) async throws -> [WAFDomainInfo] {
        try await decodeData("domains.list") { serverId.withMutableCString { CerberusListDomains($0) } }
    }

    public func addDomain(_ domain: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in domain.withMutableCString { d in CerberusAddDomain(s, d) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "addDomain", detail: extractError(json))
        }
    }

    public func removeDomain(_ domain: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in domain.withMutableCString { d in CerberusRemoveDomain(s, d) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "removeDomain", detail: extractError(json))
        }
    }

    public func enableDomain(_ domain: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in domain.withMutableCString { d in CerberusEnableDomain(s, d) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "enableDomain", detail: extractError(json))
        }
    }

    public func disableDomain(_ domain: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDisableDomain(s, d) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "disableDomain", detail: extractError(json))
        }
    }

    public func syncDomains(on serverId: String) async throws -> WAFDomainSyncResult {
        try await decodeData("domains.sync") { serverId.withMutableCString { CerberusSyncDomains($0) } }
    }

    public func detectWebServer(on serverId: String) async throws -> WAFWebServerInfo {
        try await decodeData("domains.detect_server") { serverId.withMutableCString { CerberusDetectWebServer($0) } }
    }

    // MARK: - Config Management

    public func getFullConfig(on serverId: String) async throws -> [String: Any] {
        let json = await callGo { serverId.withMutableCString { CerberusGetFullConfig($0) } }
        guard isSuccess(json) else {
            throw CerberusError.fetchFailed(action: "config.all", detail: extractError(json))
        }
        guard let data = extractData(json),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CerberusError.decodeFailed(action: "config.all", detail: "invalid response")
        }
        return obj
    }

    public func configSet(key: String, value: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in key.withMutableCString { k in value.withMutableCString { v in CerberusConfigSet(s, k, v) } } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "config.set(\(key))", detail: extractError(json))
        }
    }

    // MARK: - GeoIP Management

    public func listBlockedCountries(on serverId: String) async throws -> [String] {
        try await decodeData("geoip") { serverId.withMutableCString { CerberusListBlockedCountries($0) } }
    }

    public func blockCountry(_ code: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in code.withMutableCString { c in CerberusBlockCountry(s, c) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "blockCountry", detail: extractError(json))
        }
    }

    public func unblockCountry(_ code: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in code.withMutableCString { c in CerberusUnblockCountry(s, c) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "unblockCountry", detail: extractError(json))
        }
    }

    // MARK: - Threat Feed

    public func getThreatFeedStatus(on serverId: String) async throws -> WAFThreatFeedStatus {
        try await decodeData("threatfeed") { serverId.withMutableCString { CerberusGetThreatFeedStatus($0) } }
    }

    public func updateThreatFeed(on serverId: String) async throws -> WAFThreatFeedStatus {
        try await decodeData("threatfeed.update") { serverId.withMutableCString { CerberusThreatFeedUpdate($0) } }
    }

    // MARK: - Virtual Patching

    public func listVPatches(on serverId: String) async throws -> [WAFVirtualPatch] {
        try await decodeData("vpatch.list") { serverId.withMutableCString { CerberusListVPatches($0) } }
    }

    public func applyVPatch(_ patchJSON: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in patchJSON.withMutableCString { p in CerberusApplyVPatch(s, p) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "vpatch.apply", detail: extractError(json))
        }
    }

    public func removeVPatch(_ patchID: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in patchID.withMutableCString { p in CerberusRemoveVPatch(s, p) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "vpatch.remove", detail: extractError(json))
        }
    }

    // MARK: - Log Export & Config Backup

    public func exportLogs(_ logType: String, on serverId: String) async throws -> [String: Any] {
        let json = await callGo { serverId.withMutableCString { s in logType.withMutableCString { l in CerberusExportLogs(s, l) } } }
        guard isSuccess(json), let data = extractData(json),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CerberusError.fetchFailed(action: "logs.export", detail: extractError(json))
        }
        return obj
    }

    public func configBackup(on serverId: String) async throws -> [String: Any] {
        let json = await callGo { serverId.withMutableCString { CerberusConfigBackup($0) } }
        guard isSuccess(json), let data = extractData(json),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CerberusError.fetchFailed(action: "config.backup", detail: extractError(json))
        }
        return obj
    }

    public func configRestore(_ backupName: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in backupName.withMutableCString { b in CerberusConfigRestore(s, b) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "config.restore", detail: extractError(json))
        }
    }

    public func listConfigBackups(on serverId: String) async throws -> [WAFConfigBackup] {
        try await decodeData("config.list_backups") { serverId.withMutableCString { CerberusListConfigBackups($0) } }
    }

    // MARK: - Anomaly Detection

    public func getAnomalyStatus(on serverId: String) async throws -> WAFAnomalyStatus {
        try await decodeData("anomaly") { serverId.withMutableCString { CerberusGetAnomalyStatus($0) } }
    }

    // MARK: - Session Tracking

    public func getSessionStatus(on serverId: String) async throws -> WAFSessionStatus {
        try await decodeData("session") { serverId.withMutableCString { CerberusGetSessionStatus($0) } }
    }

    // MARK: - Custom Rules

    public func listRules(on serverId: String) async throws -> WAFCustomRulesResponse {
        try await decodeData("rules.list") { serverId.withMutableCString { CerberusListRules($0) } }
    }

    public func addRule(id: String, expression: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in id.withMutableCString { i in expression.withMutableCString { e in CerberusAddRule(s, i, e) } } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "rules.add", detail: extractError(json))
        }
    }

    public func removeRule(id: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in id.withMutableCString { i in CerberusRemoveRule(s, i) } } }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "rules.remove", detail: extractError(json))
        }
    }

    // MARK: - Compliance

    public func getComplianceReport(on serverId: String) async throws -> WAFComplianceReport {
        try await decodeData("compliance") { serverId.withMutableCString { CerberusGetComplianceReport($0) } }
    }

    // MARK: - Per-Domain Countries

    public func getDomainCountries(domain: String, on serverId: String) async throws -> WAFDomainCountries {
        try await decodeData("domain_countries") {
            serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDomainCountries(s, d) } }
        }
    }

    // MARK: - Per-Domain Timeline & Logs

    public func getDomainTimeline(domain: String, on serverId: String) async throws -> WAFDomainTimeline {
        try await decodeData("domain_timeline") {
            serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDomainTimeline(s, d) } }
        }
    }

    public func getDomainAccessLog(domain: String, on serverId: String) async throws -> WAFAccessLogResponse {
        try await decodeData("domain_access_log") {
            serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDomainAccessLog(s, d) } }
        }
    }

    public func getDomainBlockLog(domain: String, on serverId: String) async throws -> WAFBlockLogResponse {
        try await decodeData("domain_block_log") {
            serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDomainBlockLog(s, d) } }
        }
    }

    // MARK: - Per-Domain IP Blocking

    public func getDomainBlockedIPs(domain: String, on serverId: String) async throws -> WAFDomainRulesIP {
        try await decodeData("domain_blocked_ips") {
            serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDomainBlockedIPs(s, d) } }
        }
    }

    public func domainBlockIP(_ ip: String, domain: String, on serverId: String) async throws {
        let json = await callGo {
            serverId.withMutableCString { s in domain.withMutableCString { d in ip.withMutableCString { i in CerberusDomainBlockIP(s, d, i) } } }
        }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "domain_block_ip", detail: extractError(json))
        }
    }

    public func domainUnblockIP(_ ip: String, domain: String, on serverId: String) async throws {
        let json = await callGo {
            serverId.withMutableCString { s in domain.withMutableCString { d in ip.withMutableCString { i in CerberusDomainUnblockIP(s, d, i) } } }
        }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "domain_unblock_ip", detail: extractError(json))
        }
    }

    // MARK: - Per-Domain Country Blocking

    public func getDomainBlockedCountries(domain: String, on serverId: String) async throws -> WAFDomainRulesCountry {
        try await decodeData("domain_blocked_countries") {
            serverId.withMutableCString { s in domain.withMutableCString { d in CerberusDomainBlockedCountries(s, d) } }
        }
    }

    public func domainBlockCountry(_ code: String, domain: String, on serverId: String) async throws {
        let json = await callGo {
            serverId.withMutableCString { s in domain.withMutableCString { d in code.withMutableCString { c in CerberusDomainBlockCountry(s, d, c) } } }
        }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "domain_block_country", detail: extractError(json))
        }
    }

    public func domainUnblockCountry(_ code: String, domain: String, on serverId: String) async throws {
        let json = await callGo {
            serverId.withMutableCString { s in domain.withMutableCString { d in code.withMutableCString { c in CerberusDomainUnblockCountry(s, d, c) } } }
        }
        guard isSuccess(json) else {
            throw CerberusError.operationFailed(action: "domain_unblock_country", detail: extractError(json))
        }
    }

    // MARK: - Extended Time Series

    public func getTimeSeries(start: String, end: String, granularity: String, on serverId: String) async throws -> WAFTimeSeriesResponse {
        try await decodeData("timeseries") {
            serverId.withMutableCString { s in
                start.withMutableCString { st in
                    end.withMutableCString { e in
                        granularity.withMutableCString { g in
                            CerberusGetTimeSeries(s, st, e, g)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Config Batch Update

    public func configSetBatch(_ updates: [String: String], on serverId: String) async throws -> WAFConfigBatchResponse {
        let jsonData = try JSONEncoder().encode(updates)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        return try await decodeData("config.batch") {
            serverId.withMutableCString { s in jsonString.withMutableCString { j in CerberusConfigSetBatch(s, j) } }
        }
    }

    // MARK: - Helpers

    private static let callGoTimeoutSeconds: Double = 45

    /// Thread-safe holder for CGo call result.
    private final class GoCallResult: @unchecked Sendable {
        var json = ""
    }

    private func callGo(_ work: @escaping @Sendable () -> UnsafeMutablePointer<CChar>?) async -> String {
        let holder = GoCallResult()
        let semaphore = DispatchSemaphore(value: 0)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = work()
                defer { if let r = result { CoreFreeString(r) } }
                holder.json = result.map { String(cString: $0) } ?? ""
                semaphore.signal()
            }

            DispatchQueue.global(qos: .utility).async {
                if semaphore.wait(timeout: .now() + Self.callGoTimeoutSeconds) == .timedOut {
                    continuation.resume(returning: "{\"success\":false,\"error\":\"operation timed out\"}")
                } else {
                    continuation.resume(returning: holder.json)
                }
            }
        }
    }

    private func decodeData<T: Decodable>(_ action: String, _ work: @escaping @Sendable () -> UnsafeMutablePointer<CChar>?) async throws -> T {
        let json = await callGo(work)
        guard isSuccess(json) else {
            let detail = extractError(json)
            if detail.contains("No such file or directory") || detail.contains("command not found") {
                throw CerberusError.notInstalled
            }
            throw CerberusError.fetchFailed(action: action, detail: detail)
        }
        guard let data = extractData(json) else {
            throw CerberusError.decodeFailed(action: action, detail: "no data in response")
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CerberusError.decodeFailed(action: action, detail: error.localizedDescription)
        }
    }

    private func isSuccess(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return obj["success"] as? Bool ?? false
    }

    private func extractError(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return "Unknown" }
        return obj["error"] as? String ?? "Unknown error"
    }

    private func extractData(_ json: String) -> Data? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"],
              !(inner is NSNull) else { return nil }
        return try? JSONSerialization.data(withJSONObject: inner)
    }
}
