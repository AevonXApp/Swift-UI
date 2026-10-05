//
//  AXFormatter.swift
//  AevonXCoreBridge
//
//  Centralized formatting utilities for the entire AevonX platform.
//  Handles: bytes, sizes (MB-based), durations/uptimes, numbers, percentages.
//
//  Copied from AevonXCore to eliminate AevonXCore dependency.
//

import Foundation

// MARK: - AXFormatter

public enum AXFormatter {

    // MARK: - Bytes (raw byte count → human readable)

    /// Format raw byte count: 1536 → "1.5 KB", 1073741824 → "1.0 GB"
    public static func formatBytes(_ bytes: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = abs(bytes)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        if unitIndex == 0 {
            return "\(Int(value)) \(units[unitIndex])"
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }

    /// Convenience: format bytes from Int64
    public static func formatBytes(_ bytes: Int64) -> String {
        formatBytes(Double(bytes))
    }

    /// Convenience: format bytes from Int
    public static func formatBytes(_ bytes: Int) -> String {
        formatBytes(Double(bytes))
    }

    // MARK: - Size (MB-based → human readable)

    /// Format a size that is already in MB: 2048 → "2.00 GB", 0.5 → "0 MB"
    public static func formatSizeMB(_ megabytes: Double) -> String {
        if megabytes >= 1024 * 1024 {
            return String(format: "%.2f TB", megabytes / (1024 * 1024))
        } else if megabytes >= 1024 {
            return String(format: "%.2f GB", megabytes / 1024)
        } else {
            return String(format: "%.0f MB", megabytes)
        }
    }

    // MARK: - Duration / Uptime

    /// Format seconds into human-readable duration: 450 → "7m 30s", 90061 → "1d 1h 1m"
    public static func formatDuration(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        if totalSeconds < 0 { return "—" }
        if totalSeconds == 0 { return "0s" }
        if totalSeconds < 60 { return "\(totalSeconds)s" }

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return secs > 0 ? "\(minutes)m \(secs)s" : "\(minutes)m"
    }

    /// Format milliseconds into human-readable duration.
    public static func formatDuration(milliseconds: Double) -> String {
        formatDuration(seconds: milliseconds / 1000.0)
    }

    /// Format uptime from TimeInterval (seconds). Returns "Unknown" if nil.
    public static func formatUptime(_ uptime: TimeInterval?) -> String {
        guard let uptime = uptime else { return "Unknown" }
        let totalSeconds = Int(uptime)
        if totalSeconds <= 0 { return "0s" }

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Numbers

    /// Format large numbers: 1200 → "1.2K", 1500000 → "1.5M"
    public static func formatNumber(_ num: Double) -> String {
        if num >= 1_000_000_000 {
            return String(format: "%.1fB", num / 1_000_000_000)
        } else if num >= 1_000_000 {
            return String(format: "%.1fM", num / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", num / 1_000)
        }
        return num == num.rounded() ? String(Int(num)) : String(format: "%.1f", num)
    }

    /// Format any value to a human-readable string.
    public static func formatValue(_ value: Any) -> String {
        if let intVal = value as? Int {
            return formatNumber(Double(intVal))
        } else if let doubleVal = value as? Double {
            if doubleVal == doubleVal.rounded() && doubleVal < 1_000_000 {
                return formatNumber(doubleVal)
            }
            return String(format: "%.1f", doubleVal)
        } else if let stringVal = value as? String {
            if let num = Double(stringVal) {
                return formatNumber(num)
            }
            return stringVal
        }
        return "\(value)"
    }

    // MARK: - Percentage

    /// Format percentage: 99.0 → "99%", 55.7 → "55.7%"
    public static func formatPercent(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value))%"
        }
        return String(format: "%.1f%%", value)
    }

    // MARK: - CPU

    /// Format CPU usage: 45.3 → "45.3%"
    public static func formatCPU(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    // MARK: - Memory (process memory in KB → human readable)

    /// Format memory from KB (as reported by ps aux $6 column)
    public static func formatMemoryKB(_ kilobytes: Int64) -> String {
        let mb = Double(kilobytes) / 1024
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.1f MB", mb)
    }

    // MARK: - Null Safety

    /// Safely convert any optional value to a display string, handling NSNull and nil.
    public static func safeString(_ value: Any?) -> String {
        guard let value = value else { return "—" }
        if value is NSNull { return "—" }
        let str = String(describing: value)
        if str == "<null>" || str == "null" || str == "Optional(nil)" { return "—" }
        return str
    }

    // MARK: - Time Ago

    /// Format a Date into relative time: "5m ago", "2h ago", "3d ago"
    public static func formatTimeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }

    /// Format optional Date — returns fallback if nil
    public static func formatTimeAgo(_ date: Date?, fallback: String = "Never") -> String {
        guard let date = date else { return fallback }
        return formatTimeAgo(date)
    }

    // MARK: - Response Time

    /// Format response time (in milliseconds): 250 → "250 ms", 1500 → "1.50 s"
    public static func formatResponseTime(_ ms: Double) -> String {
        if ms < 1000 {
            return String(format: "%.0f ms", ms)
        }
        return String(format: "%.2f s", ms / 1000)
    }

    /// Format response time (in seconds): 0.25 → "250ms", 1.5 → "1.50s"
    public static func formatResponseTimeSeconds(_ seconds: Double) -> String {
        if seconds < 1.0 {
            return String(format: "%.0fms", seconds * 1000)
        }
        return String(format: "%.2fs", seconds)
    }
}

// MARK: - Backward Compatibility

typealias HookValueFormatter = AXFormatter
typealias PluginValueFormatter = AXFormatter
