//
//  ApplicationsListViewModel.swift
//  AevonX
//
//  ViewModel for the Applications list — manages state, loading &  actions
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
final class ApplicationsListViewModel: ObservableObject {
    // MARK: - Published State
    @Published var applications: [ApplicationInstance] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedApplication: ApplicationInstance?
    @Published var installingApplicationId: UUID?
    @Published var installProgressByAppId: [UUID: Double] = [:]
    @Published var installMessageByAppId: [UUID: String] = [:]
    @Published var appPendingUninstall: ApplicationInstance?

    /// AX Doctor diagnosis — set when a service action fails.
    @Published var doctorDiagnosis: DoctorDiagnosis?

    /// Currently running action (start/stop/restart) — shows spinner on that card
    @Published var actionInProgressId: UUID?

    // Search & Filter
    @Published var searchText: String = ""
    @Published var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case running = "Running"
        case stopped = "Stopped"
        case notInstalled = "Not Installed"
    }

    // MARK: - Dependencies
    let serverId: String?

    // MARK: - Computed
    var runningApps: [ApplicationInstance] { applications.filter { $0.isRunning } }
    var stoppedApps: [ApplicationInstance] { applications.filter { !$0.isRunning && $0.status != .notInstalled } }

    var filteredApplications: [ApplicationInstance] {
        var result = applications

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.type.rawValue.lowercased().contains(query)
            }
        }

        // Status filter
        switch statusFilter {
        case .all: break
        case .running: result = result.filter { $0.isRunning }
        case .stopped: result = result.filter { !$0.isRunning && $0.status != .notInstalled }
        case .notInstalled: result = result.filter { $0.status == .notInstalled }
        }

        return result
    }

    init(serverId: String?) {
        self.serverId = serverId
    }

    // MARK: - Cache
    private var lastLoadTime: Date?
    private let cacheTTL: TimeInterval = 30 // seconds

    var needsRefresh: Bool {
        guard let lastLoadTime else { return true }
        return Date().timeIntervalSince(lastLoadTime) > cacheTTL
    }

    // MARK: - Data Loading

    /// Load applications — uses cache if fresh, otherwise fetches from server
    func loadApplications(forceRefresh: Bool = false) async {
        guard let serverId else {
            errorMessage = "No server selected"
            return
        }

        guard forceRefresh || needsRefresh else { return }

        // Only show spinner on first load (no cached data)
        if applications.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        do {
            applications = try await GoApplicationService.shared.discoverInstalledApplications(serverId: serverId)
            lastLoadTime = Date()
        } catch {
            errorMessage = "Failed to load applications: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Service Actions

    /// Optimistic UI: update a specific app's state immediately
    private func updateAppState(_ id: UUID, isRunning: Bool, status: AevonXCoreBridge.ServiceStatus) {
        if let index = applications.firstIndex(where: { $0.id == id }) {
            applications[index].isRunning = isRunning
            applications[index].status = status
        }
    }

    /// Refresh only ONE app's real state instead of re-discovering all 14
    private func refreshSingleApp(_ type: ApplicationType) async {
        guard let serverId else { return }
        do {
            let freshApp = try await GoApplicationService.shared.getApplicationInfo(type: type, serverId: serverId)
            if let index = applications.firstIndex(where: { $0.type == type }) {
                applications[index] = freshApp
            }
        } catch {
            // Silent — optimistic state remains
        }
    }

    func startApplication(_ app: ApplicationInstance) async {
        guard let serverId else { return }
        actionInProgressId = app.id
        errorMessage = nil
        do {
            try await GoApplicationService.shared.startService(type: app.type, serverId: serverId)
            // If we get here, the service was started AND verified on the server
            updateAppState(app.id, isRunning: true, status: .active)
            await refreshSingleApp(app.type)
        } catch {
            let msg = error.localizedDescription
            if msg.contains("verification failed") {
                errorMessage = "\(app.name) command was sent but the service is not running. Diagnosing..."
            } else {
                errorMessage = "Failed to start \(app.name): \(msg)"
            }
            invokeDiagnostics(section: "applications", action: "start", target: app.type.rawValue, error: msg, serverId: serverId)
        }
        actionInProgressId = nil
    }

    func stopApplication(_ app: ApplicationInstance) async {
        guard let serverId else { return }
        actionInProgressId = app.id
        errorMessage = nil
        do {
            try await GoApplicationService.shared.stopService(type: app.type, serverId: serverId)
            // If we get here, the service was stopped AND verified on the server
            updateAppState(app.id, isRunning: false, status: .inactive)
            await refreshSingleApp(app.type)
        } catch {
            let msg = error.localizedDescription
            if msg.contains("verification failed") {
                errorMessage = "\(app.name) stop command was sent but the service is still running. Diagnosing..."
            } else {
                errorMessage = "Failed to stop \(app.name): \(msg)"
            }
            invokeDiagnostics(section: "applications", action: "stop", target: app.type.rawValue, error: msg, serverId: serverId)
        }
        actionInProgressId = nil
    }

    func restartApplication(_ app: ApplicationInstance) async {
        guard let serverId else { return }
        actionInProgressId = app.id
        errorMessage = nil
        do {
            try await GoApplicationService.shared.restartService(type: app.type, serverId: serverId)
            // If we get here, the service was restarted AND verified on the server
            updateAppState(app.id, isRunning: true, status: .active)
            await refreshSingleApp(app.type)
        } catch {
            let msg = error.localizedDescription
            if msg.contains("verification failed") {
                errorMessage = "\(app.name) restart was sent but the service is not running. Diagnosing..."
            } else {
                errorMessage = "Failed to restart \(app.name): \(msg)"
            }
            invokeDiagnostics(section: "applications", action: "restart", target: app.type.rawValue, error: msg, serverId: serverId)
        }
        actionInProgressId = nil
    }

    // MARK: - AX Doctor

    /// Invokes AX Doctor to diagnose a service action failure.
    /// Uses live diagnosis: runs SSH check commands on the server first.
    private func invokeDiagnostics(section: String, action: String, target: String, error: String, serverId: String) {
        Task {
            let diagnosis = await DoctorService.shared.liveDiagnose(
                section: section, action: action, target: target,
                error: error, serverId: serverId,
                sshExecutor: { command in
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: command)
                            continuation.resume(returning: result)
                        }
                    }
                }
            )
            await MainActor.run {
                self.doctorDiagnosis = diagnosis
            }
        }
    }

    func toggleAutoStart(_ app: ApplicationInstance) async {
        guard let serverId else { return }
        actionInProgressId = app.id
        do {
            if app.autoStart {
                try await GoApplicationService.shared.disableOnBoot(type: app.type, serverId: serverId)
            } else {
                try await GoApplicationService.shared.enableOnBoot(type: app.type, serverId: serverId)
            }
            await refreshSingleApp(app.type)
        } catch {
            errorMessage = "Failed to toggle auto-start for \(app.name): \(error.localizedDescription)"
        }
        actionInProgressId = nil
    }

    func installApplication(_ app: ApplicationInstance) async {
        guard let serverId else { return }
        errorMessage = nil
        installingApplicationId = app.id
        installProgressByAppId[app.id] = 0
        installMessageByAppId[app.id] = "Preparing installation..."

        do {
            let targetVersion: String
            do {
                let versions = try await GoApplicationService.shared.getAvailableVersions(type: app.type, serverId: serverId)
                targetVersion = versions.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "latest"
            } catch {
                targetVersion = "latest"
            }

            try await GoApplicationService.shared.installVersion(targetVersion, type: app.type, serverId: serverId) { [weak self] message, progress in
                Task { @MainActor in
                    self?.installMessageByAppId[app.id] = message
                    self?.installProgressByAppId[app.id] = max(0, min(1, progress))
                }
            }
            await loadApplications(forceRefresh: true)
        } catch {
            errorMessage = "Failed to install \(app.name): \(error.localizedDescription)"
        }

        installingApplicationId = nil
        installProgressByAppId[app.id] = nil
        installMessageByAppId[app.id] = nil
    }

    func uninstallApplication(_ app: ApplicationInstance) async {
        guard let serverId else { return }
        errorMessage = nil

        do {
            try await GoApplicationService.shared.uninstallApplication(type: app.type, serverId: serverId, currentVersion: app.version)
            await loadApplications(forceRefresh: true)
        } catch {
            errorMessage = "Failed to uninstall \(app.name): \(error.localizedDescription)"
        }
    }

    // MARK: - Navigation

    func selectApplication(_ app: ApplicationInstance) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedApplication = app
        }
    }

    func deselectApplication() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedApplication = nil
        }
    }

    // MARK: - Health Score

    func healthScore(for app: ApplicationInstance) -> Int {
        guard app.status != .notInstalled else { return 0 }

        var score = 0

        // Running = +40
        if app.isRunning { score += 40 }

        // Auto-start = +15
        if app.autoStart { score += 15 }

        // Version detected = +15
        if app.version != nil { score += 15 }

        // Memory within limits = +20
        if let mem = app.memoryUsage {
            if mem < 200 { score += 20 }
            else if mem < 400 { score += 10 }
            else { score += 5 }
        } else {
            score += 10 // no data = neutral
        }

        // Port configured = +10
        if app.port != nil { score += 10 }

        return min(100, score)
    }

    func healthColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .axSuccess
        case 50..<80: return .axWarning
        default: return .axError
        }
    }
}
