//
//  LogsCronModels.swift
//  AevonX
//
//  Data models for system logs and cron jobs.
//

import SwiftUI

// MARK: - Log File Size

struct LogFileSize: Identifiable {
    let id = UUID()
    let path: String
    let size: String

    var filename: String {
        path.split(separator: "/").last.map(String.init) ?? path
    }
}

// MARK: - Cron Job

struct ServerCronJob: Identifiable {
    let id = UUID()
    let user: String
    let schedule: String
    let command: String
    let lineNum: Int
    let isDisabled: Bool
}

// MARK: - Cron Log Entry

struct ServerCronLogEntry: Identifiable {
    let id = UUID()
    let line: String
}

// MARK: - Log Priority

enum LogPriority: String, CaseIterable {
    case all = ""
    case err = "err"
    case warning = "warning"
    case info = "info"
    case debug = "debug"

    var label: String {
        switch self {
        case .all: return L10n.ServerSettings.priorityAll
        case .err: return L10n.ServerSettings.priorityError
        case .warning: return L10n.ServerSettings.priorityWarning
        case .info: return L10n.ServerSettings.priorityInfo
        case .debug: return L10n.ServerSettings.priorityDebug
        }
    }
}
