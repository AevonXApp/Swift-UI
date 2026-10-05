//
//  CerberusModels.swift
//  AevonXCoreBridge
//
//  Codable structs for AXCerberus WAF stats and management.
//  Matches JSON responses from `axcerberus exec` commands.
//

import Foundation

// MARK: - Overview

public struct WAFOverview: Codable, Sendable {
    public let totalRequests: Int
    public let blockedRequests: Int
    public let allowedRequests: Int
    public let protectionRate: Double
    public let qps: Double
    public let bytesIn: Int
    public let bytesOut: Int
    public let botRequests: Int
    public let humanRequests: Int
    public let uptimeSeconds: Int
    public let honeypotHitsToday: Int
    public let credentialAttacksToday: Int
    public let dlpEventsToday: Int
    public let ddosLevel: Int

    enum CodingKeys: String, CodingKey {
        case totalRequests = "total_requests"
        case blockedRequests = "blocked_requests"
        case allowedRequests = "allowed_requests"
        case protectionRate = "protection_rate"
        case qps
        case bytesIn = "bytes_in"
        case bytesOut = "bytes_out"
        case botRequests = "bot_requests"
        case humanRequests = "human_requests"
        case uptimeSeconds = "uptime_seconds"
        case honeypotHitsToday = "honeypot_hits_today"
        case credentialAttacksToday = "credential_attacks_today"
        case dlpEventsToday = "dlp_events_today"
        case ddosLevel = "ddos_level"
    }
}

// MARK: - Timeline

public struct TimelineEntry: Codable, Sendable, Identifiable {
    public var id: Int { hour }
    public let hour: Int
    public let total: Int
    public let blocked: Int
    public let allowed: Int
}

// MARK: - Attack Types

public struct AttackTypeStats: Codable, Sendable, Identifiable {
    public var id: String { type }
    public let type: String
    public let count: Int
}

// MARK: - Countries

public struct CountryStats: Codable, Sendable, Identifiable {
    public var id: String { countryCode }
    public let countryCode: String
    public let countryName: String
    public let count: Int

    enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case countryName = "country_name"
        case count
    }
}

// MARK: - Attackers

public struct AttackerInfo: Codable, Sendable, Identifiable {
    public var id: String { ip }
    public let ip: String
    public let country: String
    public let countryCode: String
    public let attacks: Int
    public let lastSeen: String

    enum CodingKeys: String, CodingKey {
        case ip, country, attacks
        case countryCode = "country_code"
        case lastSeen = "last_seen"
    }
}

// MARK: - URIs

public struct URIStats: Codable, Sendable, Identifiable {
    public var id: String { uri }
    public let uri: String
    public let count: Int
}

// MARK: - Domain Stats

public struct DomainStats: Codable, Sendable {
    public let totalRequests: Int
    public let blockedRequests: Int
    public let bytesIn: Int
    public let bytesOut: Int

    enum CodingKeys: String, CodingKey {
        case totalRequests = "total_requests"
        case blockedRequests = "blocked_requests"
        case bytesIn = "bytes_in"
        case bytesOut = "bytes_out"
    }
}

// MARK: - DDoS Status

public struct DDoSStatus: Codable, Sendable {
    public let level: Int
    public let currentQps: Double
    public let baselineQps: Double
    public let underAttack: Bool
    public let attackSince: String?

    enum CodingKeys: String, CodingKey {
        case level
        case currentQps = "current_qps"
        case baselineQps = "baseline_qps"
        case underAttack = "under_attack"
        case attackSince = "attack_since"
    }

    /// Raw level key for localization at the view layer.
    /// Map to L10n keys: none, low, medium, high, unknown.
    public var levelKey: String {
        switch level {
        case 0: return "none"
        case 1: return "low"
        case 2: return "medium"
        case 3: return "high"
        default: return "unknown"
        }
    }
}

// MARK: - Honeypot

public struct HoneypotHit: Codable, Sendable, Identifiable {
    public let uid: String
    public let ip: String
    public let path: String
    public let method: String
    public let userAgent: String
    public let headers: [String: String]
    public let body: String
    public let time: String

    public var id: String { uid }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ip = try c.decode(String.self, forKey: .ip)
        path = try c.decode(String.self, forKey: .path)
        method = try c.decode(String.self, forKey: .method)
        userAgent = try c.decodeIfPresent(String.self, forKey: .userAgent) ?? ""
        headers = try c.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
        body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
        time = try c.decode(String.self, forKey: .time)
        uid = "\(ip)-\(time)-\(path)-\(UUID().uuidString.prefix(8))"
    }

    enum CodingKeys: String, CodingKey {
        case ip, path, method, headers, body, time
        case userAgent = "user_agent"
    }
}

// MARK: - Credential Status

public struct CredentialStatus: Codable, Sendable {
    public let totalAttempts: Int
    public let blockedIps: Int
    public let activeTrackedIps: Int
    public let attacksDetected: Int

    enum CodingKeys: String, CodingKey {
        case totalAttempts = "total_attempts"
        case blockedIps = "blocked_ips"
        case activeTrackedIps = "active_tracked_ips"
        case attacksDetected = "attacks_detected"
    }
}

// MARK: - Response Times

public struct WAFResponseTimes: Codable, Sendable {
    public let p50: Double
    public let p95: Double
    public let p99: Double
    public let avg: Double
    public let max: Double
    public let samples: Int
}

// MARK: - Status Codes

public struct WAFStatusCode: Codable, Sendable, Identifiable {
    public var id: Int { code }
    public let code: Int
    public let count: Int
}

// MARK: - Bot Details

public struct WAFBotDetails: Codable, Sendable {
    public let totalBot: Int
    public let totalHuman: Int
    public let botRate: Double

    enum CodingKeys: String, CodingKey {
        case totalBot = "total_bot"
        case totalHuman = "total_human"
        case botRate = "bot_rate"
    }
}

// MARK: - Alert Event

public struct WAFAlertEvent: Codable, Sendable, Identifiable {
    public let uid: String
    public let type: String
    public let severity: String
    public let message: String
    public let details: [String: String]?
    public let timestamp: String

    public var id: String { uid }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        severity = try c.decode(String.self, forKey: .severity)
        message = try c.decode(String.self, forKey: .message)
        timestamp = try c.decode(String.self, forKey: .timestamp)

        // Preserve details even when values are non-string by converting to String
        if let rawDetails = try? c.decode([String: AnyCodableValue].self, forKey: .details) {
            details = rawDetails.mapValues { $0.stringValue }
        } else {
            details = nil
        }

        uid = "\(type)-\(timestamp)-\(UUID().uuidString.prefix(8))"
    }

    enum CodingKeys: String, CodingKey {
        case type, severity, message, details, timestamp
    }
}

/// Helper for decoding mixed-type JSON values into String.
public enum AnyCodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Int.self) { self = .int(v) }
        else if let v = try? c.decode(Double.self) { self = .double(v) }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else { self = .string("") }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        }
    }

    public var stringValue: String {
        switch self {
        case .string(let v): return v
        case .int(let v): return String(v)
        case .double(let v): return String(v)
        case .bool(let v): return v ? "true" : "false"
        }
    }
}

// MARK: - Access Log Entry

public struct WAFAccessLogEntry: Codable, Sendable, Identifiable {
    public let uid: String
    public let timestamp: String
    public let ip: String
    public let country: String
    public let countryCode: String
    public let method: String
    public let host: String
    public let path: String
    public let statusCode: Int
    public let latencyMs: Double
    public let bytesIn: Int
    public let bytesOut: Int
    public let userAgent: String
    public let isBot: Bool

    public var id: String { uid }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try c.decode(String.self, forKey: .timestamp)
        ip = try c.decode(String.self, forKey: .ip)
        country = try c.decodeIfPresent(String.self, forKey: .country) ?? ""
        countryCode = try c.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        method = try c.decode(String.self, forKey: .method)
        host = try c.decodeIfPresent(String.self, forKey: .host) ?? ""
        path = try c.decode(String.self, forKey: .path)
        statusCode = try c.decode(Int.self, forKey: .statusCode)
        latencyMs = try c.decodeIfPresent(Double.self, forKey: .latencyMs) ?? 0
        bytesIn = try c.decodeIfPresent(Int.self, forKey: .bytesIn) ?? 0
        bytesOut = try c.decodeIfPresent(Int.self, forKey: .bytesOut) ?? 0
        userAgent = try c.decodeIfPresent(String.self, forKey: .userAgent) ?? ""
        isBot = try c.decodeIfPresent(Bool.self, forKey: .isBot) ?? false
        uid = "\(ip)-\(timestamp)-\(UUID().uuidString.prefix(8))"
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, ip, country, method, host, path
        case countryCode = "country_code"
        case statusCode = "status_code"
        case latencyMs = "latency_ms"
        case bytesIn = "bytes_in"
        case bytesOut = "bytes_out"
        case userAgent = "user_agent"
        case isBot = "is_bot"
    }
}

// MARK: - Block Log Entry

public struct WAFBlockLogEntry: Codable, Sendable, Identifiable {
    public let uid: String
    public let timestamp: String
    public let ip: String
    public let country: String
    public let countryCode: String
    public let method: String
    public let host: String
    public let path: String
    public let rule: String
    public let reason: String
    public let severity: String
    public let userAgent: String

    public var id: String { uid }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try c.decode(String.self, forKey: .timestamp)
        ip = try c.decode(String.self, forKey: .ip)
        country = try c.decodeIfPresent(String.self, forKey: .country) ?? ""
        countryCode = try c.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        method = try c.decodeIfPresent(String.self, forKey: .method) ?? ""
        host = try c.decodeIfPresent(String.self, forKey: .host) ?? ""
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        rule = try c.decodeIfPresent(String.self, forKey: .rule) ?? ""
        reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
        severity = try c.decodeIfPresent(String.self, forKey: .severity) ?? ""
        userAgent = try c.decodeIfPresent(String.self, forKey: .userAgent) ?? ""
        uid = "\(ip)-\(timestamp)-\(rule)-\(UUID().uuidString.prefix(8))"
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, ip, country, method, host, path, rule, reason, severity
        case countryCode = "country_code"
        case userAgent = "user_agent"
    }
}

// MARK: - Log Responses (with total for pagination)

public struct WAFAccessLogResponse: Codable, Sendable {
    public let entries: [WAFAccessLogEntry]
    public let total: Int
}

public struct WAFBlockLogResponse: Codable, Sendable {
    public let entries: [WAFBlockLogEntry]
    public let total: Int
}

// MARK: - Service Status

public struct WAFServiceStatus: Codable, Sendable {
    public let service: String
    public let status: String
    public let binary: String

    public var isActive: Bool { status == "active" }
}

// MARK: - Service Action Result

public struct WAFServiceActionResult: Codable, Sendable {
    public let service: String
    public let action: String
    public let status: String
    public let ok: Bool
}

// MARK: - Domain Info

public struct WAFDomainInfo: Codable, Sendable, Identifiable {
    public var id: String { domain }
    public let domain: String
    public let enabled: Bool
    public let webServer: String

    enum CodingKeys: String, CodingKey {
        case domain, enabled
        case webServer = "web_server"
    }
}

// MARK: - Domain Sync Result

public struct WAFDomainSyncResult: Codable, Sendable {
    public let synced: Int
    public let total: Int
    public let webServer: String

    enum CodingKeys: String, CodingKey {
        case synced, total
        case webServer = "web_server"
    }
}

// MARK: - Web Server Info

public struct WAFWebServerInfo: Codable, Sendable {
    public let type: String
    public let port: Int
    public let status: String

    public var isActive: Bool { status == "active" }
}

// MARK: - Threat Feed Status

public struct WAFThreatSource: Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let entries: Int
    public let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case name, entries
        case lastUpdated = "last_updated"
    }

    public init(name: String, entries: Int, lastUpdated: String) {
        self.name = name
        self.entries = entries
        self.lastUpdated = lastUpdated
    }
}

public struct WAFThreatFeedStatus: Codable, Sendable {
    public let enabled: Bool
    public let lastUpdate: String?
    public let nextUpdate: String?
    public let totalEntries: Int?
    public let blockedByFeed: Int?
    public let sources: [WAFThreatSource]?

    enum CodingKeys: String, CodingKey {
        case enabled
        case lastUpdate = "last_update"
        case nextUpdate = "next_update"
        case totalEntries = "total_entries"
        case blockedByFeed = "blocked_by_feed"
        case sources
    }
}

// MARK: - Virtual Patch

public struct WAFVirtualPatch: Codable, Sendable, Identifiable {
    public var id: String { patchID }
    public let patchID: String
    public let cve: String
    public let description: String
    public let pathPattern: String
    public let action: String
    public let severity: String
    public let enabled: Bool
    public let createdAt: String?
    public let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case patchID = "id"
        case cve, description, action, severity, enabled
        case pathPattern = "path_pattern"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - Config Backup

public struct WAFConfigBackup: Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let size: Int
    public let modTime: String

    enum CodingKeys: String, CodingKey {
        case name, size
        case modTime = "mod_time"
    }
}

// MARK: - Anomaly Detection Status

public struct WAFAnomalyStatus: Codable, Sendable {
    public let enabled: Bool
    public let totalEndpoints: Int?
    public let anomaliesDetected: Int?
    public let windowMinutes: Int?
    public let deviationFactor: Double?

    enum CodingKeys: String, CodingKey {
        case enabled
        case totalEndpoints = "total_endpoints"
        case anomaliesDetected = "anomalies_detected"
        case windowMinutes = "window_minutes"
        case deviationFactor = "deviation_factor"
    }
}

// MARK: - Session Tracking Status

public struct WAFSessionStatus: Codable, Sendable {
    public let enabled: Bool
    public let activeSessions: Int?
    public let totalTracked: Int?
    public let atoDetections: Int?
    public let rateLimited: Int?

    enum CodingKeys: String, CodingKey {
        case enabled
        case activeSessions = "active_sessions"
        case totalTracked = "total_tracked"
        case atoDetections = "ato_detections"
        case rateLimited = "rate_limited"
    }
}

// MARK: - Custom Rule

public struct WAFCustomRule: Codable, Sendable, Identifiable {
    public var id: String { ruleID }
    public let ruleID: String
    public let raw: String
    public let action: String
    public let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case ruleID = "id"
        case raw, action, enabled
    }
}

// MARK: - Custom Rules Response

public struct WAFCustomRulesResponse: Codable, Sendable {
    public let rules: [WAFCustomRule]
    public let enabled: Bool
}

// MARK: - Compliance Check

public struct WAFComplianceCheck: Codable, Sendable, Identifiable {
    public var id: String { checkID }
    public let checkID: String
    public let category: String
    public let requirement: String
    public let description: String
    public let status: String
    public let details: String?

    enum CodingKeys: String, CodingKey {
        case checkID = "id"
        case category, requirement, description, status, details
    }

    public var isPassed: Bool { status == "pass" }
    public var isFailed: Bool { status == "fail" }
}

// MARK: - Time Series

public struct WAFTimeSeriesBucket: Codable, Sendable, Identifiable {
    public var id: String { timestamp }
    public let timestamp: String
    public let total: Int64
    public let blocked: Int64
    public let allowed: Int64
    public let avgLatencyMs: Double

    enum CodingKeys: String, CodingKey {
        case timestamp, total, blocked, allowed
        case avgLatencyMs = "avg_latency_ms"
    }
}

public struct WAFTimeSeriesResponse: Codable, Sendable {
    public let buckets: [WAFTimeSeriesBucket]
    public let granularity: String
    public let start: String
    public let end: String
}

// MARK: - Domain Countries

public struct WAFDomainCountries: Codable, Sendable {
    public let domain: String
    public let countries: [CountryStats]
}

// MARK: - Domain Timeline

public struct WAFDomainTimeline: Codable, Sendable {
    public let domain: String
    public let timeline: [TimelineEntry]
}

// MARK: - Domain Rules (per-domain blocking)

public struct WAFDomainRules: Codable, Sendable {
    public let domain: String
    public let blockedIPs: [String]
    public let blockedCountries: [String]

    enum CodingKeys: String, CodingKey {
        case domain
        case blockedIPs = "blocked_ips"
        case blockedCountries = "blocked_countries"
    }
}

// MARK: - Domain Rules IP

public struct WAFDomainRulesIP: Codable, Sendable {
    public let domain: String
    public let blockedIPs: [String]
    public let count: Int

    enum CodingKeys: String, CodingKey {
        case domain
        case blockedIPs = "blocked_ips"
        case count
    }
}

// MARK: - Domain Rules Country

public struct WAFDomainRulesCountry: Codable, Sendable {
    public let domain: String
    public let blockedCountries: [String]
    public let count: Int

    enum CodingKeys: String, CodingKey {
        case domain
        case blockedCountries = "blocked_countries"
        case count
    }
}

// MARK: - Config Batch

public struct WAFConfigBatchResult: Codable, Sendable, Identifiable {
    public var id: String { key }
    public let key: String
    public let value: String
    public let status: String
    public let error: String?

    public var succeeded: Bool { status == "success" }
}

public struct WAFConfigBatchResponse: Codable, Sendable {
    public let results: [WAFConfigBatchResult]
    public let succeeded: Int
    public let failed: Int
}

// MARK: - Compliance Report

public struct WAFComplianceReport: Codable, Sendable {
    public let generatedAt: String?
    public let framework: String
    public let score: Int
    public let totalChecks: Int
    public let passed: Int
    public let failed: Int
    public let warnings: Int
    public let checks: [WAFComplianceCheck]

    enum CodingKeys: String, CodingKey {
        case framework, score, passed, failed, warnings, checks
        case generatedAt = "generated_at"
        case totalChecks = "total_checks"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try c.decodeIfPresent(String.self, forKey: .generatedAt)
        framework   = try c.decodeIfPresent(String.self, forKey: .framework) ?? "PCI-DSS"
        score       = try c.decodeIfPresent(Int.self, forKey: .score) ?? 0
        totalChecks = try c.decodeIfPresent(Int.self, forKey: .totalChecks) ?? 0
        passed      = try c.decodeIfPresent(Int.self, forKey: .passed) ?? 0
        failed      = try c.decodeIfPresent(Int.self, forKey: .failed) ?? 0
        warnings    = try c.decodeIfPresent(Int.self, forKey: .warnings) ?? 0
        checks      = try c.decodeIfPresent([WAFComplianceCheck].self, forKey: .checks) ?? []
    }
}

// MARK: - Dashboard Bundle

/// All dashboard data fetched in a single SSH call (replaces 9 concurrent calls).
public struct CerberusDashboardBundle: Codable, Sendable {
    public let overview: WAFOverview?
    public let timeline: [TimelineEntry]?
    public let ddosStatus: DDoSStatus?
    public let serviceStatus: WAFServiceStatus?
    public let credentialStatus: CredentialStatus?
    public let countries: [CountryStats]?
    public let blockLog: [WAFBlockLogEntry]?
    public let blockLogTotal: Int?
    public let qps: Double?
    public let anomalyStatus: WAFAnomalyStatus?

    private enum CodingKeys: String, CodingKey {
        case overview
        case timeline
        case ddosStatus = "ddos_status"
        case serviceStatus = "service_status"
        case credentialStatus = "credential_status"
        case countries
        case blockLog = "block_log"
        case blockLogTotal = "block_log_total"
        case qps
        case anomalyStatus = "anomaly_status"
    }
}
