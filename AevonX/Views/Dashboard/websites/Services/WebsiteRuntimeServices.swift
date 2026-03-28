//
//  WebsiteRuntimeServices.swift
//  AevonX
//
//  Runtime services for Websites section.
//  ALL commands come from Go Core — no hardcoded SSH commands here.
//  These actors are thin wrappers around SSHBridge + Go Core command builders.
//

import Foundation
import AevonXCoreBridge

// MARK: - NodeJS Config Service

public actor NodeJSConfigService {
    public static let shared = NodeJSConfigService()
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false
    private let bridge = GenericBridge.shared
    public init() {}

    private func detectPathsIfNeeded(serverId: String) async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    public func readPackageJSON(appPath: String, serverId: String) async throws -> PackageJSON? {
        let cmd = bridge.callSync("websites.readPackageJSONCmd", ["app_path": appPath])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return nil }
        return try JSONDecoder().decode(PackageJSON.self, from: data)
    }

    public func detectEntryFile(appPath: String, serverId: String) async throws -> String {
        if let pkg = try await readPackageJSON(appPath: appPath, serverId: serverId) {
            return pkg.entryFile
        }
        let cmd = bridge.callSync("websites.detectEntryFileCmd", ["app_path": appPath])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "index.js" : trimmed
    }

    public func readEnvFile(appPath: String, serverId: String) async throws -> [EnvironmentVariable] {
        let cmd = bridge.callSync("websites.readEnvFileCmd", ["app_path": appPath])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let secretKeys = ["SECRET", "KEY", "PASSWORD", "TOKEN", "API_KEY", "PRIVATE", "CREDENTIALS"]
        return trimmed.split(separator: "\n").compactMap { line in
            let l = String(line).trimmingCharacters(in: .whitespaces)
            guard !l.isEmpty, !l.hasPrefix("#") else { return nil }
            let parts = l.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            var value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            let isSecret = secretKeys.contains { key.uppercased().contains($0) }
            return EnvironmentVariable(key: key, value: value, isSecret: isSecret)
        }
    }

    public func writeEnvFile(variables: [EnvironmentVariable], appPath: String, serverId: String) async throws {
        let content = variables.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        let cmd = bridge.callSync("websites.writeEnvFileCmd", ["app_path": appPath, "content": content])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func npmInstall(appPath: String, serverId: String) async throws -> String {
        let cmd = bridge.callSync("websites.npmInstallCmd", ["app_path": appPath])
        return await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func npmRun(script: String, appPath: String, serverId: String) async throws -> String {
        let cmd = bridge.callSync("websites.npmRunCmd", ["script": script, "app_path": appPath])
        return await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    // MARK: - Nginx Reverse Proxy

    public func applyNginxReverseProxy(domain: String, port: Int, sslEnabled: Bool, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        let result = bridge.callSync("websites.applyNodeProxyCmds", [
            "domain": domain, "port": port, "ssl_enabled": sslEnabled,
            "sites_available": serverPaths.nginxSitesAvailable,
            "sites_enabled": serverPaths.nginxSitesEnabled,
            "ssl_base_path": serverPaths.letsEncryptDir
        ])
        let cmds = extractCmds(result)
        for cmd in cmds {
            let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            if cmd.contains("nginx -t") && !output.contains("successful") && !output.contains("ok") {
                throw NSError(domain: "NodeJSConfig", code: 3, userInfo: [NSLocalizedDescriptionKey: "Nginx config test failed: \(output)"])
            }
        }
    }
}

// MARK: - Website Analytics Service

public actor WebsiteAnalyticsService {
    public static let shared = WebsiteAnalyticsService()
    private let bridge = GenericBridge.shared
    public init() {}

    public struct HealthResult {
        public let isReachable: Bool
        public let responseTime: Double
        public let statusCode: Int
        public let sslValid: Bool
        public let issues: [HealthIssue]
    }

    public struct HealthIssue {
        public let severity: HealthIssueSeverity
        public let title: String
        public let description: String
        public let recommendation: String
    }

    public enum HealthIssueSeverity: String {
        case info, warning, critical
    }

    public func checkWebsiteHealth(websiteId: String, serverId: String) async throws -> HealthResult {
        let cmd = bridge.callSync("websites.siteHealthCheckCmd", ["domain": websiteId])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        let status = Int(parts.first ?? "") ?? 0
        let time = Double(parts.last ?? "") ?? 0
        return HealthResult(isReachable: (200...399).contains(status), responseTime: time, statusCode: status, sslValid: true, issues: [])
    }
}

// MARK: - Website SSL Service

public actor WebsiteSSLService {
    public static let shared = WebsiteSSLService()
    private let bridge = GenericBridge.shared
    public init() {}

    public func renewSSL(websiteId: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.certbotRenewCmd", ["domain": websiteId])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        if output.contains("FAILED") || output.contains("error") {
            throw NSError(domain: "SSL", code: 1, userInfo: [NSLocalizedDescriptionKey: "SSL renewal failed: \(output)"])
        }
    }
}

// MARK: - NodeJS Version Service

public actor NodeJSVersionService {
    public static let shared = NodeJSVersionService()
    private let bridge = GenericBridge.shared
    public init() {}

    public func getInstalledVersion(serverId: String) async -> String? {
        let cmd = bridge.callSync("websites.nvmGetVersionCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public func detectCurrentVersion(serverId: String) async throws -> String? {
        return await getInstalledVersion(serverId: serverId)
    }

    public func getNPMVersion(serverId: String) async -> String? {
        let cmd = bridge.callSync("websites.nvmGetNPMVersionCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public func detectNPMVersion(serverId: String) async throws -> String? {
        return await getNPMVersion(serverId: serverId)
    }

    public func getInstalledVersions(serverId: String) async throws -> [String] {
        let cmd = bridge.callSync("websites.nvmGetInstalledVersionsCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "") }
            .filter { !$0.isEmpty }
    }

    public func isNvmInstalled(serverId: String) async throws -> Bool {
        let cmd = bridge.callSync("websites.nvmIsInstalledCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "yes"
    }

    public func installNvm(serverId: String) async throws {
        let cmd = bridge.callSync("websites.nvmInstallCmd", [:])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func installVersion(_ version: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.nvmInstallVersionCmd", ["version": version])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func switchVersion(_ version: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.nvmSwitchVersionCmd", ["version": version])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func getAvailableVersions(serverId: String) async throws -> [String] {
        let cmd = bridge.callSync("websites.nvmGetAvailableVersionsCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "") }
            .filter { !$0.isEmpty }
    }
}

// MARK: - NodeJS Process Service (PM2)

public actor NodeJSProcessService {
    public static let shared = NodeJSProcessService()
    private let bridge = GenericBridge.shared
    public init() {}

    public func isPM2Installed(serverId: String) async throws -> Bool {
        let cmd = bridge.callSync("websites.pm2IsInstalledCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func installPM2(serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2InstallCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        if output.contains("ERR!") {
            throw NSError(domain: "PM2", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to install PM2: \(output)"])
        }
    }

    public func listProcesses(serverId: String) async throws -> [PM2Process] {
        let cmd = bridge.callSync("websites.pm2ListCmd", [:])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.first == "[", let data = trimmed.data(using: .utf8) else { return [] }
        let raw = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return raw.compactMap { item -> PM2Process? in
            guard let pmId = item["pm_id"] as? Int, let name = item["name"] as? String,
                  let env = item["pm2_env"] as? [String: Any], let monit = item["monit"] as? [String: Any] else { return nil }
            return PM2Process(id: pmId, name: name, status: PM2Process.PM2Status(rawValue: env["status"] as? String ?? "unknown") ?? .unknown, cpu: monit["cpu"] as? Double ?? 0, memory: monit["memory"] as? Int64 ?? 0, uptime: env["pm_uptime"] as? Int64, restarts: env["restart_time"] as? Int ?? 0, pid: env["pid"] as? Int)
        }
    }

    public func startProcess(name: String, entryFile: String? = nil, cwd: String? = nil, serverId: String) async throws -> String {
        let cmd = bridge.callSync("websites.pm2StartCmd", ["name": name, "entry_file": entryFile ?? "", "cwd": cwd ?? ""])
        return await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func stopProcess(name: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2StopCmd", ["name": name])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func restartProcess(name: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2RestartCmd", ["name": name])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func deleteProcess(name: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2DeleteCmd", ["name": name])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func getProcessLogs(name: String, lines: Int = 50, serverId: String) async throws -> String {
        let cmd = bridge.callSync("websites.pm2LogsCmd", ["name": name, "lines": lines])
        return await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func saveProcessList(serverId: String) async throws {
        let result = bridge.callSync("websites.pm2SaveCmds", [:])
        let cmds = extractCmds(result)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
    }

    public func reloadProcess(name: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2ReloadCmd", ["name": name])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func scaleProcess(name: String, instances: Int, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2ScaleCmd", ["name": name, "instances": instances])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func startCluster(name: String, entryFile: String, instances: Int, cwd: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2StartClusterCmd", ["name": name, "entry_file": entryFile, "instances": instances, "cwd": cwd])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func generateEcosystemConfig(name: String, script: String, cwd: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2EcosystemCmd", ["name": name, "script": script, "cwd": cwd])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }
}

// MARK: - Site Monitoring Service

public actor SiteMonitoringService {
    public static let shared = SiteMonitoringService()
    private let bridge = GenericBridge.shared
    public init() {}

    public func measureResponseTime(domain: String, serverId: String) async throws -> Double {
        let cmd = bridge.callSync("websites.siteResponseTimeCmd", ["domain": domain])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return Double(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    public func analyzeDiskUsage(docRoot: String, serverId: String) async throws -> [CoreDiskEntry] {
        let cmd = bridge.callSync("websites.siteDiskUsageCmd", ["doc_root": docRoot])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return output.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .compactMap { line -> CoreDiskEntry? in
                let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: "\t")
                guard parts.count >= 2 else { return nil }
                return CoreDiskEntry(size: parts[0], path: parts[1])
            }
    }

    public func findLargeFiles(docRoot: String, serverId: String) async throws -> [String] {
        let cmd = bridge.callSync("websites.siteLargeFilesCmd", ["doc_root": docRoot])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

public struct CoreDiskEntry: Sendable {
    public let size: String
    public let path: String
    nonisolated public init(size: String, path: String) {
        self.size = size; self.path = path
    }
}

// MARK: - Site Quick Actions Service

public actor SiteQuickActionsService {
    public static let shared = SiteQuickActionsService()
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false
    private let bridge = GenericBridge.shared
    public init() {}

    private func detectPathsIfNeeded(serverId: String) async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    public func restartPHPFPM(version: String, serverId: String) async throws {
        let cmd = bridge.callSync("websites.restartPHPCmd", ["version": version])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func restartPM2(serverId: String) async throws {
        let cmd = bridge.callSync("websites.pm2RestartCmd", ["name": "all"])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func restartNginx(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: WebsitesBridge.shared.restartNginxCmd())
    }

    public func reloadNginx(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: WebsitesBridge.shared.reloadNginxCmd())
    }

    public func fixOwnership(docRoot: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        let cmd = bridge.callSync("websites.fixOwnershipCmd", ["doc_root": docRoot, "web_ownership": serverPaths.webOwnership])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func clearAppCache(docRoot: String, serverId: String) async throws -> String {
        let cmd = bridge.callSync("websites.clearAppCacheCmd", ["doc_root": docRoot])
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func getDiskUsage(docRoot: String, serverId: String) async throws -> String {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: WebsitesBridge.shared.getDiskUsageCmd(docRoot: docRoot))
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func testNginxConfig(serverId: String) async throws -> (passed: Bool, output: String) {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: WebsitesBridge.shared.validateNginxCmd())
        let passed = output.contains("syntax is ok") || output.contains("test is successful")
        return (passed: passed, output: output)
    }
}

// MARK: - Website Lifecycle Service

public actor WebsiteLifecycleService {
    public static let shared = WebsiteLifecycleService()
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false
    private let bridge = GenericBridge.shared
    public init() {}

    private func detectPathsIfNeeded(serverId: String) async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    public func deleteWebsite(websiteId: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        CoreLogger.shared.info("Deleting website: \(websiteId)", module: "WebsiteLifecycleService")
        let result = bridge.callSync("websites.siteDeleteCmds", [
            "domain": websiteId,
            "sites_available": serverPaths.nginxSitesAvailable,
            "sites_enabled": serverPaths.nginxSitesEnabled
        ])
        let cmds = extractCmds(result)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        CoreLogger.shared.info("Website deleted successfully", module: "WebsiteLifecycleService")
    }

    public func startWebsite(websiteId: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        let cmd = bridge.callSync("websites.siteStartCmd", [
            "domain": websiteId,
            "sites_available": serverPaths.nginxSitesAvailable,
            "sites_enabled": serverPaths.nginxSitesEnabled
        ])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }

    public func stopWebsite(websiteId: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        let cmd = bridge.callSync("websites.siteStopCmd", [
            "domain": websiteId,
            "sites_enabled": serverPaths.nginxSitesEnabled
        ])
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: extractCmd(cmd))
    }
}

// MARK: - Database Management Service (stub)

public struct CoreDatabaseInfo: Sendable {
    public let id: String
    public let name: String
    public let size: Double // MB
    public let tables: Int

    nonisolated public init(id: String = UUID().uuidString, name: String, size: Double, tables: Int) {
        self.id = id; self.name = name; self.size = size; self.tables = tables
    }
}

public actor DatabaseManagementService {
    public static let shared = DatabaseManagementService()
    public init() {}

    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    public func listDatabases(type: String, serverId: String) async throws -> [CoreDatabaseInfo] {
        let engine = type.lowercased()
        let cmd = bridge.listDatabasesCmd(engine: engine)
        guard !cmd.isEmpty else { return [] }

        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }.compactMap { line in
            let lower = line.lowercased()
            if lower.contains("error") || lower.contains("warning") || lower.contains("access denied") { return nil }
            let parts = line.split(separator: "\t")
            guard let first = parts.first else { return nil }
            let name = String(first).trimmingCharacters(in: .whitespaces)
            let sizeBytes = parts.count >= 2 ? (Double(parts[1]) ?? 0) : 0
            let size = sizeBytes / (1024.0 * 1024.0) // Convert bytes to MB
            let tables = parts.count >= 3 ? (Int(parts[2]) ?? 0) : 0
            return CoreDatabaseInfo(name: name, size: size, tables: tables)
        }
    }

    public func createDatabase(name: String, type: String, characterSet: String? = nil, collation: String? = nil, serverId: String) async throws {
        let cmd = bridge.createDatabaseCmd(engine: type.lowercased(), name: name, charset: characterSet ?? "", collation: collation ?? "")
        guard !cmd.isEmpty else {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported database type: \(type)"])
        }
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        if output.lowercased().contains("error") {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: output])
        }
    }

    public func deleteDatabase(name: String, type: String, serverId: String) async throws {
        let cmd = bridge.dropDatabaseCmd(engine: type.lowercased(), name: name)
        guard !cmd.isEmpty else {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported database type: \(type)"])
        }
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        if output.lowercased().contains("error") {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: output])
        }
    }
}

// MARK: - Helpers

/// Extracts a single command string from a Go Core dispatch response.
nonisolated func extractCmd(_ json: String) -> String {
    guard let data = json.data(using: .utf8),
          let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          resp["success"] as? Bool == true,
          let innerData = resp["data"] as? [String: Any],
          let command = innerData["command"] as? String else {
        return ""
    }
    return command
}

/// Extracts a command array from a Go Core dispatch response.
nonisolated func extractCmds(_ json: String) -> [String] {
    guard let data = json.data(using: .utf8),
          let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          resp["success"] as? Bool == true,
          let innerData = resp["data"] as? [String: Any],
          let cmds = innerData["commands"] as? [String] else {
        return []
    }
    return cmds
}
