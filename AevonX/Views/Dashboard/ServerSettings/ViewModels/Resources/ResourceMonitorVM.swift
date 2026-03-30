//
//  ResourceMonitorVM.swift
//  AevonX
//
//  ViewModel for real-time server resource monitoring.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class ResourceMonitorVM: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - CPU
    @Published var cpuPercent: Double = 0
    @Published var cpuCores: Int = 0

    // MARK: - Load Average
    @Published var loadAvg1: Double = 0
    @Published var loadAvg5: Double = 0
    @Published var loadAvg15: Double = 0

    // MARK: - RAM (bytes)
    @Published var ramTotal: UInt64 = 0
    @Published var ramUsed: UInt64 = 0
    @Published var ramFree: UInt64 = 0
    @Published var ramCached: UInt64 = 0
    @Published var ramBuffers: UInt64 = 0

    // MARK: - Swap (bytes)
    @Published var swapTotal: UInt64 = 0
    @Published var swapUsed: UInt64 = 0

    // MARK: - IO
    @Published var ioWait: Double = 0
    @Published var processCount: Int = 0

    // MARK: - Processes
    @Published var topCPUProcesses: [ServerProcessInfo] = []
    @Published var topMemProcesses: [ServerProcessInfo] = []
    @Published var sortMode: ProcessSortMode = .cpu

    // MARK: - Network I/O
    @Published var networkRxRate: Double = 0
    @Published var networkTxRate: Double = 0

    // MARK: - Disk I/O
    @Published var diskReadSectors: UInt64 = 0
    @Published var diskWriteSectors: UInt64 = 0

    // MARK: - Temperature
    @Published var cpuTemp: Double? = nil

    // MARK: - Disk (enhanced)
    @Published var diskPartitions: [DiskPartitionInfo] = []

    // MARK: - History (for MiniCharts)
    @Published var cpuHistory: [Double] = []
    @Published var ramHistory: [Double] = []

    // MARK: - State
    @Published var isLoading = true
    @Published var autoRefreshInterval: Int = 10
    @Published var isAutoRefreshing = false

    var refreshTask: Task<Void, Never>?
    var prevNetRx: UInt64 = 0
    var prevNetTx: UInt64 = 0
    var prevNetTime: Date?

    var isConnected: Bool {
        SSHBridge.shared.isConnected(serverID: serverId)
    }

    var ramPercent: Double {
        guard ramTotal > 0 else { return 0 }
        return Double(ramUsed) / Double(ramTotal) * 100
    }

    var swapPercent: Double {
        guard swapTotal > 0 else { return 0 }
        return Double(swapUsed) / Double(swapTotal) * 100
    }

    var loadNormalized: Double {
        guard cpuCores > 0 else { return 0 }
        return loadAvg1 / Double(cpuCores)
    }

    var displayedProcesses: [ServerProcessInfo] {
        sortMode == .cpu ? topCPUProcesses : topMemProcesses
    }

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - SSH

    func ssh(_ cmd: String) async -> String {
        guard !cmd.isEmpty else { return "" }
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: cmd)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Auto-Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        guard autoRefreshInterval > 0 else { return }
        isAutoRefreshing = true
        refreshTask = Task {
            while !Task.isCancelled {
                await loadResourceSnapshot()
                try? await Task.sleep(nanoseconds: UInt64(autoRefreshInterval) * 1_000_000_000)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
        isAutoRefreshing = false
    }

    func loadResourceSnapshot() async {
        guard isConnected else { isLoading = false; return }
        let cmd = await service.resourceSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseSnapshot(sections)
        isLoading = false
    }

    func killProcess(_ pid: Int) async {
        guard pid > 1 else { return }
        let cmd = await service.killProcessCmd(pid: Int32(pid))
        let _ = await ssh(cmd)
        await loadResourceSnapshot()
    }
}
