//
//  SiteSecurityConfig.swift
//  AevonX
//
//  Models for per-site security features
//  (Hotlink protection, directory listing, rate limiting, bot blocking, etc.)
//

import Foundation
import SwiftUI

// MARK: - Security Feature

enum SiteSecurityFeature: String, CaseIterable, Identifiable {
    case hotlinkProtection = "Hotlink Protection"
    case directoryListing = "Directory Listing"
    case directoryPassword = "Directory Password"
    case botBlocking = "Bot Blocking"
    case rateLimiting = "Rate Limiting"
    case phpInUploads = "PHP in Uploads"
    case sensitiveFiles = "Sensitive Files"
    case permissionAudit = "Permission Audit"
    case malwareScan = "Malware Scan"
    case securityHeaders = "Security Headers Audit"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hotlinkProtection: return "link.badge.plus"
        case .directoryListing: return "list.bullet"
        case .directoryPassword: return "lock.fill"
        case .botBlocking: return "ant.fill"
        case .rateLimiting: return "speedometer"
        case .phpInUploads: return "exclamationmark.shield.fill"
        case .sensitiveFiles: return "eye.slash.fill"
        case .permissionAudit: return "checkmark.shield.fill"
        case .malwareScan: return "magnifyingglass"
        case .securityHeaders: return "doc.badge.gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .hotlinkProtection: return .orange
        case .directoryListing: return .blue
        case .directoryPassword: return .purple
        case .botBlocking: return .red
        case .rateLimiting: return .axWarning
        case .phpInUploads: return .axError
        case .sensitiveFiles: return .axAccentBlue
        case .permissionAudit: return .axSuccess
        case .malwareScan: return .red
        case .securityHeaders: return .cyan
        }
    }

    var description: String {
        switch self {
        case .hotlinkProtection: return "Prevent other sites from embedding your images"
        case .directoryListing: return "Toggle autoindex on/off for directories"
        case .directoryPassword: return "Password-protect specific directories"
        case .botBlocking: return "Block malicious bots and crawlers"
        case .rateLimiting: return "Limit requests per IP to prevent abuse"
        case .phpInUploads: return "Disable PHP execution in upload directories"
        case .sensitiveFiles: return "Block access to .env, .git, config files"
        case .permissionAudit: return "Find files with insecure permissions (777)"
        case .malwareScan: return "Scan for suspicious code patterns"
        case .securityHeaders: return "Check HTTP security headers configuration"
        }
    }
}

// MARK: - Security Status

struct SiteSecurityStatus: Identifiable {
    let id = UUID()
    let feature: SiteSecurityFeature
    var enabled: Bool
    var lastChecked: Date?
    var issues: [String]

    var statusColor: Color {
        if issues.isEmpty && enabled { return .axSuccess }
        if !issues.isEmpty { return .axError }
        return .axTextMuted
    }

    var statusText: String {
        if issues.isEmpty && enabled { return "Protected" }
        if !issues.isEmpty { return "\(issues.count) Issue\(issues.count > 1 ? "s" : "")" }
        return "Disabled"
    }
}

// MARK: - Rate Limit Rule

struct RateLimitRule: Identifiable, Hashable {
    let id = UUID()
    var zone: String        // e.g., "login", "api", "global"
    var rate: String        // e.g., "10r/s", "30r/m"
    var burst: Int          // burst allowance
    var locationPath: String // e.g., "/wp-login.php", "/api/", "/"

    static var presets: [RateLimitRule] {
        [
            RateLimitRule(zone: "login", rate: "5r/m", burst: 3, locationPath: "/wp-login.php"),
            RateLimitRule(zone: "api", rate: "30r/s", burst: 20, locationPath: "/api/"),
            RateLimitRule(zone: "global", rate: "50r/s", burst: 30, locationPath: "/"),
        ]
    }
}

// MARK: - Blocked Bot Pattern

struct BlockedBotPattern: Identifiable, Hashable {
    let id = UUID()
    var pattern: String
    var description: String
    var enabled: Bool

    static var defaults: [BlockedBotPattern] {
        [
            BlockedBotPattern(pattern: "SemrushBot", description: "SEMRush crawler", enabled: true),
            BlockedBotPattern(pattern: "AhrefsBot", description: "Ahrefs crawler", enabled: true),
            BlockedBotPattern(pattern: "MJ12bot", description: "Majestic crawler", enabled: true),
            BlockedBotPattern(pattern: "DotBot", description: "Moz crawler", enabled: false),
            BlockedBotPattern(pattern: "BLEXBot", description: "BLEXBot crawler", enabled: true),
            BlockedBotPattern(pattern: "sqlmap", description: "SQL injection tool", enabled: true),
            BlockedBotPattern(pattern: "nikto", description: "Web vulnerability scanner", enabled: true),
        ]
    }
}

// MARK: - Permission Audit Result

struct PermissionAuditResult: Identifiable {
    let id = UUID()
    let path: String
    let permissions: String
    let owner: String
    let severity: AuditSeverity

    enum AuditSeverity: String {
        case critical = "Critical"
        case warning = "Warning"
        case info = "Info"

        var color: Color {
            switch self {
            case .critical: return .axError
            case .warning: return .axWarning
            case .info: return .axAccentBlue
            }
        }
    }
}

// MARK: - Malware Scan Result

struct MalwareScanResult: Identifiable {
    let id = UUID()
    let filePath: String
    let matchedPattern: String
    let lineNumber: Int
    let lineContent: String
    let severity: PermissionAuditResult.AuditSeverity
}
