//
//  CronViewModel.swift
//  AevonX
//
//  ViewModel for the Cron Management tab.
//  Uses Go Core via AevonXCoreBridge for all business logic.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class CronViewModel: ObservableObject {
    let serverId: String

    @Published var jobs: [CronJob] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: CronTaskType?

    // Add/Edit
    @Published var showAddSheet = false
    @Published var editingJob: CronJob?

    // Logs
    @Published var showLogSheet = false
    @Published var logJob: CronJob?
    @Published var logEntries: [CronLogEntry] = []
    @Published var isLoadingLogs = false

    // Execute
    @Published var executingJobId: UUID?
    @Published var executeOutput: String?
    @Published var showExecuteResult = false

    // Script Library
    @Published var scriptTemplates: [ScriptTemplate] = []
    @Published var selectedScriptCategory: ScriptCategory?

    // Message
    @Published var toastMessage: (String, Bool)?

    // Bridge references
    private let bridge = CronBridge.shared

    // Default cron directory (matches Core Swift fallback)
    private let defaultCronDir = "/var/log/aevonx/cron"

    var filteredJobs: [CronJob] {
        var result = jobs
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.command.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.taskType == cat }
        }
        return result
    }

    var filteredScripts: [ScriptTemplate] {
        guard let cat = selectedScriptCategory else { return scriptTemplates }
        return scriptTemplates.filter { $0.category == cat }
    }

    var activeJobsCount: Int { jobs.filter { $0.isEnabled }.count }
    var disabledJobsCount: Int { jobs.filter { !$0.isEnabled }.count }

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - Paths

    private var scriptDir: String { "\(defaultCronDir)/scripts" }
    private var logDir: String { defaultCronDir }

    // MARK: - Load Jobs

    func loadJobs() async {
        isLoading = true
        defer { isLoading = false }

        // Step 1: Get list command from Go Core
        let listCmd = bridge.listJobsCmd()
        guard !listCmd.isEmpty else {
            errorMessage = "Failed to get cron list command"
            return
        }

        // Step 2: Execute via SSH
        let stdout = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: listCmd
        )

        // Step 3: Parse crontab via Go Core
        let response = bridge.parseCrontab(output: stdout)
        guard response.success, let jsonData = response.data else {
            errorMessage = "Failed to parse crontab"
            return
        }

        // Step 4: Decode into CronJob array
        do {
            var parsed = try JSONDecoder().decode([CronJob].self, from: jsonData)

            // Step 5: For AevonX-managed jobs, read script content
            for i in parsed.indices {
                let cmd = parsed[i].command.trimmingCharacters(in: .whitespaces)
                if cmd.contains("\(scriptDir)/") || cmd.contains("/scripts/") {
                    // Extract script path
                    var scriptPath = cmd
                        .replacingOccurrences(of: "/bin/bash ", with: "")
                        .replacingOccurrences(of: "bash ", with: "")
                    if let redirectRange = scriptPath.range(of: " >>") {
                        scriptPath = String(scriptPath[..<redirectRange.lowerBound])
                    }
                    scriptPath = scriptPath.trimmingCharacters(in: .whitespaces)

                    // Read actual script content via SSH
                    let catOutput = await SSHBridge.shared.executeAsync(
                        serverID: serverId,
                        command: "cat \(scriptPath) 2>/dev/null || echo ''"
                    )
                    let content = catOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        let wrapperPrefixes = ["#!/bin/bash", "PATH=", "LOGFILE=", "mkdir -p", "exec >>", "echo \"---["]
                        let userLines = content.components(separatedBy: "\n").filter { line in
                            let t = line.trimmingCharacters(in: .whitespaces)
                            return !wrapperPrefixes.contains(where: { t.hasPrefix($0) }) && t != "echo \"---[END]---\""
                        }
                        let userCode = userLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        parsed[i].command = userCode.isEmpty ? content : userCode
                    }
                }
            }

            jobs = parsed
        } catch {
            errorMessage = "Decode error: \(error.localizedDescription)"
        }
    }

    // MARK: - Script Library

    func loadScriptLibrary() {
        let response = bridge.getScriptLibrary()
        guard response.success, let jsonData = response.data else { return }
        do {
            scriptTemplates = try JSONDecoder().decode([ScriptTemplate].self, from: jsonData)
        } catch {
            // Silent fail — templates are optional
        }
    }

    // MARK: - Add Job

    func addJob(_ job: CronJob) async {
        // Step 1: Write script to server
        let writeCmds = bridge.writeScriptCmds(
            scriptDir: scriptDir, logDir: logDir,
            jobID: job.id.uuidString, userScript: job.command
        )
        for cmd in writeCmds {
            let _ = await SSHBridge.shared.executeAsync(
                serverID: serverId, command: cmd
            )
        }

        // Step 2: Add crontab entry
        let scriptPath = "\(scriptDir)/\(job.id.uuidString).sh"
        let addCmd = bridge.addJobCmd(
            minute: job.schedule.minute, hour: job.schedule.hour,
            dom: job.schedule.dayOfMonth, month: job.schedule.month,
            dow: job.schedule.dayOfWeek, scriptPath: scriptPath,
            jobName: job.name, taskType: job.taskType.rawValue
        )
        let _ = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: addCmd
        )

        // Step 3: Ensure cron service is running
        let ensureCmd = bridge.ensureRunningCmd()
        let _ = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: ensureCmd
        )

        showToast("Task added: \(job.name)", success: true)
        await loadJobs()
    }

    // MARK: - Delete Job

    func deleteJob(_ job: CronJob) async {
        // Step 1: Remove crontab entry
        let rawLine = job.rawLine ?? job.cronLine
        let delCmd = bridge.deleteJobCmd(rawLine: rawLine)
        let _ = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: delCmd
        )

        // Step 2: Remove script file
        let delScript = bridge.deleteScriptCmd(
            scriptDir: scriptDir, jobID: job.id.uuidString
        )
        let _ = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: delScript
        )

        showToast("Deleted: \(job.name)", success: true)
        await loadJobs()
    }

    // MARK: - Toggle Job

    func toggleJob(_ job: CronJob) async {
        guard let rawLine = job.rawLine, !rawLine.isEmpty else { return }
        let cmd = bridge.toggleJobCmd(rawLine: rawLine, enable: !job.isEnabled)
        let _ = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: cmd
        )
        await loadJobs()
    }

    // MARK: - Execute Now

    func executeNow(_ job: CronJob) async {
        executingJobId = job.id
        defer { executingJobId = nil }

        // Write/update script first
        let writeCmds = bridge.writeScriptCmds(
            scriptDir: scriptDir, logDir: logDir,
            jobID: job.id.uuidString, userScript: job.command
        )
        for cmd in writeCmds {
            let _ = await SSHBridge.shared.executeAsync(
                serverID: serverId, command: cmd
            )
        }

        // Execute
        let scriptPath = "\(scriptDir)/\(job.id.uuidString).sh"
        let execCmd = bridge.executeNowCmd(scriptPath: scriptPath)
        let output = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: execCmd
        )

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        executeOutput = trimmed.isEmpty ? "Script executed successfully (no output)" : trimmed
        showExecuteResult = true
    }

    // MARK: - Logs

    func loadLogs(for job: CronJob) async {
        logJob = job
        isLoadingLogs = true
        showLogSheet = true
        defer { isLoadingLogs = false }

        let readCmd = bridge.readLogCmd(logDir: logDir, jobID: job.id.uuidString)
        let stdout = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: readCmd
        )

        // Parse log output via Go Core
        let response = bridge.parseLogOutput(output: stdout)
        guard response.success, let jsonData = response.data else {
            logEntries = []
            return
        }
        do {
            logEntries = try JSONDecoder().decode([CronLogEntry].self, from: jsonData)
        } catch {
            logEntries = []
        }
    }

    func clearLogs(for job: CronJob) async {
        let cmd = bridge.clearLogCmd(logDir: logDir, jobID: job.id.uuidString)
        let _ = await SSHBridge.shared.executeAsync(
            serverID: serverId, command: cmd
        )
        logEntries = []
        showToast("Logs cleared", success: true)
    }

    // MARK: - Import Template

    func importTemplate(_ template: ScriptTemplate) {
        var job = CronJob()
        job.name = template.name
        job.taskType = template.taskType
        job.schedule = template.defaultSchedule
        job.command = template.script
        editingJob = job
        showAddSheet = true
    }

    // MARK: - Toast

    private func showToast(_ msg: String, success: Bool) {
        toastMessage = (msg, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.toastMessage = nil }
    }
}
