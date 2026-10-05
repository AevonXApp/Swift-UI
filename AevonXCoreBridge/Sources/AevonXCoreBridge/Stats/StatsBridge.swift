//
//  StatsBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core stats polling.
//  Fetches system stats (CPU, RAM, Disk, Temp, Uptime, Load)
//  via Go SSH and returns parsed JSON.
//

import Foundation
import AevonXCoreLib

public final class StatsBridge: @unchecked Sendable {
    
    public static let shared = StatsBridge()
    private init() {}
    
    /// Fetch current server stats via Go SSH.
    /// Returns JSON: `{"success":true,"data":{"cpu":12.5,"memory":45.2,...}}`
    ///
    /// The Go side builds and executes the same batched SSH command as
    /// Swift's `BatchCommandBuilder.overviewStats()`, then parses the output.
    public func fetchStatsAsync(serverID: String) async -> String {
        await background { [self] in
            withCArgs { c in extract(SSHFetchStats(c.str(serverID))) }
        }
    }

    /// Synchronous version for use in background contexts.
    public func fetchStats(serverID: String) -> String {
        withCArgs { c in extract(SSHFetchStats(c.str(serverID))) }
    }
    
    // MARK: - Helpers
    
    private func background(_ work: @escaping @Sendable () -> String) async -> String {
        await Task.detached(priority: .userInitiated) { work() }.value
    }
    
    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }
}
