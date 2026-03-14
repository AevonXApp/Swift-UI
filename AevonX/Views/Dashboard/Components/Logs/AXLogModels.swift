//
//  AXLogModels.swift
//  AevonX
//
//  Shared models, enums, and helpers for all log components.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Flexible Table Models

/// Column definition — caller decides which columns to show.
struct AXLogColumn: Identifiable {
    let id: String          // key used in AXLogRow.cells
    let title: String       // header text
    let width: CGFloat?     // nil = flexible (fills remaining space)
    var alignment: Alignment = .leading
}

/// A single row — caller parses data and builds these.
struct AXLogRow: Identifiable {
    let id: Int
    let level: String                     // "error", "warn", "info" → for badge + filter
    let cells: [String: String]           // columnId → display value
    let raw: String                       // full original line for expandable view
    var details: [AXLogRowDetail]? = nil  // key-value pairs in expanded view
}

/// Key-value detail shown in expanded row.
struct AXLogRowDetail {
    let label: String
    let value: String
}

/// Action button shown in expanded row.
struct AXLogRowAction {
    let id: String
    let label: String
    let icon: String
    let color: Color
    let handler: (AXLogRow) -> Void
}

// MARK: - Log Line Parser Helper

/// Detects level from raw log line text. Callers use this to build `AXLogRow.level`.
enum AXLogLevelDetector {
    static func detect(_ line: String) -> String {
        let lower = line.lowercased()
        // Error patterns
        if lower.contains("[error]") || lower.contains("[crit]") || lower.contains("[emerg]")
            || lower.contains("failed password") || lower.contains("denied")
            || lower.contains("refused") || lower.contains("fatal") || lower.contains("panic") {
            return "error"
        }
        // Warning patterns
        if lower.contains("[warn") || lower.contains("[notice]")
            || lower.contains("invalid user") || lower.contains("authentication failure")
            || lower.contains("connection closed") || lower.contains("disconnect")
            || lower.contains("timeout") || lower.contains("not allowed") {
            return "warn"
        }
        // HTTP status detection
        if lower.contains(" 500 ") || lower.contains(" 502 ") || lower.contains(" 503 ") { return "error" }
        if lower.contains(" 404 ") || lower.contains(" 403 ") || lower.contains(" 401 ") { return "warn" }
        return "info"
    }

    static func color(_ level: String) -> Color {
        switch level {
        case "error", "fatal", "crit", "emerg": return .red
        case "warn", "warning", "notice": return .orange
        case "info", "debug": return .green
        default: return .axTextMuted
        }
    }
}

// MARK: - Timestamp Extractor

enum AXLogTimestamp {
    /// Extracts timestamp from a raw log line. Supports bracket format and ISO 8601.
    static func extract(_ raw: String) -> String {
        // Bracket format: [28/Feb/2026:13:07:01 +0100]
        if let match = raw.range(of: "\\[([^\\]]+)\\]", options: .regularExpression) {
            let ts = String(raw[match]).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            return format(ts)
        }
        // ISO 8601: 2026-02-28T13:07:01...
        if let match = raw.range(of: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", options: .regularExpression) {
            let iso = String(raw[match])
            if iso.count >= 16 { return String(iso.prefix(10)) + " " + String(iso.dropFirst(11).prefix(5)) }
        }
        return "—"
    }

    private static func format(_ raw: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss Z"
        if let date = formatter.date(from: raw) {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd HH:mm"
            return out.string(from: date)
        }
        formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss"
        if let date = formatter.date(from: raw) {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd HH:mm"
            return out.string(from: date)
        }
        if raw.count > 16 { return String(raw.prefix(16)) }
        return raw
    }
}

// MARK: - Log Level Filter (for raw text logs)

/// Reusable log level filter with severity detection.
enum AXLogLevel: String, CaseIterable, Identifiable {
    case all = "All"
    case errors = "Errors"
    case warnings = "Warnings"
    case info = "Info"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .all:      return .axAccentBlue
        case .errors:   return .axError
        case .warnings: return .axWarning
        case .info:     return .axSuccess
        }
    }

    func matches(_ line: String) -> Bool {
        let lower = line.lowercased()
        switch self {
        case .all: return true
        case .errors:
            return lower.contains("error") || lower.contains("failed")
                || lower.contains("fatal") || lower.contains("crit")
                || lower.contains("emerg") || lower.contains("panic")
                || lower.contains("denied") || lower.contains("refused")
                || lower.contains(" 500 ") || lower.contains(" 502 ") || lower.contains(" 503 ")
        case .warnings:
            return lower.contains("warn") || lower.contains("notice")
                || lower.contains("invalid") || lower.contains("authentication failure")
                || lower.contains("not allowed") || lower.contains("timeout")
                || lower.contains("connection closed") || lower.contains("disconnect")
                || lower.contains("expired") || lower.contains("retry")
                || lower.contains(" 404 ") || lower.contains(" 403 ") || lower.contains(" 401 ")
        case .info:
            return lower.contains("accept") || lower.contains("success")
                || lower.contains("started") || lower.contains("opened")
                || lower.contains("session closed") || lower.contains("logged")
                || lower.contains("[info]") || lower.contains("new session")
                || lower.contains(" 200 ") || lower.contains(" 301 ") || lower.contains(" 304 ")
        }
    }
}

// MARK: - Default Line Colorizer (for raw text logs)

func axLogLineColor(_ line: String) -> Color {
    let lower = line.lowercased()
    if lower.contains("error") || lower.contains("failed") || lower.contains("fatal")
        || lower.contains("denied") || lower.contains("crit") || lower.contains("emerg") {
        return .axError
    }
    if lower.contains("warn") || lower.contains("invalid") || lower.contains("notice") {
        return .axWarning
    }
    if lower.contains("accepted") || lower.contains("success") || lower.contains("started") {
        return .axSuccess
    }
    return .axTextSecondary
}

// MARK: - Log Source (for structured/parsed logs)

public enum AXLogSource: Equatable {
    case website(domain: String)
    case nginxService
    case apacheService
    case phpService
    case mysqlService
    case postgresqlService
    case redisService
    case mongodbService
    case mariadbService
    case cassandraService
    case elasticsearchService
    case cockroachdbService
    case genericService(name: String, path: String)

    var displayName: String {
        switch self {
        case .website(let domain): return "Site: \(domain)"
        case .nginxService: return "Nginx Service"
        case .apacheService: return "Apache Service"
        case .phpService: return "PHP-FPM Service"
        case .mysqlService: return "MySQL Service"
        case .postgresqlService: return "PostgreSQL Service"
        case .redisService: return "Redis Service"
        case .mongodbService: return "MongoDB Service"
        case .mariadbService: return "MariaDB Service"
        case .cassandraService: return "Cassandra Service"
        case .elasticsearchService: return "Elasticsearch Service"
        case .cockroachdbService: return "CockroachDB Service"
        case .genericService(let name, _): return "\(name) Service"
        }
    }
}

// MARK: - Log Type Tabs

enum AXLogTab: String, CaseIterable, Identifiable {
    case access = "Access Logs"
    case error = "Error Logs"
    case all = "All Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .access: return "arrow.right.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .all: return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .access: return .axAccentBlue
        case .error: return .axError
        case .all: return .axTextSecondary
        }
    }
}

// MARK: - Sort Options

enum AXLogSortOption: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case ipAddress = "IP Address"
    case statusCode = "Status Code"

    var icon: String {
        switch self {
        case .newestFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        case .ipAddress: return "network"
        case .statusCode: return "number"
        }
    }
}

// MARK: - Log Entry Display Model

public struct AXLogEntryDisplay: Identifiable {
    public let id: UUID
    let type: AXLogTab
    public let timestamp: Date
    public let ip: String?
    public let method: String?
    public let statusCode: Int?
    public let urlOrMessage: String
    public let userAgent: String?
    public let referer: String?
    public let responseTime: String?
    public let level: String?
    public let file: String?
    public let line: Int?

    public var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var levelIcon: String {
        switch level?.lowercased() {
        case "error", "crit", "emerg", "alert": return "xmark.circle.fill"
        case "warn", "warning": return "exclamationmark.triangle.fill"
        case "info", "notice", "debug": return "info.circle.fill"
        default: return "circle.fill"
        }
    }

    var levelColor: Color {
        switch level?.lowercased() {
        case "error", "crit", "emerg", "alert": return .axError
        case "warn", "warning": return .axWarning
        case "info", "notice", "debug": return .axAccentBlue
        default: return .axTextSecondary
        }
    }
}
