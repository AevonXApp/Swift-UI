//
//  ResourceModels.swift
//  AevonX
//
//  Data models for resource monitoring.
//

import SwiftUI

// MARK: - Process Info

struct ServerProcessInfo: Identifiable {
    let id: String
    let user: String
    let pid: Int
    let cpuPercent: Double
    let memPercent: Double
    let command: String

    init(user: String, pid: Int, cpuPercent: Double, memPercent: Double, command: String) {
        self.id = "\(pid)"
        self.user = user
        self.pid = pid
        self.cpuPercent = cpuPercent
        self.memPercent = memPercent
        self.command = command
    }
}

// MARK: - Disk Partition (Enhanced)

struct DiskPartitionInfo: Identifiable {
    let id: String
    let mount: String
    let filesystem: String
    let size: String
    let used: String
    let available: String
    let usagePercent: Int
    var inodeUsedPercent: Int?

    init(mount: String, filesystem: String, size: String, used: String, available: String, usagePercent: Int) {
        self.id = mount
        self.mount = mount
        self.filesystem = filesystem
        self.size = size
        self.used = used
        self.available = available
        self.usagePercent = usagePercent
    }
}

// MARK: - Process Sort Mode

enum ProcessSortMode: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
}

// MARK: - Resource Color Helpers

enum ResourceColor {
    static func cpu(_ percent: Double) -> Color {
        percent > 85 ? .axError : percent > 60 ? .axWarning : .axSuccess
    }

    static func ram(_ percent: Double) -> Color {
        percent > 90 ? .axError : percent > 70 ? .axWarning : .axSuccess
    }

    static func swap(_ percent: Double) -> Color {
        percent > 70 ? .axError : percent > 30 ? .axWarning : .axSuccess
    }

    static func load(_ normalized: Double) -> Color {
        normalized > 1.0 ? .axError : normalized > 0.7 ? .axWarning : .axSuccess
    }

    static func disk(_ percent: Int) -> Color {
        percent > 90 ? .axError : percent > 70 ? .axWarning : .axSuccess
    }

    static func temp(_ celsius: Double) -> Color {
        celsius > 80 ? .axError : celsius > 60 ? .axWarning : .axSuccess
    }

    static func ioWait(_ percent: Double) -> Color {
        percent > 30 ? .axError : percent > 10 ? .axWarning : .axSuccess
    }
}

// MARK: - Byte Formatting

extension UInt64 {
    var humanReadable: String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(self)
        var idx = 0
        while size >= 1024 && idx < units.count - 1 { size /= 1024; idx += 1 }
        return String(format: "%.1f %@", size, units[idx])
    }
}

extension Double {
    var humanReadableRate: String {
        if self >= 1_048_576 { return String(format: "%.1f MB/s", self / 1_048_576) }
        if self >= 1024 { return String(format: "%.1f KB/s", self / 1024) }
        return String(format: "%.0f B/s", self)
    }
}
