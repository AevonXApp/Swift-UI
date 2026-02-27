//
//  MonitoringViewModel.swift
//  AevonX
//
//  ViewModel for per-site monitoring — delegates to SiteMonitoringService
//

import SwiftUI
import Combine
import AevonXCore

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
    private let service = SiteMonitoringService.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        await runHealthCheck()
        await loadTraffic()
    }

    func runHealthCheck() async {
        do {
            let result = try await service.runHealthCheck(domain: domain, serverId: serverId)
            healthCheck = SiteHealthCheck(
                timestamp: Date(),
                httpStatus: result.httpStatus,
                responseTime: result.responseTime,
                sslDaysRemaining: result.sslDaysRemaining,
                dnsResolved: result.dnsResolved,
                isUp: result.isUp
            )
        } catch {
            healthCheck = SiteHealthCheck(timestamp: Date(), httpStatus: nil, responseTime: nil, sslDaysRemaining: nil, dnsResolved: false, isUp: false)
        }
    }

    private func loadTraffic() async {
        do {
            let analytics = try await service.analyzeTraffic(domain: domain, serverId: serverId)
            let totalRequests = analytics.topURLs.reduce(0) { $0 + $1.count }

            topURLs = analytics.topURLs.map { entry in
                TopURLEntry(url: entry.value, count: entry.count, percentage: totalRequests > 0 ? Double(entry.count) / Double(totalRequests) * 100 : 0)
            }
            topIPs = analytics.topIPs.map { TopIPEntry(ip: $0.value, count: $0.count, country: nil) }

            let totalStatus = analytics.statusCodes.reduce(0) { $0 + $1.count }
            statusCodes = analytics.statusCodes.map { entry in
                let code = Int(entry.value) ?? 0
                return StatusCodeEntry(
                    code: code,
                    count: entry.count,
                    percentage: totalStatus > 0 ? Double(entry.count) / Double(totalStatus) * 100 : 0
                )
            }

            botTraffic = analytics.botTraffic.map { BotTrafficEntry(botName: $0.value, requestCount: $0.count, percentage: 0, isKnownGood: $0.value.lowercased().contains("google") || $0.value.lowercased().contains("bing")) }

            bandwidth = SiteBandwidthData(totalBytes: analytics.totalBandwidthBytes, period: "Total")
        } catch {
            // Silent fail for analytics
        }
    }
}
