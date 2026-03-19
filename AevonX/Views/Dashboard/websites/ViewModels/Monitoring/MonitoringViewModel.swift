//
//  MonitoringViewModel.swift
//  AevonX
//
//  ViewModel for per-site monitoring — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class MonitoringViewModel: ObservableObject {
    @Published var selectedTab: MonitoringTab = .health
    @Published var healthCheck: SiteHealthCheck?
    @Published var topURLs: [TopURLEntry] = []
    @Published var topIPs: [TopIPEntry] = []
    @Published var statusCodes: [StatusCodeEntry] = []
    @Published var botTraffic: [BotTrafficEntry] = []
    @Published var bandwidth: SiteBandwidthData?
    @Published var isLoading = false

    let serverId: String
    let domain: String
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        await detectPathsIfNeeded()
        await runHealthCheck()
        await loadTraffic()
    }

    func runHealthCheck() async {
        let cmd = bridge.healthCheckCmd(domain: domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseHealthCheck(output: result)

        if let data = parsedJSON.data(using: String.Encoding.utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let hc = resp["data"] as? [String: Any] {
            healthCheck = SiteHealthCheck(
                timestamp: Date(),
                httpStatus: hc["http_status"] as? Int,
                responseTime: hc["response_time"] as? Double,
                sslDaysRemaining: hc["ssl_days_remaining"] as? Int,
                dnsResolved: hc["dns_resolved"] as? Bool ?? false,
                isUp: hc["is_up"] as? Bool ?? false
            )
        } else {
            healthCheck = SiteHealthCheck(timestamp: Date(), httpStatus: nil, responseTime: nil, sslDaysRemaining: nil, dnsResolved: false, isUp: false)
        }
    }

    private func loadTraffic() async {
        let logPath = "\(serverPaths.logDir)/\(domain).access.log"
        let cmd = bridge.analyzeTrafficCmd(domain: domain, logPath: logPath)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseTrafficAnalysis(output: result)

        if let data = parsedJSON.data(using: String.Encoding.utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let analytics = resp["data"] as? [String: Any] {

            // Top URLs
            if let urls = analytics["top_urls"] as? [[String: Any]] {
                let totalReqs = urls.reduce(0) { $0 + ($1["count"] as? Int ?? 0) }
                topURLs = urls.compactMap { (dict: [String: Any]) -> TopURLEntry? in
                    guard let url = dict["value"] as? String, let count = dict["count"] as? Int else { return nil }
                    return TopURLEntry(url: url, count: count, percentage: totalReqs > 0 ? Double(count) / Double(totalReqs) * 100 : 0)
                }
            }

            // Top IPs
            if let ips = analytics["top_ips"] as? [[String: Any]] {
                topIPs = ips.compactMap { (dict: [String: Any]) -> TopIPEntry? in
                    guard let ip = dict["value"] as? String, let count = dict["count"] as? Int else { return nil }
                    return TopIPEntry(ip: ip, count: count, country: nil)
                }
            }

            // Status codes
            if let codes = analytics["status_codes"] as? [[String: Any]] {
                let totalStatus = codes.reduce(0) { $0 + ($1["count"] as? Int ?? 0) }
                statusCodes = codes.compactMap { (dict: [String: Any]) -> StatusCodeEntry? in
                    guard let codeStr = dict["value"] as? String, let count = dict["count"] as? Int else { return nil }
                    let code = Int(codeStr) ?? 0
                    return StatusCodeEntry(code: code, count: count, percentage: totalStatus > 0 ? Double(count) / Double(totalStatus) * 100 : 0)
                }
            }

            // Bot traffic
            if let bots = analytics["bot_traffic"] as? [[String: Any]] {
                botTraffic = bots.compactMap { (dict: [String: Any]) -> BotTrafficEntry? in
                    guard let bot = dict["value"] as? String, let count = dict["count"] as? Int else { return nil }
                    return BotTrafficEntry(botName: bot, requestCount: count, percentage: 0, isKnownGood: bot.lowercased().contains("google") || bot.lowercased().contains("bing"))
                }
            }

            // Bandwidth
            if let totalBytes = analytics["total_bandwidth_bytes"] as? Int64 {
                bandwidth = SiteBandwidthData(totalBytes: totalBytes, period: "Total")
            }
        }
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
