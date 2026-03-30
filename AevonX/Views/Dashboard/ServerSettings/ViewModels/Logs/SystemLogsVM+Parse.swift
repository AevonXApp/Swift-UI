//
//  SystemLogsVM+Parse.swift
//  AevonX
//
//  Parsing logic for system logs and cron snapshots.
//

import Foundation

extension SystemLogsVM {

    func parseLogsSnapshot(_ sections: [String: String]) {
        parseLogSizes(sections["LOGSIZES"] ?? "")
        parseLogSources(sections["SOURCES"] ?? "")
    }

    private func parseLogSizes(_ s: String) {
        logSizes = s.split(separator: "\n").compactMap { line in
            let parts = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 2 else { return nil }
            return LogFileSize(path: parts[1], size: parts[0])
        }
    }

    private func parseLogSources(_ s: String) {
        var sources = s.split(separator: "\n").map(String.init)
        if !sources.contains("journalctl") {
            sources.insert("journalctl", at: 0)
        }
        logSources = sources
    }

    func parseCronSnapshot(_ sections: [String: String]) {
        parseServerCronJobs(sections["CRONJOBS"] ?? "")
        systemCron = sections["SYSTEMCRON"] ?? ""
        parseCronLogs(sections["CRONLOG"] ?? "")
    }

    private func parseServerCronJobs(_ s: String) {
        var lineCounter: [String: Int] = [:]
        cronJobs = s.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let user = String(parts[0])
            let cronLine = String(parts[1]).trimmingCharacters(in: .whitespaces)
            guard !cronLine.isEmpty else { return nil }

            let count = (lineCounter[user] ?? 0) + 1
            lineCounter[user] = count

            let isDisabled = cronLine.hasPrefix("#")
            let cleaned = isDisabled ? String(cronLine.dropFirst()).trimmingCharacters(in: .whitespaces) : cronLine

            // Parse schedule (first 5 fields) and command (rest)
            let cronParts = cleaned.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard cronParts.count >= 6 else { return nil }
            let schedule = cronParts[0..<5].joined(separator: " ")
            let command = cronParts[5...].joined(separator: " ")

            return ServerCronJob(
                user: user, schedule: schedule, command: command,
                lineNum: count, isDisabled: isDisabled
            )
        }
    }

    private func parseCronLogs(_ s: String) {
        cronLogs = s.split(separator: "\n").map { ServerCronLogEntry(line: String($0)) }
    }
}
