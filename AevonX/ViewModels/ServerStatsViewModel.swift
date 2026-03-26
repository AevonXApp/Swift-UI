import SwiftUI
import AevonXCoreBridge

import Combine

// MARK: - Server Stats ViewModel

/// Manages server system stats (CPU, memory, disk, uptime, load, temperature).
///
/// **Performance**: Uses Go Core's `SSHFetchStats` which executes all overview
/// commands in a single SSH call (8→1 reduction) via `StatsBridge`.
///
/// **Architecture**: All SSH commands now go through Go Core, not Swift NIO.
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
    
    /// Stats polling task
    private var pollingTask: Task<Void, Never>?
    
    /// Polling interval from settings (falls back to InternalConfiguration)
    private var pollingInterval: TimeInterval {
        let interval = AppSettingsManager.shared.statsRefreshInterval
        return interval > 0 ? TimeInterval(interval) : InternalConfiguration.statsPollingInterval
    }
    
    /// Maximum history points to keep
    private let maxHistoryPoints = 20
    
    /// Whether the app is in foreground
    private var isInForeground: Bool = true
    
    // MARK: - Initialization
    
    init(serverId: String) {
        self.serverId = serverId
        
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
    
    // MARK: - Stats Refresh (via Go Core SSH)
    
    /// Refresh all stats using Go Core's SSHFetchStats.
    ///
    /// Go Core builds the same batched SSH command as the old Swift
    /// `BatchCommandBuilder.overviewStats()`, executes it via Go SSH,
    /// and returns parsed JSON with all stats.
    func refreshStats() async {
        // Check connection via Go SSH
        guard SSHBridge.shared.isConnected(serverID: serverId) else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Fetch stats via Go Core (SSH + parsing happens in Go)
        let resultJSON = await StatsBridge.shared.fetchStatsAsync(serverID: serverId)
        
        // Parse Go response
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let stats = result["data"] as? [String: Any] else {
            AevonXCoreBridge.CoreLogger.shared.warning("Failed to fetch stats via Go Core", module: "ServerStats")
            return
        }
        
        // Update CPU
        if let cpu = stats["cpu"] as? Double {
            updateHistory(&cpuUsageHistory, with: cpu)
            cpuUsage = cpu
        }
        
        // Update Memory
        if let mem = stats["memory"] as? Double {
            updateHistory(&memoryUsageHistory, with: mem)
            memoryUsage = mem
        }
        
        // Update Disk
        if let disk = stats["disk"] as? Double {
            updateHistory(&diskUsageHistory, with: disk)
            diskUsage = disk
        }
        
        // Update Uptime
        if let uptimeStr = stats["uptime"] as? String {
            uptime = uptimeStr
        }
        
        // Update Load Average
        if let loadStr = stats["load_average"] as? String {
            loadAverage = loadStr
        }
        
        // Update Temperature
        if let hasTemp = stats["has_temp"] as? Bool, hasTemp,
           let temp = stats["temperature"] as? Double {
            updateHistory(&temperatureHistory, with: temp)
            cpuTemperature = temp
        }
        
        // Update Website Count
        if let websites = stats["websites"] as? Int {
            websiteCount = websites
        }
        
        // Update Service Count
        if let services = stats["services"] as? Int {
            serviceCount = services
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
    
    // MARK: - History Helper
    
    private func updateHistory(_ history: inout [Double], with value: Double) {
        history.append(value)
        if history.count > maxHistoryPoints {
            history.removeFirst()
        }
    }
}
