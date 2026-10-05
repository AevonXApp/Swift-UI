//
//  CronModels.swift
//  AevonXCoreBridge
//
//  UI-facing Codable models for Cron management.
//  These decode JSON produced by Go Core via CronBridge.
//

import Foundation

// MARK: - Cron Task Type

/// Cron task types matching Go Core CronTaskType constants.
public enum CronTaskType: String, CaseIterable, Identifiable, Codable {
    case shellScript = "Shell Script"
    case backupWebsite = "Backup Website"
    case backupDatabase = "Backup Database"
    case backupDirectory = "Backup Directory"
    case cutLog = "Cut/Rotate Logs"
    case syncTime = "Sync Time"
    case freeRAM = "Free RAM"
    case accessURL = "Access URL"
    case sslRenewal = "SSL Renewal"
    case diskCleanup = "Disk Cleanup"
    case dbOptimization = "DB Optimization"
    case systemUpdate = "System Update"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .shellScript: return "terminal"
        case .backupWebsite: return "globe"
        case .backupDatabase: return "cylinder.split.1x2"
        case .backupDirectory: return "folder"
        case .cutLog: return "doc.text.magnifyingglass"
        case .syncTime: return "clock.arrow.2.circlepath"
        case .freeRAM: return "memorychip"
        case .accessURL: return "link"
        case .sslRenewal: return "lock.shield"
        case .diskCleanup: return "trash"
        case .dbOptimization: return "wand.and.stars"
        case .systemUpdate: return "arrow.down.circle"
        }
    }

    public var color: String {
        switch self {
        case .shellScript: return "axTextSecondary"
        case .backupWebsite: return "axAccentBlue"
        case .backupDatabase: return "axAccentGreen"
        case .backupDirectory: return "axWarning"
        case .cutLog: return "purple"
        case .syncTime: return "cyan"
        case .freeRAM: return "orange"
        case .accessURL: return "teal"
        case .sslRenewal: return "axSuccess"
        case .diskCleanup: return "axError"
        case .dbOptimization: return "indigo"
        case .systemUpdate: return "axAccentBlue"
        }
    }

    /// Default script template for this task type.
    /// Calls Go Core to generate the script.
    public func defaultScript(param: String = "") -> String {
        CronBridge.shared.defaultScript(taskType: rawValue, param: param)
    }
}

// MARK: - Cron Schedule

/// 5-field cron schedule expression.
public struct CronSchedule: Codable, Equatable {
    public var minute: String
    public var hour: String
    public var dayOfMonth: String
    public var month: String
    public var dayOfWeek: String

    public init(
        minute: String = "*",
        hour: String = "*",
        dayOfMonth: String = "*",
        month: String = "*",
        dayOfWeek: String = "*"
    ) {
        self.minute = minute
        self.hour = hour
        self.dayOfMonth = dayOfMonth
        self.month = month
        self.dayOfWeek = dayOfWeek
    }

    enum CodingKeys: String, CodingKey {
        case minute
        case hour
        case dayOfMonth = "day_of_month"
        case month
        case dayOfWeek = "day_of_week"
    }

    public var expression: String {
        "\(minute) \(hour) \(dayOfMonth) \(month) \(dayOfWeek)"
    }

    public var humanReadable: String {
        if minute == "*" && hour == "*" && dayOfMonth == "*" && month == "*" && dayOfWeek == "*" {
            return "Every minute"
        }
        if minute == "0" && hour == "*" {
            return "Every hour"
        }
        if minute != "*" && hour != "*" && dayOfMonth == "*" && month == "*" && dayOfWeek == "*" {
            return "Daily at \(hour.leftPad(2)):\(minute.leftPad(2))"
        }
        if minute != "*" && hour != "*" && dayOfWeek != "*" && dayOfMonth == "*" {
            let days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            let dayName = Int(dayOfWeek).flatMap { $0 < days.count ? days[$0] : nil } ?? dayOfWeek
            return "Every \(dayName) at \(hour.leftPad(2)):\(minute.leftPad(2))"
        }
        if minute.hasPrefix("*/") {
            return "Every \(String(minute.dropFirst(2))) minutes"
        }
        if hour.hasPrefix("*/") {
            return "Every \(String(hour.dropFirst(2))) hours"
        }
        return expression
    }

    // Preset schedules
    public static let everyMinute = CronSchedule()
    public static let every5Minutes = CronSchedule(minute: "*/5")
    public static let every15Minutes = CronSchedule(minute: "*/15")
    public static let every30Minutes = CronSchedule(minute: "*/30")
    public static let hourly = CronSchedule(minute: "0")
    public static let daily = CronSchedule(minute: "0", hour: "2")
    public static let weekly = CronSchedule(minute: "0", hour: "2", dayOfWeek: "0")
    public static let monthly = CronSchedule(minute: "0", hour: "2", dayOfMonth: "1")
}

fileprivate extension String {
    func leftPad(_ length: Int, with char: Character = "0") -> String {
        let needed = length - count
        guard needed > 0 else { return self }
        return String(repeating: char, count: needed) + self
    }
}

// MARK: - Cron Job

/// A cron job parsed from crontab output.
public struct CronJob: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var taskType: CronTaskType
    public var schedule: CronSchedule
    public var command: String
    public var executeUser: String
    public var isEnabled: Bool
    public var lastExecuted: String?
    public var lastStatus: CronJobStatus?
    public var rawLine: String?

    public init(
        id: UUID = UUID(),
        name: String = "",
        taskType: CronTaskType = .shellScript,
        schedule: CronSchedule = .daily,
        command: String = "",
        executeUser: String = "root",
        isEnabled: Bool = true,
        lastExecuted: String? = nil,
        lastStatus: CronJobStatus? = nil,
        rawLine: String? = nil
    ) {
        self.id = id
        self.name = name
        self.taskType = taskType
        self.schedule = schedule
        self.command = command
        self.executeUser = executeUser
        self.isEnabled = isEnabled
        self.lastExecuted = lastExecuted
        self.lastStatus = lastStatus
        self.rawLine = rawLine
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case taskType = "task_type"
        case schedule
        case command
        case executeUser = "execute_user"
        case isEnabled = "is_enabled"
        case lastExecuted = "last_executed"
        case lastStatus = "last_status"
        case rawLine = "raw_line"
    }

    /// Custom decode to handle Go Core's string ID → UUID conversion.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Go Core sends ID as string; convert to UUID or generate new
        if let idStr = try container.decodeIfPresent(String.self, forKey: .id),
           let parsed = UUID(uuidString: idStr) {
            self.id = parsed
        } else {
            self.id = UUID()
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.taskType = try container.decode(CronTaskType.self, forKey: .taskType)
        self.schedule = try container.decode(CronSchedule.self, forKey: .schedule)
        self.command = try container.decode(String.self, forKey: .command)
        self.executeUser = try container.decodeIfPresent(String.self, forKey: .executeUser) ?? "root"
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.lastExecuted = try container.decodeIfPresent(String.self, forKey: .lastExecuted)
        self.lastStatus = try container.decodeIfPresent(CronJobStatus.self, forKey: .lastStatus)
        self.rawLine = try container.decodeIfPresent(String.self, forKey: .rawLine)
    }

    /// The full crontab line.
    public var cronLine: String {
        let prefix = isEnabled ? "" : "#"
        return "\(prefix)\(schedule.expression) \(command) # AevonX:\(name):\(taskType.rawValue)"
    }
}

// MARK: - Cron Job Status

public enum CronJobStatus: String, Codable {
    case success = "Success"
    case failed = "Failed"
    case running = "Running"
    case unknown = "Unknown"
}

// MARK: - Execution Log Entry

public struct CronLogEntry: Identifiable, Codable {
    public var id: UUID
    public var timestamp: String
    public var output: String
    public var isSuccess: Bool

    public init(id: UUID = UUID(), timestamp: String, output: String, isSuccess: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.output = output
        self.isSuccess = isSuccess
    }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case output
        case isSuccess = "is_success"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
        self.output = try container.decode(String.self, forKey: .output)
        self.isSuccess = try container.decode(Bool.self, forKey: .isSuccess)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(output, forKey: .output)
        try container.encode(isSuccess, forKey: .isSuccess)
    }
}

// MARK: - Script Template

public struct ScriptTemplate: Identifiable, Codable {
    public var id: String
    public var name: String
    public var category: ScriptCategory
    public var description: String
    public var taskType: CronTaskType
    public var script: String
    public var defaultSchedule: CronSchedule

    public init(
        id: String,
        name: String,
        category: ScriptCategory,
        description: String,
        taskType: CronTaskType,
        script: String,
        defaultSchedule: CronSchedule
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.taskType = taskType
        self.script = script
        self.defaultSchedule = defaultSchedule
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case taskType = "task_type"
        case script
        case defaultSchedule = "default_schedule"
    }
}

// MARK: - Script Category

public enum ScriptCategory: String, CaseIterable, Identifiable, Codable {
    case serviceManagement = "Service Management"
    case monitoring = "Monitoring"
    case backup = "Backup"
    case maintenance = "Maintenance"
    case security = "Security"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .serviceManagement: return "gearshape.2"
        case .monitoring: return "chart.line.uptrend.xyaxis"
        case .backup: return "externaldrive"
        case .maintenance: return "wrench.and.screwdriver"
        case .security: return "lock.shield"
        }
    }
}
