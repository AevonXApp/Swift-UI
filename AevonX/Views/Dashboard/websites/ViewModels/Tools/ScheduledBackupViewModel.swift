//
//  ScheduledBackupViewModel.swift
//  AevonX
//
//  ViewModel for scheduled backup management — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class ScheduledBackupViewModel: ObservableObject {
    @Published var schedules: [ScheduledBackupItem] = []
    @Published var selectedFrequency = "daily"
    @Published var retentionDays = 30
    @Published var includeDatabase = true
    @Published var isLoading = false

    let serverId: String
    let domain: String
    let docRoot: String
    private let bridge = WebsitesBridge.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func loadSchedules() async {
        isLoading = true; defer { isLoading = false }
        let cmd = bridge.listScheduledBackupsCmd(domain: domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseScheduledBackups(output: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let list = resp["data"] as? [[String: Any]] {
            schedules = list.compactMap { dict in
                guard let freq = dict["frequency"] as? String else { return nil }
                return ScheduledBackupItem(
                    frequency: freq,
                    cronExpression: dict["cron_expression"] as? String ?? "",
                    includesDatabase: dict["includes_database"] as? Bool ?? false,
                    displayText: dict["display_text"] as? String ?? freq.capitalized
                )
            }
        }
    }

    func createSchedule() async {
        isLoading = true; defer { isLoading = false }
        let cmd = bridge.createScheduledBackupCmd(
            domain: domain,
            docRoot: docRoot,
            frequency: selectedFrequency,
            retentionDays: retentionDays,
            includeDB: includeDatabase
        )
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        GlobalToastManager.shared.showSuccess("Scheduled \(selectedFrequency) backup created")
        await loadSchedules()
    }

    func deleteSchedule(_ schedule: ScheduledBackupItem) async {
        let cmd = bridge.deleteScheduledBackupCmd(domain: domain, frequency: schedule.frequency)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        schedules.removeAll { $0.id == schedule.id }
        GlobalToastManager.shared.showSuccess("Schedule removed")
    }

    func runBackupNow() async {
        isLoading = true; defer { isLoading = false }
        let cmds = bridge.backupSiteCmds(domain: domain, docRoot: docRoot)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        GlobalToastManager.shared.showSuccess("Backup created")
    }
}

// MARK: - UI Models

struct ScheduledBackupItem: Identifiable {
    let id = UUID()
    let frequency: String
    let cronExpression: String
    let includesDatabase: Bool
    let displayText: String
}
