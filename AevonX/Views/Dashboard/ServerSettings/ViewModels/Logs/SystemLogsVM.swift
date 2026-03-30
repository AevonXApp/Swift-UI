//
//  SystemLogsVM.swift
//  AevonX
//
//  ViewModel for system logs viewer and cron job management.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class SystemLogsVM: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - Logs
    @Published var logSizes: [LogFileSize] = []
    @Published var logSources: [String] = []
    @Published var selectedSource = "syslog"
    @Published var selectedPriority: LogPriority = .all
    @Published var logServiceFilter = ""
    @Published var logSearchText = ""
    @Published var logLines: Int32 = 50
    @Published var logContent = ""
    @Published var isLoadingLogs = false

    // MARK: - Cron
    @Published var cronJobs: [ServerCronJob] = []
    @Published var systemCron = ""
    @Published var cronLogs: [ServerCronLogEntry] = []
    @Published var newCronUser = "root"
    @Published var newCronSchedule = "0 * * * *"
    @Published var newCronCommand = ""

    // MARK: - State
    @Published var isLoading = true
    @Published var isLoadingCron = true
    @Published var saveMsg: (String, Bool)? = nil

    var isConnected: Bool {
        SSHBridge.shared.isConnected(serverID: serverId)
    }

    init(serverId: String) {
        self.serverId = serverId
    }

    func ssh(_ cmd: String) async -> String {
        guard !cmd.isEmpty else { return "" }
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: cmd)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Load

    func loadLogsSnapshot() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        let cmd = await service.systemLogsSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseLogsSnapshot(sections)
    }

    func queryLogs() async {
        isLoadingLogs = true
        defer { isLoadingLogs = false }
        let cmd = await service.systemLogsQueryCmd(
            source: selectedSource, priority: selectedPriority.rawValue,
            service: logServiceFilter, search: logSearchText, lines: logLines
        )
        logContent = await ssh(cmd)
    }

    func clearLog(_ source: String) async {
        let cmd = await service.systemLogsClearCmd(source: source)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.logCleared, true)
            await loadLogsSnapshot()
        } else {
            showMsg(L10n.ServerSettings.logClearFailed, false)
        }
    }

    func loadCron() async {
        guard isConnected else { return }
        isLoadingCron = true
        defer { isLoadingCron = false }
        let cmd = await service.cronSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseCronSnapshot(sections)
    }

    func addServerCronJob() async {
        guard !newCronCommand.isEmpty else { return }
        let cmd = await service.cronAddCmd(
            user: newCronUser, schedule: newCronSchedule, command: newCronCommand
        )
        let out = await ssh(cmd)
        if out.contains("OK") {
            newCronCommand = ""
            showMsg(L10n.ServerSettings.cronJobAdded, true)
            await loadCron()
        } else {
            showMsg(L10n.ServerSettings.cronJobAddFailed, false)
        }
    }

    func deleteServerCronJob(_ job: ServerCronJob) async {
        let cmd = await service.cronDeleteCmd(user: job.user, lineNum: Int32(job.lineNum))
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.cronJobDeleted, true)
            await loadCron()
        } else {
            showMsg(L10n.ServerSettings.cronJobDeleteFailed, false)
        }
    }

    private func showMsg(_ text: String, _ success: Bool) {
        saveMsg = (text, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.saveMsg = nil }
    }
}
