//
//  DatabaseEngineDetailViewModel+Service.swift
//  AevonX
//
//  Service control, health status, boot management, confirmations,
//  user management, and uninstall for engine detail VM.
//

import Foundation
import SwiftUI
import AevonXCoreBridge

// MARK: - Service Control

extension DatabaseEngineDetailViewModel {

    /// Start the database service
    public func startService() async {
        await performOperation(
            progressMessage: "Starting \(databaseType.displayName)...",
            successMessage: "\(databaseType.displayName) started successfully!",
            successAlert: "\(databaseType.displayName) service has been started.",
            failurePrefix: "Failed to start"
        ) {
            try await DatabaseEngineService.shared.startService(type: databaseType, serverId: currentServerId!)
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    /// Stop the database service
    public func stopService() async {
        await performOperation(
            progressMessage: "Stopping \(databaseType.displayName)...",
            successMessage: "\(databaseType.displayName) stopped successfully!",
            successAlert: "\(databaseType.displayName) service has been stopped.",
            failurePrefix: "Failed to stop"
        ) {
            try await DatabaseEngineService.shared.stopService(type: databaseType, serverId: currentServerId!)
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    /// Restart the database service
    public func restartService() async {
        await performOperation(
            progressMessage: "Restarting \(databaseType.displayName)...",
            successMessage: "\(databaseType.displayName) restarted successfully!",
            successAlert: "\(databaseType.displayName) service has been restarted.",
            failurePrefix: "Failed to restart"
        ) {
            try await DatabaseEngineService.shared.restartService(type: databaseType, serverId: currentServerId!)
            try await Task.sleep(nanoseconds: 3_000_000_000)
        }
    }

    /// Enable service on boot
    public func enableOnBoot() async {
        await performOperation(
            progressMessage: "Enabling \(databaseType.displayName) on boot...",
            successMessage: "\(databaseType.displayName) will start on boot!",
            successAlert: "\(databaseType.displayName) has been enabled to start on system boot.",
            failurePrefix: "Failed to enable"
        ) {
            try await DatabaseEngineService.shared.enableService(type: databaseType, serverId: currentServerId!)
        }
    }

    /// Disable service on boot
    public func disableOnBoot() async {
        await performOperation(
            progressMessage: "Disabling \(databaseType.displayName) on boot...",
            successMessage: "\(databaseType.displayName) will not start on boot!",
            successAlert: "\(databaseType.displayName) has been disabled from starting on system boot.",
            failurePrefix: "Failed to disable"
        ) {
            try await DatabaseEngineService.shared.disableService(type: databaseType, serverId: currentServerId!)
        }
    }

    // MARK: - Confirmation Actions

    public func showRestartConfirmation() { activeAlert = .confirmRestart }
    public func showStopConfirmation() { activeAlert = .confirmStop }
    public func showStartConfirmation() { activeAlert = .confirmStart }

    public func showInstallConfirmation(version: DatabaseVersion) {
        selectedVersion = version
        activeAlert = .confirmInstall(version: version)
    }

    public func showUpdateConfirmation() { activeAlert = .confirmUpdate }
    public func showUninstallConfirmation() { activeAlert = .confirmUninstall }

    /// Dismiss alert
    public func dismissAlert() {
        activeAlert = nil
        if operationResult.isSuccess || operationResult.isFailure {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run { self.operationResult = .idle }
            }
        }
    }

    // MARK: - Health Status

    public func updateHealthStatus() {
        guard let info = engineInfo else {
            healthStatus = .unknown
            return
        }

        if !info.isInstalled {
            healthStatus = .unknown
            return
        }

        switch info.status {
        case .active:
            if let metrics = metrics {
                let connectionRatio = Double(metrics.connections) / Double(max(metrics.maxConnections, 1))
                if connectionRatio > 0.9 {
                    healthStatus = .warning
                    return
                }
            }
            healthStatus = .healthy
        case .inactive:
            healthStatus = .warning
        case .failed:
            healthStatus = .critical
        default:
            healthStatus = .unknown
        }
    }

    // MARK: - Uninstall

    public func uninstallEngine() async {
        await performOperation(
            progressMessage: "Uninstalling \(databaseType.displayName)...",
            successMessage: "\(databaseType.displayName) uninstalled successfully!",
            successAlert: "\(databaseType.displayName) has been uninstalled from the server.",
            failurePrefix: "Uninstall failed"
        ) {
            try await DatabaseEngineService.shared.uninstallDatabaseEngine(type: databaseType, serverId: currentServerId!)
        }
    }

    // MARK: - User Management

    public func loadUsers() async {
        guard let serverId = currentServerId else { return }

        isLoadingUsers = true
        userLoadError = nil

        do {
            databaseUsers = try await DatabaseUserService.shared.listUsers(type: databaseType, serverId: serverId)
        } catch {
            userLoadError = "Could not load users: \(error.localizedDescription)"
            databaseUsers = []
        }

        isLoadingUsers = false
    }
}
