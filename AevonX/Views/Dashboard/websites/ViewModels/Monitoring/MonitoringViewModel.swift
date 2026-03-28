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
        // Health check command outputs: "200 0.543" (http_code space time_total)
        let cmd = bridge.healthCheckCmd(domain: domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", maxSplits: 1)

        if parts.count >= 2,
           let httpCode = Int(parts[0]),
           let responseTime = Double(parts[1]) {
            let isUp = httpCode >= 200 && httpCode < 500
            healthCheck = SiteHealthCheck(
                timestamp: Date(),
                httpStatus: httpCode,
                responseTime: responseTime,
                sslDaysRemaining: nil,
                dnsResolved: isUp,
                isUp: isUp
            )
        } else if parts.count == 1, let httpCode = Int(parts[0]) {
            let isUp = httpCode >= 200 && httpCode < 500
            healthCheck = SiteHealthCheck(
                timestamp: Date(),
                httpStatus: httpCode,
                responseTime: nil,
                sslDaysRemaining: nil,
                dnsResolved: isUp,
                isUp: isUp
            )
        } else {
            healthCheck = SiteHealthCheck(timestamp: Date(), httpStatus: nil, responseTime: nil, sslDaysRemaining: nil, dnsResolved: false, isUp: false)
        }
    }

    private func loadTraffic() async {
        // Go AnalyzeTrafficCmd outputs sections like:
        // === TOP_URLS ===
        //   15 /index.html
        // === TOP_IPS ===
        //   20 1.2.3.4
        // === STATUS_CODES ===
        //   40 200
        let logPath = "\(serverPaths.logDir)/\(domain).access.log"
        let cmd = bridge.analyzeTrafficCmd(domain: domain, logPath: logPath)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)

        let sections = parseTrafficSections(result)

        // Top URLs
        if let urlLines = sections["TOP_URLS"] {
            let entries = parseCountValueLines(urlLines)
            let total = entries.reduce(0) { $0 + $1.0 }
            topURLs = entries.map { count, value in
                TopURLEntry(url: value, count: count, percentage: total > 0 ? Double(count) / Double(total) * 100 : 0)
            }
        }

        // Top IPs
        if let ipLines = sections["TOP_IPS"] {
            let entries = parseCountValueLines(ipLines)
            topIPs = entries.map { count, value in
                TopIPEntry(ip: value, count: count, country: nil)
            }
        }

        // Status codes
        if let codeLines = sections["STATUS_CODES"] {
            let entries = parseCountValueLines(codeLines)
            let total = entries.reduce(0) { $0 + $1.0 }
            statusCodes = entries.map { count, value in
                StatusCodeEntry(code: Int(value) ?? 0, count: count, percentage: total > 0 ? Double(count) / Double(total) * 100 : 0)
            }
        }
    }

    /// Parse sectioned output: "=== SECTION ===" followed by "  count value" lines.
    private func parseTrafficSections(_ output: String) -> [String: [String]] {
        var sections: [String: [String]] = [:]
        var currentSection: String?
        for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("===") && trimmed.hasSuffix("===") {
                let name = trimmed.replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = name
                sections[name] = []
            } else if let section = currentSection, !trimmed.isEmpty {
                sections[section, default: []].append(trimmed)
            }
        }
        return sections
    }

    /// Parse "  count value" lines from uniq -c output.
    private func parseCountValueLines(_ lines: [String]) -> [(Int, String)] {
        lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count == 2, let count = Int(parts[0]) else { return nil }
            return (count, String(parts[1]))
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
