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
        do {
            switch runtime {
            case .php:
                // Multi-path restart: BT Panel + systemd
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command:
                    "sudo systemctl restart php*-fpm 2>/dev/null || " +
                    "(for v in $(ls /www/server/php/ 2>/dev/null); do /www/server/php/$v/sbin/php-fpm restart 2>/dev/null; done) || true"
                )
                GlobalToastManager.shared.showSuccess("PHP-FPM restarted")
            case .nodejs:
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "pm2 restart all")
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
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess("Nginx restarted")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func reloadNginx() async {
        isRunning = true; runningAction = "Reloading Nginx..."
        defer { isRunning = false; runningAction = "" }
        do {
            // Use bridge reload — falls back to init.d for BT Panel
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess("Nginx reloaded")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func toggleMaintenanceMode() async {
        isRunning = true; runningAction = maintenanceMode ? "Disabling maintenance..." : "Enabling maintenance..."
        defer { isRunning = false; runningAction = "" }
        await detectPathsIfNeeded()
        do {
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
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func fixOwnership() async {
        isRunning = true; runningAction = "Fixing ownership..."
        defer { isRunning = false; runningAction = "" }
        await detectPathsIfNeeded()
        do {
            let cmd = bridge.fixPermissionsCmd(docRoot: docRoot)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            GlobalToastManager.shared.showSuccess("Ownership fixed to \(serverPaths.webOwnership)")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func clearAppCache() async {
        isRunning = true; runningAction = "Clearing app cache..."
        defer { isRunning = false; runningAction = "" }
        do {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo rm -rf \(docRoot)/storage/framework/cache/* \(docRoot)/bootstrap/cache/* 2>/dev/null; echo 'Cache cleared'")
            GlobalToastManager.shared.showSuccess("App cache cleared")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func refreshDiskUsage() async {
        do {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "du -sh \(docRoot) 2>/dev/null | awk '{print $1}'")
            diskUsage = result.trimmingCharacters(in: .whitespacesAndNewlines)
            if diskUsage.isEmpty { diskUsage = "N/A" }
        } catch {
            diskUsage = "N/A"
        }
    }

    func testNginx() async {
        isRunning = true; runningAction = "Testing Nginx config..."
        defer { isRunning = false; runningAction = "" }
        do {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t 2>&1")
            nginxTestResult = result
            nginxTestPassed = true
        } catch {
            nginxTestResult = error.localizedDescription
            nginxTestPassed = false
        }
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
