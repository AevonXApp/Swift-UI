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
            // Load statistics
            group.addTask { @MainActor in
                do {
                    let cmd = self.bridge.requestStatsCmd(domain: self.website.domain, timeRange: self.selectedTimeRange.rawValue)
                    let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                    let parsedJSON = self.bridge.parseRequestStats(output: result)

                    if let data = parsedJSON.data(using: .utf8),
                       let json = try? JSONDecoder().decode(RequestStatistics.self, from: data) {
                        self.statistics = json
                    }
                } catch {
                    CoreLogger.shared.debug("Failed to load statistics: \(error)", module: "TrafficAnalytics")
                }
            }

            // Load bandwidth data
            group.addTask { @MainActor in
                do {
                    let logPath = "\(self.serverPaths.logDir)/\(self.website.domain).access.log"
                    let cmd = self.bridge.bandwidthCmd(logPath: logPath)
                    let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                    let parsedJSON = self.bridge.parseBandwidth(output: result)

                    if let data = parsedJSON.data(using: .utf8),
                       let points = try? JSONDecoder().decode([BandwidthDataPoint].self, from: data) {
                        self.bandwidthData = points
                    }
                } catch {
                    CoreLogger.shared.debug("Failed to load bandwidth data: \(error)", module: "TrafficAnalytics")
                }
            }

            // Load top endpoints
            group.addTask { @MainActor in
                do {
                    let cmd = self.bridge.topEndpointsCmd(domain: self.website.domain, limit: 10)
                    let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
                    let parsedJSON = self.bridge.parseTopEndpoints(output: result)

                    if let data = parsedJSON.data(using: .utf8),
                       let endpoints = try? JSONDecoder().decode([EndpointStat].self, from: data) {
                        self.topEndpoints = endpoints
                    }
                } catch {
                    CoreLogger.shared.debug("Failed to load top endpoints: \(error)", module: "TrafficAnalytics")
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

    private func detectPathsIfNeeded() async {
        guard !pathsDetected, let serverId = serverId else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
