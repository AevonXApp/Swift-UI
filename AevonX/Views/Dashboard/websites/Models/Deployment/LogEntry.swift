//
//  LogEntry.swift
//  AevonX
//
//  UI layer extensions for structured log entries
//  Core types are defined in AevonXCore
//

import Foundation
import SwiftUI
import AevonXCoreBridge

// MARK: - Log Types (local definitions)

public enum WebsiteLogLevel: String, Codable, Sendable {
    case debug = "debug"
    case info = "info"
    case notice = "notice"
    case warn = "warn"
    case error = "error"
    case crit = "crit"
    case alert = "alert"
    case emerg = "emerg"
}

public struct AccessLogEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public var timestamp: Date
    public var ip: String
    public var method: String
    public var url: String
    public var statusCode: Int
    public var responseSize: Int
    public var userAgent: String
    public var referrer: String?
    public var responseTime: Double?

    public init(id: UUID = UUID(), timestamp: Date, ip: String, method: String, url: String, statusCode: Int, responseSize: Int, userAgent: String, referrer: String? = nil, responseTime: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.ip = ip
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.responseSize = responseSize
        self.userAgent = userAgent
        self.referrer = referrer
        self.responseTime = responseTime
    }
}

public struct ErrorLogEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public var timestamp: Date
    public var level: WebsiteLogLevel
    public var message: String
    public var file: String?
    public var line: Int?
    public var context: String?

    public init(id: UUID = UUID(), timestamp: Date, level: WebsiteLogLevel, message: String, file: String? = nil, line: Int? = nil, context: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.file = file
        self.line = line
        self.context = context
    }
}

public struct LogFilters: Codable, Sendable {
    public var statusCodes: [Int]?
    public var ipAddresses: [String]?
    public var startDate: Date?
    public var endDate: Date?
    public var logLevels: [WebsiteLogLevel]?
    public var keyword: String?
    public var methods: [String]?
    public var minResponseTime: Double?
    public var maxResponseTime: Double?

    public init(statusCodes: [Int]? = nil, ipAddresses: [String]? = nil, startDate: Date? = nil, endDate: Date? = nil, logLevels: [WebsiteLogLevel]? = nil, keyword: String? = nil, methods: [String]? = nil, minResponseTime: Double? = nil, maxResponseTime: Double? = nil) {
        self.statusCodes = statusCodes
        self.ipAddresses = ipAddresses
        self.startDate = startDate
        self.endDate = endDate
        self.logLevels = logLevels
        self.keyword = keyword
        self.methods = methods
        self.minResponseTime = minResponseTime
        self.maxResponseTime = maxResponseTime
    }
}

// MARK: - UI Layer Extensions

extension AccessLogEntry {
    /// HTTP status category
    public var statusCategory: HTTPStatusCategory {
        HTTPStatusCategory(statusCode: statusCode)
    }

    /// Formatted timestamp
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    /// Formatted response size
    public var formattedSize: String {
        AXFormatter.formatBytes(Int64(responseSize))
    }

    /// Formatted response time
    public var formattedResponseTime: String? {
        guard let time = responseTime else { return nil }
        return AXFormatter.formatResponseTime(time)
    }

    /// Whether this is an error request
    public var isError: Bool {
        statusCode >= 400
    }

    /// Shortened URL for display
    public var shortURL: String {
        if url.count > 50 {
            return String(url.prefix(47)) + "..."
        }
        return url
    }

    /// Browser/client type from user agent
    public var clientType: String {
        let ua = userAgent.lowercased()
        if ua.contains("chrome") { return "Chrome" }
        if ua.contains("safari") { return "Safari" }
        if ua.contains("firefox") { return "Firefox" }
        if ua.contains("edge") { return "Edge" }
        if ua.contains("bot") || ua.contains("crawler") { return "Bot" }
        if ua.contains("curl") { return "cURL" }
        return "Other"
    }
}

extension ErrorLogEntry {
    /// Formatted timestamp
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    /// File location string
    public var fileLocation: String? {
        guard let file = file else { return nil }
        if let line = line {
            return "\(file):\(line)"
        }
        return file
    }

    /// Shortened message for list display
    public var shortMessage: String {
        if message.count > 100 {
            return String(message.prefix(97)) + "..."
        }
        return message
    }
}

extension LogFilters {
    /// Whether any filters are active
    public var hasActiveFilters: Bool {
        statusCodes != nil || ipAddresses != nil || startDate != nil ||
        endDate != nil || logLevels != nil || keyword != nil ||
        methods != nil || minResponseTime != nil || maxResponseTime != nil
    }

    /// Count of active filters
    public var activeFilterCount: Int {
        var count = 0
        if statusCodes != nil { count += 1 }
        if ipAddresses != nil { count += 1 }
        if startDate != nil || endDate != nil { count += 1 }
        if logLevels != nil { count += 1 }
        if keyword != nil { count += 1 }
        if methods != nil { count += 1 }
        if minResponseTime != nil || maxResponseTime != nil { count += 1 }
        return count
    }
}

extension WebsiteLogLevel {
    public var displayName: String {
        rawValue.capitalized
    }

    public var color: Color {
        switch self {
        case .debug: return .axTextTertiary
        case .info, .notice: return .axAccentBlue
        case .warn: return .axWarning
        case .error, .crit: return .axError
        case .alert, .emerg: return .axError
        }
    }

    public var icon: String {
        switch self {
        case .debug: return "ant"
        case .info, .notice: return "info.circle"
        case .warn: return "exclamationmark.triangle"
        case .error, .crit: return "xmark.circle"
        case .alert, .emerg: return "exclamationmark.octagon"
        }
    }

    public var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .notice: return 2
        case .warn: return 3
        case .error: return 4
        case .crit: return 5
        case .alert: return 6
        case .emerg: return 7
        }
    }
}

// MARK: - Log Type

/// Type of log file
public enum LogType: String, Codable, CaseIterable, Identifiable {
    case access = "Access"
    case error = "Error"
    case system = "System"
    case application = "Application"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .access: return "arrow.right.circle"
        case .error: return "exclamationmark.triangle"
        case .system: return "gearshape"
        case .application: return "app.badge"
        }
    }

    public var color: Color {
        switch self {
        case .access: return .axAccentBlue
        case .error: return .axError
        case .system: return .axTextSecondary
        case .application: return .axAccentGreen
        }
    }
}

// MARK: - HTTP Status Category

/// Category of HTTP status code
public enum HTTPStatusCategory: String, Codable {
    case informational = "Informational"
    case success = "Success"
    case redirection = "Redirection"
    case clientError = "Client Error"
    case serverError = "Server Error"
    case unknown = "Unknown"

    init(statusCode: Int) {
        switch statusCode {
        case 100..<200: self = .informational
        case 200..<300: self = .success
        case 300..<400: self = .redirection
        case 400..<500: self = .clientError
        case 500..<600: self = .serverError
        default: self = .unknown
        }
    }

    public var color: Color {
        switch self {
        case .informational: return .axAccentBlue
        case .success: return .axSuccess
        case .redirection: return .axAccentBlue
        case .clientError: return .axWarning
        case .serverError: return .axError
        case .unknown: return .axTextMuted
        }
    }

    public var icon: String {
        switch self {
        case .informational: return "info.circle"
        case .success: return "checkmark.circle"
        case .redirection: return "arrow.turn.up.right"
        case .clientError: return "exclamationmark.triangle"
        case .serverError: return "xmark.octagon"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Export Format

/// Format for exporting logs
public enum ExportFormat: String, Codable, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case txt = "Plain Text"

    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .txt: return "txt"
        }
    }

    public var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .txt: return "doc.text"
        }
    }
}
