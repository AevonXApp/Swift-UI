//
//  EnhancedLogsViewModel.swift
//  AevonX
//
//  ViewModel for enhanced per-site log viewing — delegates to SiteLogsService
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class EnhancedLogsViewModel: ObservableObject {
    @Published var logFiles: [LogFileItem] = []
    @Published var selectedLog: LogFileItem?
    @Published var logLines: [String] = []
    @Published var searchResults: [String] = []
    @Published var errorSummaries: [ErrorSummaryItem] = []
    @Published var searchQuery = ""
    @Published var lineCount = 100
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var selectedTab: LogTab = .viewer

    // AI Analysis
    @Published var aiAnalysis: LogAIAnalysis?
    @Published var isAnalyzing = false

    enum LogTab: String, CaseIterable, Identifiable {
        case viewer = "Log Viewer"
        case errors = "Error Analysis"
        case search = "Search"
        var id: String { rawValue }
    }

    let serverId: String
    let domain: String
    private let bridge = WebsitesBridge.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func discoverLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let cmd = bridge.discoverLogFilesCmd(domain: domain)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            let parsedJSON = bridge.parseLogFiles(output: result)

            if let data = parsedJSON.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               resp["success"] as? Bool == true,
               let files = resp["data"] as? [[String: String]] {
                logFiles = files.compactMap { dict in
                    guard let path = dict["path"], let type = dict["type"] else { return nil }
                    return LogFileItem(path: path, type: type, size: dict["size"] ?? "N/A", filename: dict["filename"] ?? (path as NSString).lastPathComponent)
                }
            }
            if selectedLog == nil, let first = logFiles.first {
                selectedLog = first
                await loadLogLines()
            }
        } catch {
            logFiles = []
        }
    }

    func loadLogLines() async {
        guard let log = selectedLog else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let cmd = bridge.readAccessLogCmd(logPath: log.path, lines: lineCount)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            logLines = result.components(separatedBy: "\n").filter { !$0.isEmpty }
            // Auto-run AI analysis when logs load
            await runSmartAnalysis()
        } catch {
            logLines = ["Error loading log: \(error.localizedDescription)"]
        }
    }

    func searchInLogs() async {
        guard let log = selectedLog, !searchQuery.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let cmd = "grep -i '\(searchQuery)' \(log.path) 2>/dev/null | tail -50"
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            searchResults = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        } catch {
            searchResults = ["Search error: \(error.localizedDescription)"]
        }
    }

    func analyzeErrors() async {
        guard let log = logFiles.first(where: { $0.type == "error" }) ?? selectedLog else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let cmd = "grep -i 'error\\|warn\\|crit\\|fatal' \(log.path) 2>/dev/null | sort | uniq -c | sort -rn | head -20"
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            let lines = result.components(separatedBy: "\n").filter { !$0.isEmpty }
            errorSummaries = lines.compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard let spaceIdx = trimmed.firstIndex(of: " ") else { return nil }
                let countStr = String(trimmed[trimmed.startIndex..<spaceIdx])
                let message = String(trimmed[trimmed.index(after: spaceIdx)...])
                return ErrorSummaryItem(count: Int(countStr) ?? 0, message: message)
            }
        } catch {
            errorSummaries = []
        }
    }

    // MARK: - Smart AI Analysis

    func runSmartAnalysis() async {
        guard !logLines.isEmpty else {
            aiAnalysis = nil
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }

        // Analyze log patterns locally (no external API needed)
        var httpCodes: [String: Int] = [:]
        var errorLines: [String] = []
        var warningLines: [String] = []
        var uniqueIPs = Set<String>()
        var totalRequests = 0
        var uniqueURLs = Set<String>()
        var botRequests = 0
        var largeResponses = 0

        for line in logLines {
            let lower = line.lowercased()
            totalRequests += 1

            // Extract HTTP status codes
            let statusPattern = try? NSRegularExpression(pattern: "\" (\\d{3}) ", options: [])
            if let match = statusPattern?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line) {
                let code = String(line[range])
                httpCodes[code, default: 0] += 1
            }

            // Extract IPs
            if let spaceIdx = line.firstIndex(of: " ") {
                let ip = String(line[line.startIndex..<spaceIdx])
                if ip.contains(".") || ip.contains(":") {
                    uniqueIPs.insert(ip)
                }
            }

            // Extract URLs
            let urlPattern = try? NSRegularExpression(pattern: "\"(?:GET|POST|PUT|DELETE|PATCH|HEAD) ([^ ]+)", options: [])
            if let match = urlPattern?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line) {
                uniqueURLs.insert(String(line[range]))
            }

            // Detect bots
            if lower.contains("bot") || lower.contains("crawler") || lower.contains("spider") || lower.contains("googlebot") || lower.contains("bingbot") || lower.contains("semrush") || lower.contains("ahref") {
                botRequests += 1
            }

            // Count errors and warnings
            if lower.contains("error") || lower.contains("fatal") || lower.contains("crit") || lower.contains(" 500 ") || lower.contains(" 502 ") || lower.contains(" 503 ") {
                errorLines.append(line)
            } else if lower.contains("warn") || lower.contains(" 404 ") || lower.contains(" 403 ") {
                warningLines.append(line)
            }

            // Large responses (>1MB)
            let sizePattern = try? NSRegularExpression(pattern: "\" \\d{3} (\\d+)", options: [])
            if let match = sizePattern?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line),
               let size = Int(line[range]), size > 1_000_000 {
                largeResponses += 1
            }
        }

        // Build health score
        let errorRate = totalRequests > 0 ? Double(errorLines.count) / Double(totalRequests) : 0
        let healthScore = max(0, min(100, Int(100 - (errorRate * 500) - Double(warningLines.count) / Double(max(1, totalRequests)) * 100)))

        // Build insights
        var insights: [LogInsight] = []

        // Health overview
        let healthLevel: LogInsight.InsightLevel = healthScore >= 80 ? .good : healthScore >= 50 ? .warning : .critical
        insights.append(LogInsight(
            icon: healthScore >= 80 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
            level: healthLevel,
            title: "Health Score: \(healthScore)%",
            detail: "Based on \(totalRequests) requests — \(errorLines.count) errors, \(warningLines.count) warnings"
        ))

        // Traffic summary
        insights.append(LogInsight(
            icon: "person.2.fill",
            level: .info,
            title: "\(uniqueIPs.count) Unique Visitors",
            detail: "\(totalRequests) total requests, \(uniqueURLs.count) unique URLs accessed"
        ))

        // Bot detection
        if botRequests > 0 {
            let botPercentage = Int(Double(botRequests) / Double(totalRequests) * 100)
            insights.append(LogInsight(
                icon: "ant.fill",
                level: botPercentage > 30 ? .warning : .info,
                title: "\(botRequests) Bot Requests (\(botPercentage)%)",
                detail: botPercentage > 30 ? "High bot traffic — consider rate limiting" : "Normal bot activity detected"
            ))
        }

        // Top HTTP errors
        let errorCodes = httpCodes.filter { Int($0.key) ?? 0 >= 400 }.sorted { $0.value > $1.value }
        if !errorCodes.isEmpty {
            let top = errorCodes.prefix(3).map { "\($0.key): \($0.value)x" }.joined(separator: ", ")
            insights.append(LogInsight(
                icon: "xmark.circle.fill",
                level: .critical,
                title: "HTTP Errors Found",
                detail: top
            ))
        }

        // 404s
        let count404 = httpCodes["404"] ?? 0
        if count404 > 5 {
            insights.append(LogInsight(
                icon: "questionmark.folder.fill",
                level: .warning,
                title: "\(count404) Not Found (404)",
                detail: "Multiple missing resources — check broken links or missing assets"
            ))
        }

        // 500 errors
        let count5xx = (httpCodes["500"] ?? 0) + (httpCodes["502"] ?? 0) + (httpCodes["503"] ?? 0)
        if count5xx > 0 {
            insights.append(LogInsight(
                icon: "bolt.trianglebadge.exclamationmark.fill",
                level: .critical,
                title: "\(count5xx) Server Errors (5xx)",
                detail: "Server-side failures detected — check application logs and PHP/Node errors"
            ))
        }

        // Large responses
        if largeResponses > 0 {
            insights.append(LogInsight(
                icon: "arrow.down.circle.fill",
                level: .warning,
                title: "\(largeResponses) Large Responses (>1MB)",
                detail: "Consider enabling compression or optimizing assets"
            ))
        }

        // Top status code distribution
        let statusDist = httpCodes.sorted { $0.value > $1.value }.prefix(5).map { LogStatusStat(code: $0.key, count: $0.value) }

        aiAnalysis = LogAIAnalysis(
            healthScore: healthScore,
            totalRequests: totalRequests,
            uniqueIPs: uniqueIPs.count,
            errorCount: errorLines.count,
            warningCount: warningLines.count,
            botCount: botRequests,
            insights: insights,
            statusDistribution: Array(statusDist)
        )
    }

    func clearLog() async {
        guard let log = selectedLog else { return }
        do {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo truncate -s 0 \(log.path)")
            logLines = []
            aiAnalysis = nil
            GlobalToastManager.shared.showSuccess("Log cleared: \(log.filename)")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func blockIP(_ ip: String) async {
        guard !ip.isEmpty else { return }
        do {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo ufw insert 1 deny from \(ip) to any comment 'Blocked via AevonX Logs' 2>&1")
            let output = result.lowercased()
            if output.contains("added") || output.contains("rule") {
                GlobalToastManager.shared.showSuccess("IP \(ip) blocked successfully")
            } else {
                // Fallback to iptables
                let iptResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo iptables -I INPUT -s \(ip) -j DROP 2>&1")
                if true {
                    GlobalToastManager.shared.showSuccess("IP \(ip) blocked via iptables")
                } else {
                    GlobalToastManager.shared.showError("Failed to block IP: \("")")
                }
            }
        } catch {
            GlobalToastManager.shared.showError("Block IP failed: \(error.localizedDescription)")
        }
    }

    func generateReport() -> String {
        guard let a = aiAnalysis else { return "No analysis data available." }
        var report = """
        ═══════════════════════════════════════
          AevonX Log Analysis Report
          Domain: \(domain)
          Generated: \(Date().formatted())
        ═══════════════════════════════════════

        HEALTH SCORE: \(a.healthScore)%
        Total Requests: \(a.totalRequests)
        Unique IPs: \(a.uniqueIPs)
        Errors: \(a.errorCount)
        Warnings: \(a.warningCount)
        Bot Requests: \(a.botCount)

        HTTP STATUS DISTRIBUTION:
        """
        for s in a.statusDistribution {
            report += "\n  \(s.code): \(s.count) requests"
        }
        report += "\n\nINSIGHTS:"
        for i in a.insights {
            report += "\n  [\(i.level)] \(i.title)"
            report += "\n    \(i.detail)"
        }
        report += "\n\n═══════════════════════════════════════"
        return report
    }
}

// MARK: - UI Models

struct LogFileItem: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let type: String
    let size: String
    let filename: String
}

struct ErrorSummaryItem: Identifiable {
    let id = UUID()
    let count: Int
    let message: String
}

struct LogAIAnalysis {
    let healthScore: Int
    let totalRequests: Int
    let uniqueIPs: Int
    let errorCount: Int
    let warningCount: Int
    let botCount: Int
    let insights: [LogInsight]
    let statusDistribution: [LogStatusStat]
}

struct LogInsight: Identifiable {
    let id = UUID()
    let icon: String
    let level: InsightLevel
    let title: String
    let detail: String

    enum InsightLevel {
        case good, info, warning, critical

        var color: Color {
            switch self {
            case .good: return .green
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

struct LogStatusStat: Identifiable {
    let id = UUID()
    let code: String
    let count: Int

    var color: Color {
        guard let num = Int(code) else { return .gray }
        switch num {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .gray
        }
    }
}
