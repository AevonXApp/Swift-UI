//
//  MonitoringData.swift
//  AevonX
//
//  Models for per-site monitoring, analytics, and health checking
//

import Foundation
import SwiftUI

// MARK: - Site Health Check

struct SiteHealthCheck: Identifiable {
    let id = UUID()
    let timestamp: Date
    var httpStatus: Int?
    var responseTime: Double?     // seconds
    var sslDaysRemaining: Int?
    var dnsResolved: Bool
    var isUp: Bool

    var statusColor: Color {
        guard isUp else { return .axError }
        if let status = httpStatus, status >= 400 { return .axError }
        if let time = responseTime, time > 3.0 { return .axWarning }
        if let days = sslDaysRemaining, days < 14 { return .axWarning }
        return .axSuccess
    }

    var statusText: String {
        guard isUp else { return "Offline" }
        if let status = httpStatus, status >= 500 { return "Server Error" }
        if let status = httpStatus, status >= 400 { return "Client Error" }
        return "Healthy"
    }

    var formattedResponseTime: String {
        guard let time = responseTime else { return "N/A" }
        if time < 1.0 {
            return String(format: "%.0fms", time * 1000)
        }
        return String(format: "%.2fs", time)
    }
}

// MARK: - Top URL Entry

struct TopURLEntry: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let count: Int
    let percentage: Double
}

// MARK: - Top IP Entry

struct TopIPEntry: Identifiable, Hashable {
    let id = UUID()
    let ip: String
    let count: Int
    let country: String?
}

// MARK: - Status Code Distribution

struct StatusCodeEntry: Identifiable, Hashable {
    let id = UUID()
    let code: Int
    let count: Int
    let percentage: Double

    var category: String {
        switch code {
        case 200..<300: return "Success"
        case 300..<400: return "Redirect"
        case 400..<500: return "Client Error"
        case 500..<600: return "Server Error"
        default: return "Other"
        }
    }

    var color: Color {
        switch code {
        case 200..<300: return .axSuccess
        case 300..<400: return .axAccentBlue
        case 400..<500: return .axWarning
        case 500..<600: return .axError
        default: return .axTextMuted
        }
    }
}

// MARK: - Bandwidth Data

struct SiteBandwidthData: Identifiable {
    let id = UUID()
    let totalBytes: Int64
    let period: String  // e.g., "Today", "This Week"

    var formatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
}

// MARK: - Bot Traffic Entry

struct BotTrafficEntry: Identifiable, Hashable {
    let id = UUID()
    let botName: String
    let requestCount: Int
    let percentage: Double
    let isKnownGood: Bool   // Googlebot, Bingbot, etc.

    var color: Color {
        isKnownGood ? .axSuccess : .axWarning
    }
}

// MARK: - Monitoring Tab

enum MonitoringTab: String, CaseIterable, Identifiable {
    case health = "Health"
    case traffic = "Traffic"
    case errors = "Errors"
    case bandwidth = "Bandwidth"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .traffic: return "person.2.fill"
        case .errors: return "exclamationmark.triangle.fill"
        case .bandwidth: return "arrow.up.arrow.down"
        }
    }
}
