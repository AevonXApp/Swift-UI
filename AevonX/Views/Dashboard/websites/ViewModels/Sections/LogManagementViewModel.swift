//
//  LogManagementViewModel.swift
//  AevonX
//
//  ViewModel for Log Management section with structured log display
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
public final class LogManagementViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var selectedLogType: LogType = .access
    @Published public var accessLogs: [AccessLogEntry] = []
    @Published public var errorLogs: [ErrorLogEntry] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String?

    // Filtering
    @Published public var filters: LogFilters = LogFilters()
    @Published public var showFilterSheet: Bool = false
    @Published public var searchKeyword: String = ""

    // Pagination
    @Published public var currentLimit: Int = 100
    @Published public var hasMore: Bool = false

    // Auto-refresh
    @Published public var autoRefreshEnabled: Bool = false

    // Export
    @Published public var showExportSheet: Bool = false
    @Published public var selectedExportFormat: ExportFormat = .csv

    private let website: WebsiteInfo
    private let serverId: String?
    private let logService = WebsiteLogService.shared
    private let toastManager = GlobalToastManager.shared

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

        // Apply search keyword to filters
        if !searchKeyword.isEmpty {
            filters.keyword = searchKeyword
        }

        do {
            switch selectedLogType {
            case .access:
                accessLogs = try await logService.getAccessLogs(
                    domain: website.domain,
                    serverId: serverId,
                    limit: currentLimit,
                    filters: filters.hasActiveFilters ? filters : nil
                )
                hasMore = accessLogs.count >= currentLimit

            case .error:
                errorLogs = try await logService.getErrorLogs(
                    domain: website.domain,
                    serverId: serverId,
                    limit: currentLimit,
                    filters: filters.hasActiveFilters ? filters : nil
                )
                hasMore = errorLogs.count >= currentLimit

            case .system, .application:
                // These would need additional Core methods
                toastManager.showInfo("\(selectedLogType.rawValue) logs not yet implemented")
            }
        } catch {
            self.error = "Failed to load logs: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoading = false
    }

    // MARK: - Log Type Selection

    public func changeLogType(_ newType: LogType) async {
        selectedLogType = newType
        await load()
    }

    // MARK: - Filtering

    public func applyFilters(_ newFilters: LogFilters) async {
        filters = newFilters
        await load()
    }

    public func clearFilters() async {
        filters = LogFilters()
        searchKeyword = ""
        await load()
    }

    public func updateSearchKeyword(_ keyword: String) async {
        searchKeyword = keyword
        filters.keyword = keyword.isEmpty ? nil : keyword
        await load()
    }

    // MARK: - Pagination

    public func loadMore() async {
        currentLimit += 100
        await load()
    }

    public func reset() async {
        currentLimit = 100
        await load()
    }

    // MARK: - Auto Refresh

    public func startAutoRefresh() {
        guard autoRefreshEnabled else { return }

        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
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

    // MARK: - Export

    public func exportLogs() async {
        guard serverId != nil else { return }
        // This would need a Core method to export logs
        toastManager.showInfo("Export functionality coming soon")
    }

    // MARK: - Computed Properties

    public var currentLogCount: Int {
        switch selectedLogType {
        case .access:
            return accessLogs.count
        case .error:
            return errorLogs.count
        case .system, .application:
            return 0
        }
    }

    public var hasActiveFilters: Bool {
        filters.hasActiveFilters || !searchKeyword.isEmpty
    }

    public var activeFilterCount: Int {
        filters.activeFilterCount
    }

    // MARK: - Statistics

    public var errorCount: Int {
        accessLogs.filter { $0.isError }.count
    }

    public var errorPercentage: Double {
        guard !accessLogs.isEmpty else { return 0 }
        return (Double(errorCount) / Double(accessLogs.count)) * 100.0
    }

    public var topStatusCodes: [(Int, Int)] {
        var counts: [Int: Int] = [:]
        for log in accessLogs {
            counts[log.statusCode, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    public var topIPs: [(String, Int)] {
        var counts: [String: Int] = [:]
        for log in accessLogs {
            counts[log.ip, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }

    // MARK: - Helpers

    public func clearError() {
        error = nil
    }

    public func refresh() async {
        await load()
    }
}
