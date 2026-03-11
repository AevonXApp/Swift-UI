//
//  DatabaseEngineService.swift
//  AevonX
//
//  Bridge-backed service for database engine operations.
//  Replaces AevonXCore DatabaseEngineService using DatabasesBridge + SSHBridge.
//

import Foundation
import AevonXCoreBridge

/// Service for database engine detection, installation, and service control.
/// Uses DatabasesBridge for command generation and SSHBridge for execution.
public actor DatabaseEngineService {

    public static let shared = DatabaseEngineService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    // MARK: - Detection

    /// Detect all installed database engines on a server.
    public func detectInstalledDatabases(serverId: String) async -> [BridgeInstallationState] {
        let detectCmd = bridge.detectAllCmd()
        guard !detectCmd.isEmpty else { return [] }

        let output = await ssh.executeAsync(serverID: serverId, command: detectCmd)
        return parseDetectionOutput(output)
    }

    /// Check installation state of a specific engine.
    public func checkDatabaseInstallation(type: DatabaseType, serverId: String) async -> BridgeInstallationState {
        let engine = type.rawValue
        let isInstalledCmd = bridge.isInstalledCmd(engine: engine)
        let installedOutput = await ssh.executeAsync(serverID: serverId, command: isInstalledCmd)
        let isInstalled = installedOutput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "yes"

        var state = BridgeInstallationState(isInstalled: isInstalled)

        if isInstalled {
            let versionCmd = bridge.getVersionCmd(engine: engine)
            state.version = await ssh.executeAsync(serverID: serverId, command: versionCmd)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let pathCmd = bridge.getInstallPathCmd(engine: engine)
            state.installPath = await ssh.executeAsync(serverID: serverId, command: pathCmd)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return state
    }

    // MARK: - Service Control

    public func startService(type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.startCmd(engine: type.rawValue)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") || result.lowercased().contains("failed") {
            throw DatabaseServiceError.operationFailed("Start failed: \(result)")
        }
    }

    public func stopService(type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.stopCmd(engine: type.rawValue)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") || result.lowercased().contains("failed") {
            throw DatabaseServiceError.operationFailed("Stop failed: \(result)")
        }
    }

    public func restartService(type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.restartCmd(engine: type.rawValue)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") || result.lowercased().contains("failed") {
            throw DatabaseServiceError.operationFailed("Restart failed: \(result)")
        }
    }

    public func enableService(type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.enableOnBootCmd(engine: type.rawValue)
        _ = await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    public func disableService(type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.disableOnBootCmd(engine: type.rawValue)
        _ = await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    public func getServiceStatus(type: DatabaseType, serverId: String) async -> BridgeServiceStatus {
        let cmd = bridge.statusCmd(engine: type.rawValue)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch result {
        case "active": return .active
        case "inactive": return .inactive
        case "failed": return .failed
        default: return .unknown
        }
    }

    // MARK: - Installation

    public func installDatabase(type: DatabaseType, version: String = "", serverId: String) async throws {
        let cmd = bridge.installCmd(engine: type.rawValue, version: version)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") && !result.lowercased().contains("already") {
            throw DatabaseServiceError.operationFailed("Installation failed: \(result)")
        }
    }

    public func uninstallDatabaseEngine(type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.uninstallCmd(engine: type.rawValue)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") && !result.lowercased().contains("not installed") {
            throw DatabaseServiceError.operationFailed("Uninstall failed: \(result)")
        }
    }

    // MARK: - Configuration

    public func getConfiguration(type: DatabaseType, serverId: String) async throws -> DatabaseConfiguration {
        let pathCmd = bridge.configPathCmd(engine: type.rawValue)
        let configPath = await ssh.executeAsync(serverID: serverId, command: pathCmd)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let readCmd = bridge.readConfigCmd(engine: type.rawValue)
        let content = await ssh.executeAsync(serverID: serverId, command: readCmd)

        return DatabaseConfiguration(configPath: configPath, content: content)
    }

    public func updateConfiguration(_ config: DatabaseConfiguration, type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.writeConfigCmd(engine: type.rawValue, content: config.content)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Config update failed: \(result)")
        }
    }

    // MARK: - Version Management

    public func getAvailableVersions(type: DatabaseType, serverId: String) async throws -> [String] {
        let versionCmd = bridge.getVersionCmd(engine: type.rawValue)
        let result = await ssh.executeAsync(serverID: serverId, command: versionCmd)
        return result.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Parsing

    private func parseDetectionOutput(_ output: String) -> [BridgeInstallationState] {
        // The Go DetectAllCmd() outputs:
        //   mysql:
        //   /usr/bin/mysql
        //   mysql  Ver 8.0.36-0ubuntu0.24.04.1 ...
        //   postgresql:
        //   /usr/bin/psql
        //   psql (PostgreSQL) 16.4
        //   redis:
        //   mongodb:
        //   ...
        // Each engine section starts with "enginename:" label.
        // If command -v fails, no path/version lines follow.
        
        let lines = output.components(separatedBy: .newlines)
        
        // Engine labels we look for (must match Go's DetectAllCmd echo labels)
        let engineLabels = ["mysql", "mariadb", "postgresql", "redis", "mongodb", "cassandra", "cockroachdb", "elasticsearch", "sqlite"]
        
        // Collect lines per engine section
        var sections: [String: [String]] = [:]
        var currentEngine: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // Check if this is an engine label line (e.g. "mysql:" or "postgresql:")
            let lowered = trimmed.lowercased()
            if let engine = engineLabels.first(where: { lowered == "\($0):" }) {
                currentEngine = engine
                sections[engine] = []
            } else if let engine = currentEngine {
                sections[engine, default: []].append(trimmed)
            }
        }
        
        // Build states in the same order as engine labels
        var states: [BridgeInstallationState] = []
        for engine in engineLabels {
            let sectionLines = sections[engine] ?? []
            // If there are lines after the label, the engine is installed
            // (command -v succeeded and produced output)
            let isInstalled = !sectionLines.isEmpty
            var version = ""
            var installPath = ""
            
            if isInstalled {
                // First line is usually the path from `command -v`
                if let first = sectionLines.first, first.hasPrefix("/") {
                    installPath = first
                }
                // Extract version from version lines
                for vLine in sectionLines {
                    // Skip the path line
                    if vLine.hasPrefix("/") { continue }
                    // This is the version output (e.g. "mysql  Ver 8.0.36..." or "psql (PostgreSQL) 16.4")
                    version = extractVersionNumber(from: vLine)
                    if !version.isEmpty { break }
                }
            }
            
            states.append(BridgeInstallationState(isInstalled: isInstalled, version: version, installPath: installPath))
        }
        
        return states
    }
    
    /// Extracts a version number like "8.0.36" or "16.4" from a version string.
    private func extractVersionNumber(from text: String) -> String {
        // Try to find a version pattern like X.Y.Z or X.Y
        let pattern = #"(\d+\.\d+[\.\d]*)"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return text
    }
}

// MARK: - Database Service Error

public enum DatabaseServiceError: Error, LocalizedError {
    case operationFailed(String)
    case notConnected
    case invalidResponse(String)

    public var errorDescription: String? {
        switch self {
        case .operationFailed(let msg): return msg
        case .notConnected: return "Not connected to server"
        case .invalidResponse(let msg): return "Invalid response: \(msg)"
        }
    }
}
