//
//  DatabaseMetricsService.swift
//  AevonX
//
//  Bridge-backed service for database metrics and performance stats.
//

import Foundation
import AevonXCoreBridge

/// Service for retrieving database metrics, performance stats, and health data.
public actor DatabaseMetricsService {

    public static let shared = DatabaseMetricsService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func getMetrics(type: DatabaseType, serverId: String) async throws -> DatabaseMetrics {
        let cmd = bridge.metricsCmd(engine: type.rawValue)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parseMetrics(output)
    }

    public func getPerformanceStats(type: DatabaseType, serverId: String) async throws -> PerformanceStatistics {
        let cmd = bridge.performanceStatsCmd(engine: type.rawValue)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parsePerformanceStats(output)
    }

    // MARK: - Parsers

    private func parseMetrics(_ output: String) -> DatabaseMetrics {
        var m = DatabaseMetrics()
        for line in output.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count >= 2 else { continue }
            let key = parts[0].lowercased()
            let val = parts[1]
            if key.contains("uptime") { m.uptime = TimeInterval(val) ?? 0 }
            else if key.contains("threads_connected") || key.contains("connections") { m.connections = Int(val) ?? 0 }
            else if key.contains("max_connections") { m.maxConnections = Int(val) ?? 0 }
            else if key.contains("queries") || key.contains("questions") { m.queries = Int64(val) ?? 0 }
            else if key.contains("slow_queries") { m.slowQueries = Int64(val) ?? 0 }
            else if key.contains("innodb_buffer_pool") && key.contains("read") { m.bufferPoolUsage = Double(val) ?? 0 }
        }
        return m
    }

    private func parsePerformanceStats(_ output: String) -> PerformanceStatistics {
        var s = PerformanceStatistics()
        for line in output.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count >= 2 else { continue }
            let key = parts[0].lowercased()
            let val = parts[1]
            if key.contains("queries") && !key.contains("slow") { s.queriesPerSecond = Double(val) ?? 0 }
            else if key.contains("threads_cached") { s.threadsCached = Int(val) ?? 0 }
            else if key.contains("threads_running") { s.threadsRunning = Int(val) ?? 0 }
        }
        return s
    }
}
