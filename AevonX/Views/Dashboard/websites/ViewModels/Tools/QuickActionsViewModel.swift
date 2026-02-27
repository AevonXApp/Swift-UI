//
//  QuickActionsViewModel.swift
//  AevonX
//
//  ViewModel for quick one-click actions — delegates to SiteQuickActionsService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class QuickActionsViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var runningAction = ""
    @Published var diskUsage = "—"
    @Published var nginxTestResult: String?
    @Published var nginxTestPassed = false
    @Published var maintenanceMode = false

    let serverId: String
    let domain: String
    let docRoot: String
    let runtime: RuntimeType
    private let service = SiteQuickActionsService.shared

    init(serverId: String, domain: String, docRoot: String, runtime: RuntimeType) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
        self.runtime = runtime
    }

    func restartRuntime() async {
        isRunning = true; runningAction = "Restarting runtime..."
        defer { isRunning = false; runningAction = "" }
        do {
            switch runtime {
            case .php:
                try await service.restartPHPFPM(version: "8.2", serverId: serverId)
                GlobalToastManager.shared.showSuccess("PHP-FPM restarted")
            case .nodejs:
                try await service.restartPM2(serverId: serverId)
                GlobalToastManager.shared.showSuccess("PM2 restarted")
            default:
                GlobalToastManager.shared.showSuccess("No runtime to restart")
            }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func restartNginx() async {
        isRunning = true; runningAction = "Restarting Nginx..."
        defer { isRunning = false; runningAction = "" }
        do {
            try await service.restartNginx(serverId: serverId)
            GlobalToastManager.shared.showSuccess("Nginx restarted")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func reloadNginx() async {
        isRunning = true; runningAction = "Reloading Nginx..."
        defer { isRunning = false; runningAction = "" }
        do {
            try await service.reloadNginx(serverId: serverId)
            GlobalToastManager.shared.showSuccess("Nginx reloaded")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func toggleMaintenanceMode() async {
        isRunning = true; runningAction = maintenanceMode ? "Disabling maintenance..." : "Enabling maintenance..."
        defer { isRunning = false; runningAction = "" }
        do {
            if maintenanceMode {
                try await service.disableMaintenanceMode(domain: domain, docRoot: docRoot, serverId: serverId)
                maintenanceMode = false
                GlobalToastManager.shared.showSuccess("Maintenance mode disabled")
            } else {
                try await service.enableMaintenanceMode(domain: domain, docRoot: docRoot, serverId: serverId)
                maintenanceMode = true
                GlobalToastManager.shared.showSuccess("Maintenance mode enabled")
            }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func fixOwnership() async {
        isRunning = true; runningAction = "Fixing ownership..."
        defer { isRunning = false; runningAction = "" }
        do {
            try await service.fixOwnership(docRoot: docRoot, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Ownership fixed to www-data")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func clearAppCache() async {
        isRunning = true; runningAction = "Clearing app cache..."
        defer { isRunning = false; runningAction = "" }
        do {
            let result = try await service.clearAppCache(docRoot: docRoot, serverId: serverId)
            GlobalToastManager.shared.showSuccess(result)
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func refreshDiskUsage() async {
        do {
            diskUsage = try await service.getDiskUsage(docRoot: docRoot, serverId: serverId)
        } catch {
            diskUsage = "N/A"
        }
    }

    func testNginx() async {
        isRunning = true; runningAction = "Testing Nginx config..."
        defer { isRunning = false; runningAction = "" }
        do {
            let result = try await service.testNginxConfig(serverId: serverId)
            nginxTestResult = result.output
            nginxTestPassed = result.passed
        } catch {
            nginxTestResult = error.localizedDescription
            nginxTestPassed = false
        }
    }
}
