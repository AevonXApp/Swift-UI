//
//  QuickActionsViewModel.swift
//  AevonX
//
//  ViewModel for quick one-click actions — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

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
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, docRoot: String, runtime: RuntimeType) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
        self.runtime = runtime
    }

    func restartRuntime() async {
        isRunning = true; runningAction = "Restarting runtime..."
        defer { isRunning = false; runningAction = "" }
        await detectPathsIfNeeded()
        switch runtime {
        case .php:
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartAllPHPCmd())
            GlobalToastManager.shared.showSuccess("PHP-FPM restarted")
        case .nodejs:
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartPM2AllCmd())
            GlobalToastManager.shared.showSuccess("PM2 restarted")
        default:
            GlobalToastManager.shared.showSuccess("No runtime to restart")
        }
    }

    func restartNginx() async {
        isRunning = true; runningAction = "Restarting Nginx..."
        defer { isRunning = false; runningAction = "" }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        GlobalToastManager.shared.showSuccess("Nginx restarted")
    }

    func reloadNginx() async {
        isRunning = true; runningAction = "Reloading Nginx..."
        defer { isRunning = false; runningAction = "" }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        GlobalToastManager.shared.showSuccess("Nginx reloaded")
    }

    func toggleMaintenanceMode() async {
        isRunning = true; runningAction = maintenanceMode ? "Disabling maintenance..." : "Enabling maintenance..."
        defer { isRunning = false; runningAction = "" }
        await detectPathsIfNeeded()
        let sa = serverPaths.nginxSitesAvailable
        if maintenanceMode {
            let cmd = bridge.disableMaintenanceCmd(domain: domain, docRoot: docRoot, sitesAvailable: sa)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            maintenanceMode = false
            GlobalToastManager.shared.showSuccess("Maintenance mode disabled")
        } else {
            let cmd = bridge.enableMaintenanceCmd(domain: domain, docRoot: docRoot, sitesAvailable: sa)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            maintenanceMode = true
            GlobalToastManager.shared.showSuccess("Maintenance mode enabled")
        }
    }

    func fixOwnership() async {
        isRunning = true; runningAction = "Fixing ownership..."
        defer { isRunning = false; runningAction = "" }
        await detectPathsIfNeeded()
        let cmd = bridge.fixPermissionsCmd(docRoot: docRoot)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        GlobalToastManager.shared.showSuccess("Ownership fixed to \(serverPaths.webOwnership)")
    }

    func clearAppCache() async {
        isRunning = true; runningAction = "Clearing app cache..."
        defer { isRunning = false; runningAction = "" }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.clearAppCacheCmd(docRoot: docRoot))
        GlobalToastManager.shared.showSuccess("App cache cleared")
    }

    func refreshDiskUsage() async {
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.getDiskUsageCmd(docRoot: docRoot))
        diskUsage = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if diskUsage.isEmpty { diskUsage = "N/A" }
    }

    func testNginx() async {
        isRunning = true; runningAction = "Testing Nginx config..."
        defer { isRunning = false; runningAction = "" }
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.validateNginxCmd())
        nginxTestResult = result
        nginxTestPassed = true
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
