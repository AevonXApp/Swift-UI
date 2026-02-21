//
//  ServerStatsViewModel.swift
//  AevonX
//
//  Manages server stats polling, history, and display.
//  Extracted from ServerConnectionViewModel for single-responsibility.
//
//  Uses BatchCommandBuilder to combine 8 SSH calls into 1,
//  and CacheManager for reducing redundant queries.
//

import SwiftUI
import AevonXCore
import Combine

// MARK: - Server Stats ViewModel

/// Manages server system stats (CPU, memory, disk, uptime, load, temperature).
///
/// **Performance**: Uses `BatchCommandBuilder.overviewStats()` to execute
/// all overview commands in a single SSH call (8→1 reduction).
///
/// **Caching**: Results are cached via `CacheManager` with dynamic TTL (30s).
@MainActor
public class ServerStatsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current CPU usage percentage (0-100)
    @Published private(set) var cpuUsage: Double = 0.0
    
    /// CPU usage history for sparklines
    @Published private(set) var cpuUsageHistory: [Double] = []
    
    /// Current memory usage percentage (0-100)
    @Published private(set) var memoryUsage: Double = 0.0
    
    /// Memory usage history for sparklines
    @Published private(set) var memoryUsageHistory: [Double] = []
    
    /// Current disk usage percentage (0-100)
    @Published private(set) var diskUsage: Double = 0.0
    
    /// Disk usage history for sparklines
    @Published private(set) var diskUsageHistory: [Double] = []
    
    /// Server uptime string
    @Published private(set) var uptime: String = "N/A"
    
    /// Load average (1, 5, 15 minute)
    @Published private(set) var loadAverage: String = "N/A"
    
    /// CPU temperature (if available)
    @Published private(set) var cpuTemperature: Double?
    
    /// Temperature history for sparklines
    @Published private(set) var temperatureHistory: [Double] = []
    
    /// Number of websites detected
    @Published private(set) var websiteCount: Int = 0
    
    /// Number of services detected
    @Published private(set) var serviceCount: Int = 0
    
    /// Whether stats are currently being refreshed
    @Published private(set) var isRefreshing: Bool = false
    
    // MARK: - Private Properties
    
    private let serverId: String
    private let sshService: any SSHServiceProtocol
    
    /// Stats polling task
    private var pollingTask: Task<Void, Never>?
    
    /// Polling interval from configuration
    private var pollingInterval: TimeInterval {
        InternalConfiguration.statsPollingInterval
    }
    
    /// Maximum history points to keep
    private let maxHistoryPoints = 20
    
    /// Whether the app is in foreground
    private var isInForeground: Bool = true
    
    // MARK: - Initialization
    
    init(serverId: String, sshService: any SSHServiceProtocol = SSHService.shared) {
        self.serverId = serverId
        self.sshService = sshService
        
        // Initialize history arrays
        self.cpuUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.memoryUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.diskUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.temperatureHistory = Array(repeating: 0.0, count: maxHistoryPoints)
    }
    
    deinit {
        pollingTask?.cancel()
    }
    
    // MARK: - Polling Control
    
    /// Start periodic stats polling.
    func startPolling() {
        stopPolling()
        
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isInForeground else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                
                await self.refreshStats()
                
                try? await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
            }
        }
    }
    
    /// Stop periodic stats polling.
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    /// Handle app entering foreground.
    func appWillEnterForeground() {
        isInForeground = true
    }
    
    /// Handle app entering background.
    func appDidEnterBackground() {
        isInForeground = false
    }
    
    // MARK: - Stats Refresh
    
    /// Refresh all stats using a batched SSH command.
    ///
    /// Combines CPU, memory, disk, uptime, load, temperature, websites, and services
    /// into a single SSH call using `BatchCommandBuilder`.
    func refreshStats() async {
        guard await sshService.isConnected(serverId: serverId) else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            // Build and execute batched overview command (8 commands → 1 SSH call)
            let builder = BatchCommandBuilder.overviewStats()
            let batchCommand = builder.build()
            let result = try await sshService.execute(batchCommand, serverId: serverId)
            
            // Parse batched results
            let parsed = BatchCommandBuilder.parseResults(result.stdout)
            
            // Update CPU
            if let cpuStr = parsed["cpu"], let cpuValue = parsePercentage(cpuStr) {
                updateHistory(&cpuUsageHistory, with: cpuValue)
                cpuUsage = cpuValue
            }
            
            // Update Memory
            if let memStr = parsed["mem"], let memValue = parsePercentage(memStr) {
                updateHistory(&memoryUsageHistory, with: memValue)
                memoryUsage = memValue
            }
            
            // Update Disk
            if let diskStr = parsed["disk"], let diskValue = parsePercentage(diskStr) {
                updateHistory(&diskUsageHistory, with: diskValue)
                diskUsage = diskValue
            }
            
            // Update Uptime
            if let uptimeStr = parsed["uptime"] {
                uptime = uptimeStr.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Update Load Average
            if let loadStr = parsed["load"] {
                loadAverage = loadStr.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Update Temperature
            if let tempStr = parsed["temp"], let temp = parseTemperature(tempStr) {
                updateHistory(&temperatureHistory, with: temp)
                cpuTemperature = temp
            }
            
            // Update Website Count
            if let websiteStr = parsed["websites"], let count = Int(websiteStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                websiteCount = count
            }
            
            // Update Service Count
            if let serviceStr = parsed["services"], let count = Int(serviceStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                serviceCount = count
            }
            
        } catch {
            CoreLogger.shared.warning("Failed to refresh stats: \(error.localizedDescription)", module: "ServerStats")
        }
    }
    
    /// Reset all stats to defaults.
    func reset() {
        cpuUsage = 0.0
        memoryUsage = 0.0
        diskUsage = 0.0
        cpuTemperature = nil
        uptime = "N/A"
        loadAverage = "N/A"
        websiteCount = 0
        serviceCount = 0
        cpuUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        memoryUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        diskUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        temperatureHistory = Array(repeating: 0.0, count: maxHistoryPoints)
    }
    
    // MARK: - Parsing Helpers
    
    private func parsePercentage(_ output: String) -> Double? {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%", with: "")
        return Double(cleaned)
    }
    
    private func parseTemperature(_ output: String) -> Double? {
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "°C", with: "")
            .replacingOccurrences(of: "C", with: "")
        if cleaned == "N/A" || cleaned.isEmpty { return nil }
        return Double(cleaned)
    }
    
    private func updateHistory(_ history: inout [Double], with value: Double) {
        history.append(value)
        if history.count > maxHistoryPoints {
            history.removeFirst()
        }
    }
}
