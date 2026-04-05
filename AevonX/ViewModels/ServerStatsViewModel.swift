import SwiftUI
import Combine
import AevonXCoreBridge

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

    /// Number of known server services detected
    @Published private(set) var serviceCount: Int = 0

    /// CPU model name (e.g., "AMD EPYC-Genoa Processor")
    @Published private(set) var cpuModelName: String = ""

    /// Per-core CPU load percentages (0-100)
    @Published private(set) var cpuCoreLoads: [Double] = []

    /// CPU time breakdown percentages (from two /proc/stat samples)
    @Published private(set) var cpuUserPct: Double = 0
    @Published private(set) var cpuSystemPct: Double = 0
    @Published private(set) var cpuIowaitPct: Double = 0
    @Published private(set) var cpuIdlePct: Double = 0
    @Published private(set) var cpuStealPct: Double = 0

    /// Total process count
    @Published private(set) var processesTotal: Int = 0

    /// Running process count
    @Published private(set) var processesRunning: Int = 0

    /// Available RAM in MB
    @Published private(set) var ramAvailableMB: Int = 0

    /// Buff/Cache combined in MB
    @Published private(set) var ramBuffCacheMB: Int = 0

    /// Real-time network receive speed (KB/s)
    @Published private(set) var netRxSpeedKBs: Double = 0

    /// Real-time network transmit speed (KB/s)
    @Published private(set) var netTxSpeedKBs: Double = 0

    /// RX speed history for sparklines
    @Published private(set) var netRxSpeedHistory: [Double] = []

    /// TX speed history for sparklines
    @Published private(set) var netTxSpeedHistory: [Double] = []

    /// Whether per-core CPU detail is being fetched
    @Published private(set) var isFetchingCPUDetail: Bool = false

    /// Total installed RAM in MB (0 = unknown)
    @Published private(set) var totalRAMMB: Int = 0

    /// Used RAM in MB
    @Published private(set) var usedRAMMB: Int = 0

    /// Total disk size in GB
    @Published private(set) var totalDiskGB: Double = 0

    /// Used disk in GB
    @Published private(set) var usedDiskGB: Double = 0

    /// Number of CPU cores (0 = unknown)
    @Published private(set) var cpuCores: Int = 0

    /// Swap usage percentage (0-100)
    @Published private(set) var swapUsage: Double = 0

    /// Total swap in MB
    @Published private(set) var swapTotalMB: Int = 0

    /// Used swap in MB
    @Published private(set) var swapUsedMB: Int = 0

    /// Total network received in GB (since boot)
    @Published private(set) var netRxGB: Double = 0

    /// Total network transmitted in GB (since boot)
    @Published private(set) var netTxGB: Double = 0
    
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

    /// Previous netRxGB for speed calculation (-1 = uninitialized)
    private var prevNetRxGB: Double = -1

    /// Previous netTxGB for speed calculation (-1 = uninitialized)
    private var prevNetTxGB: Double = -1

    /// Time of previous poll for speed calculation
    private var prevPollDate: Date?

    /// Whether the app is in foreground
    private var isInForeground: Bool = true

    /// Whether the overview tab is currently visible (controls polling speed)
    var isOverviewVisible: Bool = true
    
    // MARK: - Initialization
    
    init(serverId: String) {
        self.serverId = serverId
        
        // Initialize history arrays
        self.cpuUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.memoryUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.diskUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.temperatureHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.netRxSpeedHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        self.netTxSpeedHistory = Array(repeating: 0.0, count: maxHistoryPoints)
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
                    // Sleep longer when backgrounded to save energy
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s when background
                    continue
                }

                // Adaptive: poll at normal rate when overview visible, 4x slower otherwise
                let interval = self.isOverviewVisible
                    ? self.pollingInterval
                    : self.pollingInterval * 4

                await self.refreshStats()

                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
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
        
        // Update Memory — only accept non-zero values (Swift SSH fallback may have set it)
        if let mem = stats["memory"] as? Double, mem > 0 {
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

        // Update RAM totals — only accept non-zero values (Swift SSH may have set valid data)
        if let ramTotal = stats["ram_total_mb"] as? Int, ramTotal > 0 { totalRAMMB = ramTotal }
        if let ramUsed = stats["ram_used_mb"] as? Int, ramUsed > 0 { usedRAMMB = ramUsed }

        // Update Disk totals — only accept non-zero values
        if let diskTotal = stats["disk_total_gb"] as? Double, diskTotal > 0 { totalDiskGB = diskTotal }
        if let diskUsed = stats["disk_used_gb"] as? Double, diskUsed > 0 { usedDiskGB = diskUsed }

        // Update CPU Cores
        if let cores = stats["cpu_cores"] as? Int { cpuCores = cores }

        // Update Swap — only accept non-zero totals
        if let swapTotal = stats["swap_total_mb"] as? Int, swapTotal > 0 {
            swapTotalMB = swapTotal
            if let swapUsed = stats["swap_used_mb"] as? Int { swapUsedMB = swapUsed }
            if let swapPct = stats["swap_pct"] as? Double { swapUsage = swapPct }
        }

        // Update Network I/O — only accept non-zero values
        if let rx = stats["net_rx_mb"] as? Double, rx > 0 { netRxGB = rx }
        if let tx = stats["net_tx_mb"] as? Double, tx > 0 { netTxGB = tx }

        // Update RAM detail from Go stats
        if let avail = stats["ram_avail_mb"] as? Int, avail > 0 { ramAvailableMB = avail }
        if let buffcache = stats["ram_buff_cache_mb"] as? Int, buffcache > 0 { ramBuffCacheMB = buffcache }

        // Update CPU model from Go stats
        if let model = stats["cpu_model"] as? String, !model.isEmpty { cpuModelName = model }

        // Calculate real-time traffic speeds from delta between polls
        let now = Date()
        if let prevDate = prevPollDate, prevNetRxGB >= 0, prevNetTxGB >= 0 {
            let elapsed = now.timeIntervalSince(prevDate)
            if elapsed >= 0.5 {
                let rxDeltaMB = max(0, (netRxGB - prevNetRxGB) * 1024.0)
                let txDeltaMB = max(0, (netTxGB - prevNetTxGB) * 1024.0)
                netRxSpeedKBs = rxDeltaMB * 1024.0 / elapsed
                netTxSpeedKBs = txDeltaMB * 1024.0 / elapsed
                updateHistory(&netRxSpeedHistory, with: netRxSpeedKBs)
                updateHistory(&netTxSpeedHistory, with: netTxSpeedKBs)
            }
        }
        prevNetRxGB = netRxGB
        prevNetTxGB = netTxGB
        prevPollDate = now
    }

    
    /// Set hardware specs fetched via direct SSH (called from ServerConnectionViewModel on connect).
    /// This ensures values display immediately, independent of the Go stats poll cycle.
    func applyHardwareSpecs(totalRAMMB: Int, usedRAMMB: Int, totalDiskGB: Double, usedDiskGB: Double, cpuCores: Int, ramAvailableMB: Int = 0, ramBuffCacheMB: Int = 0, cpuModelName: String = "") {
        if totalRAMMB > 0 { self.totalRAMMB = totalRAMMB }
        if usedRAMMB > 0  { self.usedRAMMB  = usedRAMMB  }
        if totalDiskGB > 0 { self.totalDiskGB = totalDiskGB }
        if usedDiskGB > 0  { self.usedDiskGB  = usedDiskGB  }
        if cpuCores > 0    { self.cpuCores    = cpuCores    }
        if ramAvailableMB > 0 { self.ramAvailableMB = ramAvailableMB }
        if ramBuffCacheMB > 0 { self.ramBuffCacheMB = ramBuffCacheMB }
        if !cpuModelName.isEmpty { self.cpuModelName = cpuModelName }

        // Always calculate percentages from absolute values
        if totalRAMMB > 0 && usedRAMMB > 0 {
            memoryUsage = Double(usedRAMMB) * 100.0 / Double(totalRAMMB)
            updateHistory(&memoryUsageHistory, with: memoryUsage)
        }
        if totalDiskGB > 0 && usedDiskGB > 0 {
            diskUsage = usedDiskGB * 100.0 / totalDiskGB
            updateHistory(&diskUsageHistory, with: diskUsage)
        }
    }

    /// Set network totals from Swift SSH — always update when valid data arrives.
    func applyNetworkTotals(rxGB: Double, txGB: Double) {
        if rxGB > 0 { netRxGB = rxGB }
        if txGB > 0 { netTxGB = txGB }
    }

    /// Set swap info from Swift SSH — always update when valid data arrives.
    func applySwapInfo(totalMB: Int, usedMB: Int) {
        if totalMB > 0 {
            swapTotalMB = totalMB
            swapUsedMB = usedMB
            swapUsage = Double(usedMB) * 100.0 / Double(totalMB)
        }
    }

    // MARK: - On-Demand CPU Detail Fetch

    /// Fetch per-core CPU loads using two /proc/stat samples 250ms apart.
    /// Also fetches process counts. Safe to call from hover handlers.
    func fetchCPUCores() async {
        guard SSHBridge.shared.isConnected(serverID: serverId) else { return }
        guard !isFetchingCPUDetail else { return }

        isFetchingCPUDetail = true
        defer { isFetchingCPUDetail = false }

        // First sample + process count in parallel
        async let stat1Future = SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "grep '^cpu' /proc/stat 2>/dev/null"
        )
        async let procFuture = SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "echo \"$(ps -e --no-header 2>/dev/null | wc -l | tr -d ' ') $(ps -eo stat --no-header 2>/dev/null | grep -c '^R' 2>/dev/null || echo 0)\""
        )

        let (s1, procOut) = await (stat1Future, procFuture)

        // 250ms gap between samples
        try? await Task.sleep(nanoseconds: 250_000_000)

        // Second sample
        let s2 = await SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "grep '^cpu' /proc/stat 2>/dev/null"
        )

        // Parse process counts
        let procParts = procOut.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").map(String.init)
        processesTotal   = Int(procParts.first ?? "0") ?? 0
        processesRunning = Int(procParts.dropFirst().first ?? "0") ?? 0

        // Parse per-core loads from delta
        let cores1 = parseProcStatLines(s1)
        let cores2 = parseProcStatLines(s2)

        var loads: [Double] = []
        for (i, c1) in cores1.enumerated() {
            guard i < cores2.count else { continue }
            let c2 = cores2[i]
            let totalDiff = c2.total - c1.total
            let idleDiff  = c2.idle  - c1.idle
            let load = totalDiff > 0
                ? max(0, min(100, Double(totalDiff - idleDiff) * 100.0 / Double(totalDiff)))
                : 0

            if c1.isOverall {
                // Overall CPU breakdown
                if totalDiff > 0 {
                    let td = Double(totalDiff)
                    cpuUserPct   = Double(c2.user   - c1.user)   * 100 / td
                    cpuSystemPct = Double(c2.sys    - c1.sys)    * 100 / td
                    cpuIowaitPct = Double(c2.iowait - c1.iowait) * 100 / td
                    cpuIdlePct   = Double(c2.idle   - c1.idle)   * 100 / td
                    cpuStealPct  = Double(c2.steal  - c1.steal)  * 100 / td
                }
            } else {
                loads.append(load)
            }
        }
        cpuCoreLoads = loads
    }

    private struct ProcStatEntry {
        let isOverall: Bool
        let total: Int
        let idle: Int
        let user: Int
        let sys: Int
        let iowait: Int
        let steal: Int
    }

    private func parseProcStatLines(_ output: String) -> [ProcStatEntry] {
        output.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("cpu") else { return nil }
            let parts = trimmed.split(separator: " ")
            guard parts.count >= 5 else { return nil }
            let name = String(parts[0])
            let isOverall = (name == "cpu")
            let nums = parts.dropFirst().compactMap { Int($0) }
            guard nums.count >= 4 else { return nil }
            let user   = nums[0]
            let nice   = nums[1]
            let sys    = nums[2]
            let idle   = nums[3]
            let iowait = nums.count > 4 ? nums[4] : 0
            let irq    = nums.count > 5 ? nums[5] : 0
            let softirq = nums.count > 6 ? nums[6] : 0
            let steal  = nums.count > 7 ? nums[7] : 0
            let total  = user + nice + sys + idle + iowait + irq + softirq + steal
            return ProcStatEntry(
                isOverall: isOverall,
                total: total,
                idle: idle + iowait,
                user: user + nice,
                sys: sys,
                iowait: iowait,
                steal: steal
            )
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
        totalRAMMB = 0
        usedRAMMB = 0
        totalDiskGB = 0
        usedDiskGB = 0
        cpuCores = 0
        swapUsage = 0
        swapTotalMB = 0
        swapUsedMB = 0
        netRxGB = 0
        netTxGB = 0
        cpuModelName = ""
        cpuCoreLoads = []
        cpuUserPct = 0; cpuSystemPct = 0; cpuIowaitPct = 0; cpuIdlePct = 0; cpuStealPct = 0
        processesTotal = 0; processesRunning = 0
        ramAvailableMB = 0; ramBuffCacheMB = 0
        netRxSpeedKBs = 0; netTxSpeedKBs = 0
        prevNetRxGB = -1; prevNetTxGB = -1; prevPollDate = nil
        cpuUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        memoryUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        diskUsageHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        temperatureHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        netRxSpeedHistory = Array(repeating: 0.0, count: maxHistoryPoints)
        netTxSpeedHistory = Array(repeating: 0.0, count: maxHistoryPoints)
    }
    
    // MARK: - History Helper
    
    private func updateHistory(_ history: inout [Double], with value: Double) {
        history.append(value)
        if history.count > maxHistoryPoints {
            history.removeFirst()
        }
    }
}
