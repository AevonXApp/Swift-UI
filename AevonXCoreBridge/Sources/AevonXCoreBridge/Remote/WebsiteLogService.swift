//
//  WebsiteLogService.swift
//  AevonXCore
//

import Foundation

public actor WebsiteLogService {
    public static let shared = WebsiteLogService()
    
    private init() {}
    
    /// Get raw website logs via SSH.
    public func getWebsiteLogs(websiteId: String, serverId: String, lines: Int = 100) async throws -> String {
        CoreLogger.shared.info("Getting logs for: \(websiteId)", module: "WebsiteLogService")
        // Read Nginx access + error logs for the domain
        let result = try await SSHBridge.shared.execute(
            "sudo tail -n \(lines) /var/log/nginx/\(websiteId)-access.log /var/log/nginx/\(websiteId)-error.log /var/log/nginx/\(websiteId)-ssl-access.log 2>/dev/null || echo ''",
            serverId: serverId
        )
        return result.stdout
    }

    /// Get parsed access logs with optional filters.
    public func getAccessLogs(
        domain: String,
        serverId: String,
        limit: Int = 100,
        filters: LogFilters?
    ) async throws -> [AccessLogEntry] {
        CoreLogger.shared.info("Getting access logs for: \(domain)", module: "WebsiteLogService")
        let rawLogs = try await getWebsiteLogs(websiteId: domain, serverId: serverId, lines: limit)
        
        var entries: [AccessLogEntry] = []
        let lines = rawLogs.components(separatedBy: .newlines)

        for line in lines {
            guard !line.isEmpty else { continue }
            if let entry = parseAccessLogLine(line) {
                if let filters = filters {
                    if let statusCodes = filters.statusCodes, !statusCodes.contains(entry.statusCode) { continue }
                    if let ips = filters.ipAddresses, !ips.contains(entry.ip) { continue }
                    if let keyword = filters.keyword, !line.lowercased().contains(keyword.lowercased()) { continue }
                }
                entries.append(entry)
            }
        }
        return entries
    }

    /// Get parsed error logs with optional filters.
    public func getErrorLogs(
        domain: String,
        serverId: String,
        limit: Int = 100,
        filters: LogFilters?
    ) async throws -> [ErrorLogEntry] {
        CoreLogger.shared.info("Getting error logs for: \(domain)", module: "WebsiteLogService")
        let rawLogs = try await getWebsiteLogs(websiteId: domain, serverId: serverId, lines: limit)

        var entries: [ErrorLogEntry] = []
        let lines = rawLogs.components(separatedBy: .newlines)

        for line in lines {
            guard !line.isEmpty else { continue }
            if let entry = parseErrorLogLine(line) {
                if let filters = filters {
                    if let levels = filters.logLevels, !levels.contains(entry.level) { continue }
                    if let keyword = filters.keyword, !line.lowercased().contains(keyword.lowercased()) { continue }
                }
                entries.append(entry)
            }
        }
        return entries
    }

    private func parseAccessLogLine(_ line: String) -> AccessLogEntry? {
        let pattern = #"^(\S+) \S+ \S+ \[([\w:/]+\s[+\-]\d{4})\] "(\S+) (\S+) \S+" (\d{3}) (\d+) "([^"]*)" "([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        func extract(_ index: Int) -> String? {
            guard let range = Range(match.range(at: index), in: line) else { return nil }
            return String(line[range])
        }

        guard let ip = extract(1),
              let timestampStr = extract(2),
              let method = extract(3),
              let url = extract(4),
              let statusStr = extract(5),
              let status = Int(statusStr),
              let sizeStr = extract(6),
              let size = Int(sizeStr),
              let referrer = extract(7),
              let userAgent = extract(8) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss Z"
        let timestamp = dateFormatter.date(from: timestampStr) ?? Date()

        return AccessLogEntry(
            timestamp: timestamp,
            ip: ip,
            method: method,
            url: url,
            statusCode: status,
            responseSize: size,
            userAgent: userAgent,
            referrer: referrer != "-" ? referrer : nil
        )
    }

    private func parseErrorLogLine(_ line: String) -> ErrorLogEntry? {
        let pattern = #"^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(\w+)\] (.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        func extract(_ index: Int) -> String? {
            guard let range = Range(match.range(at: index), in: line) else { return nil }
            return String(line[range])
        }

        guard let timestampStr = extract(1),
              let levelStr = extract(2),
              let message = extract(3) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let timestamp = dateFormatter.date(from: timestampStr) ?? Date()
        let level = WebsiteLogLevel(rawValue: levelStr.lowercased()) ?? .error

        return ErrorLogEntry(
            timestamp: timestamp,
            level: level,
            message: message
        )
    }
}
