//
//  TrafficAnalytics.swift
//  AevonX
//
//  UI layer extensions for traffic analytics
//  Core types are defined in AevonXCore
//

import Foundation
import SwiftUI
import AevonXCoreBridge

// MARK: - Traffic Analytics Types (local definitions)

public enum TimeRange: String, Codable, Sendable {
    case lastHour = "Last Hour"
    case last24Hours = "Last 24 Hours"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case custom = "Custom Range"
}

public struct RequestStatistics: Codable, Sendable {
    public var totalRequests: Int
    public var requestsByMethod: [String: Int]
    public var requestsByStatus: [String: Int]
    public var averageResponseTime: Double
    public var errorRate: Double
    public var timeRange: TimeRange
    public var timestamp: Date

    public init(totalRequests: Int = 0, requestsByMethod: [String: Int] = [:], requestsByStatus: [String: Int] = [:], averageResponseTime: Double = 0, errorRate: Double = 0, timeRange: TimeRange = .lastHour, timestamp: Date = Date()) {
        self.totalRequests = totalRequests
        self.requestsByMethod = requestsByMethod
        self.requestsByStatus = requestsByStatus
        self.averageResponseTime = averageResponseTime
        self.errorRate = errorRate
        self.timeRange = timeRange
        self.timestamp = timestamp
    }
}

public struct BandwidthDataPoint: Codable, Sendable, Identifiable {
    public let id: UUID
    public var timestamp: Date
    public var bytesIn: Int
    public var bytesOut: Int

    public init(id: UUID = UUID(), timestamp: Date, bytesIn: Int, bytesOut: Int) {
        self.id = id
        self.timestamp = timestamp
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

public struct EndpointStat: Codable, Sendable, Identifiable {
    public let id: UUID
    public var endpoint: String
    public var requestCount: Int
    public var averageResponseTime: Double
    public var errorCount: Int
    public var lastAccessed: Date?

    public init(id: UUID = UUID(), endpoint: String, requestCount: Int, averageResponseTime: Double, errorCount: Int, lastAccessed: Date? = nil) {
        self.id = id
        self.endpoint = endpoint
        self.requestCount = requestCount
        self.averageResponseTime = averageResponseTime
        self.errorCount = errorCount
        self.lastAccessed = lastAccessed
    }
}

// MARK: - UI Layer Extensions

extension RequestStatistics {
    /// Success rate (percentage)
    public var successRate: Double {
        100.0 - errorRate
    }

    /// Most common HTTP method
    public var topMethod: String? {
        requestsByMethod.max(by: { $0.value < $1.value })?.key
    }

    /// Most common status code
    public var topStatusCode: String? {
        requestsByStatus.max(by: { $0.value < $1.value })?.key
    }

    /// Formatted average response time
    public var formattedResponseTime: String {
        AXFormatter.formatResponseTime(averageResponseTime)
    }
}

extension BandwidthDataPoint {
    /// Total bytes transferred
    public var totalBytes: Int {
        bytesIn + bytesOut
    }

    /// Formatted bytes in
    public var formattedBytesIn: String {
        AXFormatter.formatBytes(Int64(bytesIn))
    }

    /// Formatted bytes out
    public var formattedBytesOut: String {
        AXFormatter.formatBytes(Int64(bytesOut))
    }

    /// Formatted total
    public var formattedTotal: String {
        AXFormatter.formatBytes(Int64(totalBytes))
    }
}

extension EndpointStat {
    /// Error rate for this endpoint
    public var errorRate: Double {
        guard requestCount > 0 else { return 0 }
        return (Double(errorCount) / Double(requestCount)) * 100.0
    }

    /// Success count
    public var successCount: Int {
        requestCount - errorCount
    }

    /// Formatted response time
    public var formattedResponseTime: String {
        AXFormatter.formatResponseTime(averageResponseTime)
    }

    /// Health status based on error rate and response time
    public var healthStatus: EndpointHealth {
        if errorRate > 10 || averageResponseTime > 5000 {
            return .critical
        } else if errorRate > 5 || averageResponseTime > 2000 {
            return .warning
        } else {
            return .healthy
        }
    }
}

extension TimeRange {
    public var seconds: Int {
        switch self {
        case .lastHour: return 3600
        case .last24Hours: return 86400
        case .last7Days: return 604800
        case .last30Days: return 2592000
        case .custom: return 0
        }
    }

    public var icon: String {
        switch self {
        case .lastHour: return "clock"
        case .last24Hours: return "calendar.day.timeline.left"
        case .last7Days: return "calendar"
        case .last30Days: return "calendar.badge.clock"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Endpoint Health

public enum EndpointHealth: String, Codable {
    case healthy = "Healthy"
    case warning = "Warning"
    case critical = "Critical"

    public var color: Color {
        switch self {
        case .healthy: return .axSuccess
        case .warning: return .axWarning
        case .critical: return .axError
        }
    }

    public var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}
