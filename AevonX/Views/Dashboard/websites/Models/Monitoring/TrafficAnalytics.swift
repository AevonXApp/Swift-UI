//
//  TrafficAnalytics.swift
//  AevonX
//
//  UI layer extensions for traffic analytics
//  Core types are defined in AevonXCore
//

import Foundation
import AevonXCore

// MARK: - Type Aliases (Re-export from Core)

public typealias TimeRange = AevonXCore.TimeRange
public typealias RequestStatistics = AevonXCore.RequestStatistics
public typealias BandwidthDataPoint = AevonXCore.BandwidthDataPoint
public typealias EndpointStat = AevonXCore.EndpointStat

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
        if averageResponseTime < 1000 {
            return String(format: "%.0f ms", averageResponseTime)
        } else {
            return String(format: "%.2f s", averageResponseTime / 1000)
        }
    }
}

extension BandwidthDataPoint {
    /// Total bytes transferred
    public var totalBytes: Int {
        bytesIn + bytesOut
    }

    /// Formatted bytes in
    public var formattedBytesIn: String {
        ByteCountFormatter.string(fromByteCount: Int64(bytesIn), countStyle: .binary)
    }

    /// Formatted bytes out
    public var formattedBytesOut: String {
        ByteCountFormatter.string(fromByteCount: Int64(bytesOut), countStyle: .binary)
    }

    /// Formatted total
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .binary)
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
        if averageResponseTime < 1000 {
            return String(format: "%.0f ms", averageResponseTime)
        } else {
            return String(format: "%.2f s", averageResponseTime / 1000)
        }
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

    public var color: String {
        switch self {
        case .healthy: return "axSuccess"
        case .warning: return "axWarning"
        case .critical: return "axError"
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
