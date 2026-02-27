//
//  ScheduledBackupViewModel.swift
//  AevonX
//
//  ViewModel for scheduled backup management — delegates to SiteScheduledBackupService
//

import SwiftUI
import Combine
import AevonXCore

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
    private let service = SiteScheduledBackupService.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func loadSchedules() async {
        isLoading = true; defer { isLoading = false }
        do {
            let list = try await service.listScheduledBackups(domain: domain, serverId: serverId)
            schedules = list.map { ScheduledBackupItem(frequency: $0.frequency, cronExpression: $0.cronExpression, includesDatabase: $0.includesDatabase, displayText: $0.frequencyDisplay) }
        } catch { schedules = [] }
    }

    func createSchedule() async {
        isLoading = true; defer { isLoading = false }
        do {
            try await service.createSchedule(domain: domain, docRoot: docRoot, frequency: selectedFrequency, retentionDays: retentionDays, includeDB: includeDatabase, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Scheduled \(selectedFrequency) backup created")
            await loadSchedules()
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func deleteSchedule(_ schedule: ScheduledBackupItem) async {
        do {
            try await service.deleteSchedule(domain: domain, frequency: schedule.frequency, serverId: serverId)
            schedules.removeAll { $0.id == schedule.id }
            GlobalToastManager.shared.showSuccess("Schedule removed")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func runBackupNow() async {
        isLoading = true; defer { isLoading = false }
        do {
            let filename = try await service.runNow(domain: domain, docRoot: docRoot, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Backup created: \(filename)")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
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
