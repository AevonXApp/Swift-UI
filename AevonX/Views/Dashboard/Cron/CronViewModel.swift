//
//  CronViewModel.swift
//  AevonX
//
//  ViewModel for the Cron Management tab
//

import SwiftUI
import Combine
import AevonXCore

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
    
    var filteredJobs: [CronJob] {
        var result = jobs
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.command.localizedCaseInsensitiveContains(searchText) }
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
    
    func loadJobs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            jobs = try await CronService.shared.listJobs(serverId: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadScriptLibrary() {
        Task {
            scriptTemplates = await CronService.shared.getScriptLibrary()
        }
    }
    
    func addJob(_ job: CronJob) async {
        do {
            try await CronService.shared.addJob(job, serverId: serverId)
            showToast("Task added: \(job.name)", success: true)
            await loadJobs()
        } catch {
            showToast("Failed: \(error.localizedDescription)", success: false)
        }
    }
    
    func deleteJob(_ job: CronJob) async {
        do {
            try await CronService.shared.deleteJob(job, serverId: serverId)
            showToast("Deleted: \(job.name)", success: true)
            await loadJobs()
        } catch {
            showToast("Failed to delete", success: false)
        }
    }
    
    func toggleJob(_ job: CronJob) async {
        do {
            try await CronService.shared.toggleJob(job, enable: !job.isEnabled, serverId: serverId)
            await loadJobs()
        } catch {
            showToast("Failed to toggle", success: false)
        }
    }
    
    func executeNow(_ job: CronJob) async {
        executingJobId = job.id
        defer { executingJobId = nil }
        do {
            let output = try await CronService.shared.executeNow(job, serverId: serverId)
            executeOutput = output
            showExecuteResult = true
        } catch {
            showToast("Execution failed: \(error.localizedDescription)", success: false)
        }
    }
    
    func loadLogs(for job: CronJob) async {
        logJob = job
        isLoadingLogs = true
        showLogSheet = true
        defer { isLoadingLogs = false }
        do {
            logEntries = try await CronService.shared.getLogs(for: job, serverId: serverId)
        } catch {
            logEntries = []
        }
    }
    
    func clearLogs(for job: CronJob) async {
        do {
            try await CronService.shared.clearLogs(for: job, serverId: serverId)
            logEntries = []
            showToast("Logs cleared", success: true)
        } catch {
            showToast("Failed to clear logs", success: false)
        }
    }
    
    func importTemplate(_ template: ScriptTemplate) {
        var job = CronJob()
        job.name = template.name
        job.taskType = template.taskType
        job.schedule = template.defaultSchedule
        job.command = template.script
        editingJob = job
        showAddSheet = true
    }
    
    private func showToast(_ msg: String, success: Bool) {
        toastMessage = (msg, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.toastMessage = nil }
    }
}
