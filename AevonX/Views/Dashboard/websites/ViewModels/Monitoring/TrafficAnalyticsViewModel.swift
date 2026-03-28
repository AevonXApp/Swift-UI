//
//  TrafficAnalyticsViewModel.swift
//  AevonX
//
//  ViewModel for Traffic Analytics section — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
public final class TrafficAnalyticsViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var statistics: RequestStatistics?
    @Published public var bandwidthData: [BandwidthDataPoint] = []
    @Published public var topEndpoints: [EndpointStat] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String?

    @Published public var selectedTimeRange: TimeRange = .last24Hours
    @Published public var autoRefreshEnabled: Bool = true

    private let website: WebsiteInfo
    private let serverId: String?
    private let bridge = WebsitesBridge.shared
    private let toastManager = GlobalToastManager.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    private var autoRefreshTimer: Timer?

    // MARK: - Initialization

    public init(website: WebsiteInfo, serverId: String?) {
        self.website = website
        self.serverId = serverId
    }

    nonisolated deinit {
        autoRefreshTimer?.invalidate()
    }

    // MARK: - Data Loading

    public func load() async {
        guard let serverId = serverId else {
            error = "No server ID available"
            return
        }

        isLoading = true
        error = nil

        await detectPathsIfNeeded()

        await withTaskGroup(of: Void.self) { group in
            // Load request statistics — Go outputs "  count statusCode" lines
            group.addTask { @MainActor in
                let logPath = "\(self.serverPaths.logDir)/\(self.website.domain).access.log"
                let cmd = self.bridge.requestStatsCmd(domain: self.website.domain, timeRange: self.selectedTimeRange.rawValue, logPath: logPath)
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                let entries = self.parseCountValueLines(result)
                let totalReqs = entries.reduce(0) { $0 + $1.0 }
                var byStatus: [String: Int] = [:]
                var errorCount = 0
                for (count, code) in entries {
                    byStatus[code] = count
                    if let codeInt = Int(code), codeInt >= 400 {
                        errorCount += count
                    }
                }
                let errorRate = totalReqs > 0 ? Double(errorCount) / Double(totalReqs) * 100.0 : 0
                self.statistics = RequestStatistics(
                    totalRequests: totalReqs,
                    requestsByStatus: byStatus,
                    errorRate: errorRate,
                    timeRange: self.selectedTimeRange,
                    timestamp: Date()
                )
            }

            // Load bandwidth — Go outputs single integer (total bytes)
            group.addTask { @MainActor in
                let logPath = "\(self.serverPaths.logDir)/\(self.website.domain).access.log"
                let cmd = self.bridge.bandwidthCmd(logPath: logPath)
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if let totalBytes = Int(trimmed), totalBytes > 0 {
                    self.bandwidthData = [
                        BandwidthDataPoint(timestamp: Date(), bytesIn: 0, bytesOut: totalBytes)
                    ]
                }
            }

            // Load top endpoints — Go outputs "  count /path" lines
            group.addTask { @MainActor in
                let logPath = "\(self.serverPaths.logDir)/\(self.website.domain).access.log"
                let cmd = self.bridge.topEndpointsCmd(domain: self.website.domain, limit: 10, logPath: logPath)
                let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                let entries = self.parseCountValueLines(result)
                self.topEndpoints = entries.map { count, path in
                    EndpointStat(endpoint: path, requestCount: count, averageResponseTime: 0, errorCount: 0)
                }
            }
        }

        isLoading = false
    }

    // MARK: - Time Range

    public func changeTimeRange(_ newRange: TimeRange) async {
        selectedTimeRange = newRange
        await load()
    }

    // MARK: - Auto Refresh

    public func startAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        
        guard autoRefreshEnabled else { return }

        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.load()
            }
        }
    }

    public func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }

    public func toggleAutoRefresh() {
        autoRefreshEnabled.toggle()
        if autoRefreshEnabled {
            startAutoRefresh()
        } else {
            stopAutoRefresh()
        }
    }

    // MARK: - Computed Properties

    public var totalRequests: Int {
        statistics?.totalRequests ?? 0
    }

    public var successRate: Double {
        statistics?.successRate ?? 0
    }

    public var errorRate: Double {
        statistics?.errorRate ?? 0
    }

    public var averageResponseTime: String {
        statistics?.formattedResponseTime ?? "N/A"
    }

    public var totalBandwidth: String {
        let total = bandwidthData.reduce(0) { $0 + $1.totalBytes }
        return AXFormatter.formatBytes(Int64(total))
    }

    public var topRequestMethod: String? {
        statistics?.topMethod
    }

    // MARK: - Chart Data

    public var requestsByMethodData: [(String, Int)] {
        statistics?.requestsByMethod.sorted { $0.value > $1.value } ?? []
    }

    public var requestsByStatusData: [(String, Int)] {
        statistics?.requestsByStatus.sorted { $0.key < $1.key } ?? []
    }

    // MARK: - Helpers

    public func clearError() {
        error = nil
    }

    public func refresh() async {
        await load()
    }

    /// Parse "  count value" lines from uniq -c output.
    private func parseCountValueLines(_ output: String) -> [(Int, String)] {
        output.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count == 2, let count = Int(parts[0]) else { return nil }
            return (count, String(parts[1]))
        }
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected, let serverId = serverId else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
