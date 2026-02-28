//
//  AXLogsViewModel.swift
//  AevonX
//
//  ViewModel for AXAdvancedLogsView — handles data loading,
//  filtering, sorting, and actions (block IP, clear logs).
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
public final class AXLogsViewModel: ObservableObject {
    @Published var selectedTab: AXLogTab = .all
    @Published var searchText: String = ""
    @Published var sortOption: AXLogSortOption = .newestFirst
    @Published var statusFilter: Int? = nil
    @Published var isLoading: Bool = false

    @Published var accessLogs: [AXLogEntryDisplay] = []
    @Published var errorLogs: [AXLogEntryDisplay] = []

    @Published var showLogDetail: Bool = false
    @Published var selectedLog: AXLogEntryDisplay? = nil

    @Published var showIPBlockSheet: Bool = false
    @Published var selectedIP: String? = nil

    /// Cached filtered & sorted logs — updated via Combine when inputs change
    @Published var filteredLogs: [AXLogEntryDisplay] = []

    private let source: AXLogSource
    private let serverId: String?
    private var cancellables = Set<AnyCancellable>()

    // Callbacks for UI feedback
    var onSuccess: ((String) -> Void)?
    var onError: ((String) -> Void)?

    // Services
    private let websiteLogService = WebsiteLogService.shared
    private let appManager = ApplicationManager.shared

    public init(
        source: AXLogSource,
        serverId: String?,
        onSuccess: ((String) -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self.source = source
        self.serverId = serverId
        self.onSuccess = onSuccess
        self.onError = onError

        // Set up Combine pipeline to recompute filteredLogs when any input changes
        Publishers.CombineLatest4(
            $selectedTab,
            $searchText.debounce(for: .milliseconds(150), scheduler: RunLoop.main),
            $statusFilter,
            $sortOption
        )
        .combineLatest($accessLogs, $errorLogs)
        .sink { [weak self] _ in
            self?.updateFilteredLogs()
        }
        .store(in: &cancellables)
    }

    var allLogs: [AXLogEntryDisplay] {
        accessLogs + errorLogs
    }

    // MARK: - Filtering & Sorting

    private func updateFilteredLogs() {
        var logs: [AXLogEntryDisplay]

        switch selectedTab {
        case .access: logs = accessLogs
        case .error:  logs = errorLogs
        case .all:    logs = allLogs
        }

        if !searchText.isEmpty {
            logs = logs.filter { log in
                log.urlOrMessage.localizedCaseInsensitiveContains(searchText) ||
                (log.ip?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        if let statusFilter = statusFilter {
            logs = logs.filter { log in
                guard let code = log.statusCode else { return false }
                return code >= statusFilter && code < statusFilter + 100
            }
        }

        switch sortOption {
        case .newestFirst: logs.sort { $0.timestamp > $1.timestamp }
        case .oldestFirst: logs.sort { $0.timestamp < $1.timestamp }
        case .ipAddress:   logs.sort { ($0.ip ?? "") < ($1.ip ?? "") }
        case .statusCode:  logs.sort { ($0.statusCode ?? 0) < ($1.statusCode ?? 0) }
        }

        filteredLogs = logs
    }

    var statusFilterLabel: String {
        guard let filter = statusFilter else { return "All Status" }
        switch filter {
        case 200: return "2xx Success"
        case 300: return "3xx Redirect"
        case 400: return "4xx Error"
        case 500: return "5xx Error"
        default: return "Filter"
        }
    }

    func getCount(for tab: AXLogTab) -> Int {
        switch tab {
        case .access: return accessLogs.count
        case .error:  return errorLogs.count
        case .all:    return allLogs.count
        }
    }

    // MARK: - Load Logs

    func loadLogs() async {
        guard let serverId = serverId else { return }
        isLoading = true

        do {
            switch source {
            case .website(let domain):
                let coreAccess = try await websiteLogService.getAccessLogs(domain: domain, serverId: serverId, limit: 200, filters: nil)
                let coreError = try await websiteLogService.getErrorLogs(domain: domain, serverId: serverId, limit: 200, filters: nil)

                self.accessLogs = coreAccess.map { entry in
                    AXLogEntryDisplay(
                        id: entry.id, type: .access, timestamp: entry.timestamp,
                        ip: entry.ip, method: entry.method, statusCode: entry.statusCode,
                        urlOrMessage: entry.url, userAgent: entry.userAgent,
                        referer: entry.referrer,
                        responseTime: entry.responseTime != nil ? "\(Int(entry.responseTime!))ms" : nil,
                        level: nil, file: nil, line: nil
                    )
                }

                self.errorLogs = coreError.map { entry in
                    AXLogEntryDisplay(
                        id: entry.id, type: .error, timestamp: entry.timestamp,
                        ip: nil, method: nil, statusCode: nil,
                        urlOrMessage: entry.message, userAgent: nil, referer: nil,
                        responseTime: nil, level: entry.level.rawValue,
                        file: entry.file, line: entry.line
                    )
                }

            case .nginxService:
                let rawLogs = try await appManager.readLogs(type: .nginx, lines: 200, serverId: serverId)
                self.accessLogs = parseAccessLevelLogs(rawLogs)
                self.errorLogs = parseErrorLevelLogs(rawLogs)

            case .phpService:
                let rawLogs = try await appManager.readLogs(type: .phpFpm, lines: 200, serverId: serverId)
                self.accessLogs = []
                self.errorLogs = parsePHPErrorLogs(rawLogs)

            case .apacheService:
                let rawLogs = try await appManager.readLogs(type: .apache, lines: 200, serverId: serverId)
                self.accessLogs = parseAccessLevelLogs(rawLogs)
                self.errorLogs = parseErrorLevelLogs(rawLogs)

            case .mysqlService, .postgresqlService, .redisService, .mongodbService, .mariadbService,
                 .cassandraService, .elasticsearchService, .cockroachdbService:
                let appType: ApplicationType
                switch source {
                case .mysqlService:         appType = .mysql
                case .postgresqlService:    appType = .postgresql
                case .redisService:         appType = .redis
                case .mongodbService:       appType = .mongodb
                case .mariadbService:       appType = .mariadb
                case .cassandraService:     appType = .cassandra
                case .elasticsearchService: appType = .elasticsearch
                case .cockroachdbService:   appType = .cockroachdb
                default:                    appType = .unknown
                }

                if appType != .unknown {
                    let rawLogs = try await appManager.readLogs(type: appType, lines: 200, serverId: serverId)
                    self.accessLogs = []
                    self.errorLogs = parseErrorLevelLogs(rawLogs)
                }

            case .genericService(_, _):
                self.accessLogs = []
                self.errorLogs = []
            }
        } catch {
            print("Failed to load logs: \(error)")
        }

        isLoading = false
        updateFilteredLogs()
    }

    // MARK: - Actions

    func blockIP(_ ip: String, reason: String) async {
        guard let serverId = serverId else { return }
        do {
            try await appManager.blockIP(ip, type: .nginx, serverId: serverId)
            onSuccess?("IP \(ip) blocked successfully")
        } catch {
            onError?("Failed to block IP: \(error.localizedDescription)")
        }
    }

    func clearLogs() async {
        guard let serverId = serverId else { return }
        isLoading = true

        do {
            let sshService = SSHService.shared
            let logDir = (try? await ServerPathResolver.shared.nginxLogDir(serverId: serverId)) ?? "/var/log/nginx"

            switch source {
            case .website(let domain):
                let clearCommand = """
                sudo truncate -s 0 \(logDir)/\(domain)-access.log 2>/dev/null; \
                sudo truncate -s 0 \(logDir)/\(domain)-error.log 2>/dev/null; \
                sudo truncate -s 0 \(logDir)/\(domain)-ssl-access.log 2>/dev/null; \
                sudo truncate -s 0 \(logDir)/\(domain)-ssl-error.log 2>/dev/null; \
                echo 'OK'
                """
                _ = try await sshService.execute(clearCommand, serverId: serverId)

            case .nginxService:
                let clearCommand = """
                sudo truncate -s 0 \(logDir)/access.log 2>/dev/null; \
                sudo truncate -s 0 \(logDir)/error.log 2>/dev/null; \
                echo 'OK'
                """
                _ = try await sshService.execute(clearCommand, serverId: serverId)

            default:
                break
            }

            self.accessLogs = []
            self.errorLogs = []
            onSuccess?("Logs cleared successfully")
            await loadLogs()
        } catch {
            onError?("Failed to clear logs: \(error.localizedDescription)")
            isLoading = false
        }
    }

    // MARK: - Parsers

    private func parseAccessLevelLogs(_ raw: String) -> [AXLogEntryDisplay] {
        let lines = raw.components(separatedBy: .newlines)
        var entries: [AXLogEntryDisplay] = []

        let pattern = #"^(\S+) \S+ \S+ \[([\w:/]+\s[+\-]\d{4})\] "(\S+) (\S+) \S+" (\d{3}) (\d+) "([^"]*)" "([^"]*)""#
        let regex = try? NSRegularExpression(pattern: pattern)

        for line in lines {
            guard !line.isEmpty, let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { continue }

            func extract(_ index: Int) -> String? {
                guard let range = Range(match.range(at: index), in: line) else { return nil }
                return String(line[range])
            }

            if let ip = extract(1), let tsStr = extract(2),
               let method = extract(3), let url = extract(4),
               let statusStr = extract(5), let status = Int(statusStr) {

                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss Z"
                let timestamp = formatter.date(from: tsStr) ?? Date()

                entries.append(AXLogEntryDisplay(
                    id: UUID(), type: .access, timestamp: timestamp,
                    ip: ip, method: method, statusCode: status,
                    urlOrMessage: url, userAgent: extract(8), referer: extract(7),
                    responseTime: nil, level: nil, file: nil, line: nil
                ))
            }
        }
        return entries
    }

    private func parseErrorLevelLogs(_ raw: String) -> [AXLogEntryDisplay] {
        let lines = raw.components(separatedBy: .newlines)
        var entries: [AXLogEntryDisplay] = []

        let pattern = #"^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(\w+)\] (.+)$"#
        let regex = try? NSRegularExpression(pattern: pattern)

        for line in lines {
            guard !line.isEmpty, let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { continue }

            func extract(_ index: Int) -> String? {
                guard let range = Range(match.range(at: index), in: line) else { return nil }
                return String(line[range])
            }

            if let tsStr = extract(1), let level = extract(2), let msg = extract(3) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                let timestamp = formatter.date(from: tsStr) ?? Date()

                entries.append(AXLogEntryDisplay(
                    id: UUID(), type: .error, timestamp: timestamp,
                    ip: nil, method: nil, statusCode: nil,
                    urlOrMessage: msg, userAgent: nil, referer: nil,
                    responseTime: nil, level: level, file: nil, line: nil
                ))
            }
        }
        return entries
    }

    private func parsePHPErrorLogs(_ raw: String) -> [AXLogEntryDisplay] {
        let lines = raw.components(separatedBy: .newlines)
        var entries: [AXLogEntryDisplay] = []

        let pattern = #"^\[(\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}:\d{2})\] ([A-Z]+): (.+)$"#
        let regex = try? NSRegularExpression(pattern: pattern)

        for line in lines {
            guard !line.isEmpty else { continue }

            if let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                func extract(_ index: Int) -> String? {
                    guard let range = Range(match.range(at: index), in: line) else { return nil }
                    return String(line[range])
                }

                if let tsStr = extract(1), let level = extract(2), let msg = extract(3) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
                    let timestamp = formatter.date(from: tsStr) ?? Date()

                    entries.append(AXLogEntryDisplay(
                        id: UUID(), type: .error, timestamp: timestamp,
                        ip: nil, method: nil, statusCode: nil,
                        urlOrMessage: msg, userAgent: nil, referer: nil,
                        responseTime: nil, level: level, file: nil, line: nil
                    ))
                }
            } else {
                entries.append(AXLogEntryDisplay(
                    id: UUID(), type: .error, timestamp: Date(),
                    ip: nil, method: nil, statusCode: nil,
                    urlOrMessage: line, userAgent: nil, referer: nil,
                    responseTime: nil, level: "ERROR", file: nil, line: nil
                ))
            }
        }
        return entries
    }
}
