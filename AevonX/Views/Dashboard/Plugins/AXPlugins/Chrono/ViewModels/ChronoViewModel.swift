//
//  ChronoViewModel.swift
//  AevonX
//
//  ViewModel for AXChrono plugin UI.
//  Communicates with the daemon via SSH → curl to localhost:9444.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class ChronoViewModel: ObservableObject {

    // MARK: - Tab

    enum ChronoTab: String, CaseIterable {
        case dashboard, projects, deploys, timeline, security, approvals, hologram, settings

        var label: String {
            switch self {
            case .dashboard: return L10n.Chrono.tabDashboard
            case .projects: return L10n.Chrono.tabProjects
            case .deploys: return L10n.Chrono.tabDeploys
            case .timeline: return L10n.Chrono.tabTimeline
            case .security: return L10n.Chrono.tabSecurity
            case .approvals: return L10n.Chrono.tabApprovals
            case .hologram: return L10n.Chrono.tabHologram
            case .settings: return L10n.Chrono.tabSettings
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "gauge.with.dots.needle.33percent"
            case .projects: return "folder.badge.gearshape"
            case .deploys: return "arrow.triangle.2.circlepath"
            case .timeline: return "clock.arrow.circlepath"
            case .security: return "shield.checkered"
            case .approvals: return "checkmark.seal"
            case .hologram: return "cube.transparent"
            case .settings: return "gearshape"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return .axAccentBlue
            case .projects: return .axAccentGreen
            case .deploys: return .axAccentBlue
            case .timeline: return .axAccentPurple
            case .security: return .axError
            case .approvals: return .axWarning
            case .hologram: return .axAccentPurple
            case .settings: return .axTextSecondary
            }
        }
    }

    // MARK: - Published State

    @Published var selectedTab: ChronoTab = .dashboard
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Service
    @Published var serviceStatus: ChronoServiceStatus?
    @Published var serviceOperationInProgress = false

    // Dashboard
    @Published var daemonStatus: ChronoDaemonStatus?
    @Published var recentDeploys: [ChronoDeploy] = []
    @Published var watchers: [ChronoWatcherInfo] = []
    @Published var dashboardAlerts: [ChronoAlert] = []

    // Projects
    @Published var projects: [ChronoProject] = []
    @Published var selectedProject: ChronoProject?
    @Published var showAddProject = false

    // Deploys
    @Published var deploys: [ChronoDeploy] = []
    @Published var selectedDeploy: ChronoDeploy?
    @Published var liveLogLines: [String] = []
    @Published var isLiveStreaming = false
    @Published var showLiveLog = false

    // Timeline
    @Published var timeline: [ChronoTimelineEntry] = []

    // Security
    @Published var securityResults: ChronoSecurityResults?

    // Approvals
    @Published var pendingApprovals: [ChronoApproval] = []
    @Published var approvalHistory: [ChronoApprovalHistory] = []

    // Hologram
    @Published var hologram: ChronoHologram?
    @Published var hologramProjectId: String?

    // Settings
    @Published var config: ChronoConfig?
    @Published var webhookStatus: ChronoWebhookStatus?
    @Published var settingsSaving = false

    // Snapshots
    @Published var snapshots: [ChronoSnapshot] = []

    // Health
    @Published var healthProbes: [ChronoHealthProbe] = []

    // Project Detail
    @Published var showProjectDetail = false
    @Published var detailProject: ChronoProject?
    @Published var detailDeploys: [ChronoDeploy] = []

    let serverId: String
    private var apiToken: String = ""
    private var liveLogTask: Task<Void, Never>?

    // MARK: - Init

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - Dashboard

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        async let statusResult = fetchAPI("/api/v1/status", as: ChronoDaemonStatus.self)
        async let deploysResult = fetchAPI("/api/v1/deploys?limit=5", as: [ChronoDeploy].self)
        async let alertsResult = fetchAPI("/api/v1/alerts", as: [ChronoAlert].self)
        async let watchersResult = fetchAPI("/api/v1/watchers", as: [ChronoWatcherInfo].self)

        daemonStatus = await statusResult
        recentDeploys = await deploysResult ?? []
        dashboardAlerts = await alertsResult ?? []
        watchers = await watchersResult ?? []
        isLoading = false
    }

    // MARK: - Projects

    func loadProjects() async {
        projects = await fetchAPI("/api/v1/projects", as: [ChronoProject].self) ?? []
    }

    func addProject(path: String, repoURL: String, branch: String, autoDeploy: Bool, healthURL: String) async {
        let body: [String: Any] = [
            "path": path, "repo_url": repoURL, "branch": branch,
            "auto_deploy": autoDeploy, "health_url": healthURL
        ]
        _ = await postAPI("/api/v1/projects", body: body)
        await loadProjects()
    }

    func removeProject(id: String) async {
        _ = await deleteAPI("/api/v1/projects/\(id)")
        await loadProjects()
    }

    // MARK: - Deploys

    func loadDeploys(projectId: String? = nil) async {
        let path = projectId.map { "/api/v1/projects/\($0)/deploys" } ?? "/api/v1/deploys?limit=50"
        deploys = await fetchAPI(path, as: [ChronoDeploy].self) ?? []
    }

    func triggerDeploy(projectId: String) async {
        _ = await postAPI("/api/v1/projects/\(projectId)/deploy", body: [:])
        await loadDeploys(projectId: projectId)
    }

    func loadDeployDetail(deployId: String) async {
        selectedDeploy = await fetchAPI("/api/v1/deploys/\(deployId)", as: ChronoDeploy.self)
    }

    // MARK: - Live Log

    func watchLiveLog(deployId: String) async {
        isLiveStreaming = true
        liveLogLines = []
        showLiveLog = true

        let raw = await sshExec("curl -s -N -H 'X-AXChrono-Token: \(apiToken)' http://127.0.0.1:9444/api/v1/deploys/\(deployId)/log")
        for line in raw.split(separator: "\n") {
            let s = String(line)
            if s.hasPrefix("data: ") {
                liveLogLines.append(String(s.dropFirst(6)))
            }
        }
        isLiveStreaming = false
    }

    // MARK: - Rollback

    func rollback(projectId: String, snapshotId: String) async {
        _ = await postAPI("/api/v1/projects/\(projectId)/rollback", body: ["snapshot_id": snapshotId])
    }

    // MARK: - Snapshots

    func loadSnapshots(projectId: String) async {
        snapshots = await fetchAPI("/api/v1/snapshots/\(projectId)", as: [ChronoSnapshot].self) ?? []
    }

    // MARK: - Timeline

    func loadTimeline(projectId: String? = nil) async {
        let path = projectId.map { "/api/v1/projects/\($0)/timeline" } ?? "/api/v1/timeline"
        timeline = await fetchAPI(path, as: [ChronoTimelineEntry].self) ?? []
    }

    // MARK: - Security

    func loadSecurity(projectId: String) async {
        securityResults = await fetchAPI("/api/v1/projects/\(projectId)/security", as: ChronoSecurityResults.self)
    }

    // MARK: - Hologram

    func loadHologram(projectId: String) async {
        hologramProjectId = projectId
        hologram = await fetchAPI("/api/v1/projects/\(projectId)/hologram", as: ChronoHologram.self)
    }

    // MARK: - Approvals

    func loadApprovals() async {
        async let pendingResult = fetchAPI("/api/v1/approvals/pending", as: [ChronoApproval].self)
        async let historyResult = fetchAPI("/api/v1/approvals/history", as: [ChronoApprovalHistory].self)

        pendingApprovals = await pendingResult ?? []
        approvalHistory = await historyResult ?? []
    }

    func approveOperation(id: String) async {
        _ = await postAPI("/api/v1/approvals/\(id)/approve", body: [:])
        await loadApprovals()
    }

    func denyOperation(id: String) async {
        _ = await postAPI("/api/v1/approvals/\(id)/deny", body: [:])
        await loadApprovals()
    }

    // MARK: - Health

    func loadHealth() async {
        healthProbes = await fetchAPI("/api/v1/health/probes", as: [ChronoHealthProbe].self) ?? []
    }

    // MARK: - Project Detail

    func openProjectDetail(_ project: ChronoProject) async {
        detailProject = project
        async let deploysResult = fetchAPI("/api/v1/projects/\(project.id)/deploys", as: [ChronoDeploy].self)
        async let snapshotsResult = fetchAPI("/api/v1/snapshots/\(project.id)", as: [ChronoSnapshot].self)
        detailDeploys = await deploysResult ?? []
        snapshots = await snapshotsResult ?? []
        showProjectDetail = true
    }

    func deleteSnapshot(id: String, projectId: String) async {
        _ = await deleteAPI("/api/v1/snapshots/\(id)")
        await loadSnapshots(projectId: projectId)
    }

    func restoreSnapshot(projectId: String, snapshotId: String) async {
        _ = await postAPI("/api/v1/projects/\(projectId)/rollback", body: ["snapshot_id": snapshotId])
    }

    // MARK: - Settings

    func loadConfig() async {
        config = await fetchAPI("/api/v1/config", as: ChronoConfig.self)
        webhookStatus = await fetchAPI("/api/v1/webhooks/status", as: ChronoWebhookStatus.self)
    }

    func saveConfig(_ cfg: ChronoConfig) async {
        settingsSaving = true
        if let data = try? JSONEncoder().encode(cfg),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            _ = await postAPI("/api/v1/config", body: dict)
        }
        settingsSaving = false
    }

    // MARK: - Service Control

    func checkService() async {
        let raw = await sshExec("systemctl is-active axchrono 2>/dev/null && echo ACTIVE || echo INACTIVE")
        serviceStatus = ChronoServiceStatus(
            isActive: raw.contains("ACTIVE"),
            pid: nil,
            uptimeSeconds: nil
        )
    }

    func startService() async {
        serviceOperationInProgress = true
        _ = await sshExec("sudo systemctl start axchrono")
        try? await Task.sleep(for: .seconds(1))
        await checkService()
        serviceOperationInProgress = false
    }

    func stopService() async {
        serviceOperationInProgress = true
        _ = await sshExec("sudo systemctl stop axchrono")
        try? await Task.sleep(for: .seconds(1))
        await checkService()
        serviceOperationInProgress = false
    }

    func restartService() async {
        serviceOperationInProgress = true
        _ = await sshExec("sudo systemctl restart axchrono")
        try? await Task.sleep(for: .seconds(1))
        await checkService()
        serviceOperationInProgress = false
    }

    // MARK: - Helpers

    func formatUptime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return String(format: "%.1f MB", mb)
    }

    func formatDuration(_ ms: Int) -> String {
        let s = Double(ms) / 1000
        if s >= 60 { return String(format: "%.0fm %.0fs", (s / 60).rounded(.down), s.truncatingRemainder(dividingBy: 60)) }
        return String(format: "%.1fs", s)
    }

    // MARK: - API Layer

    private func sshExec(_ command: String) async -> String {
        await SSHBridge.shared.executeAsync(serverID: serverId, command: command)
    }

    private func fetchAPI<T: Decodable>(_ path: String, as type: T.Type) async -> T? {
        let raw = await sshExec("curl -s -H 'X-AXChrono-Token: \(apiToken)' http://127.0.0.1:9444\(path)")
        guard let data = raw.data(using: .utf8) else { return nil }
        let response = try? JSONDecoder().decode(ChronoAPIResponse<T>.self, from: data)
        if let err = response?.error { errorMessage = err }
        return response?.data
    }

    private func postAPI(_ path: String, body: [String: Any]) async -> Bool {
        let jsonData = (try? JSONSerialization.data(withJSONObject: body)) ?? Data()
        let jsonStr = String(data: jsonData, encoding: .utf8) ?? "{}"
        let escaped = jsonStr.replacingOccurrences(of: "'", with: "'\\''")
        let raw = await sshExec("curl -s -X POST -H 'X-AXChrono-Token: \(apiToken)' -H 'Content-Type: application/json' -d '\(escaped)' http://127.0.0.1:9444\(path)")
        guard let data = raw.data(using: .utf8),
              let resp = try? JSONDecoder().decode(ChronoAPIResponse<Bool>.self, from: data) else { return false }
        return resp.success
    }

    private func deleteAPI(_ path: String) async -> Bool {
        let raw = await sshExec("curl -s -X DELETE -H 'X-AXChrono-Token: \(apiToken)' http://127.0.0.1:9444\(path)")
        guard let data = raw.data(using: .utf8),
              let resp = try? JSONDecoder().decode(ChronoAPIResponse<Bool>.self, from: data) else { return false }
        return resp.success
    }
}
