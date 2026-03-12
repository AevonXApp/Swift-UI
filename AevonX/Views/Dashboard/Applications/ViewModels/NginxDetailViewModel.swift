//
//  NginxDetailViewModel.swift
//  AevonX
//
//  ViewModel for Nginx detail management
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
final class NginxDetailViewModel: ObservableObject {
    @Published var nginxConfig = NginxConfigData()
    @Published var isLoading = true
    @Published var selectedSection: NginxSection = .overview

    let application: ApplicationInstance
    let serverId: String

    init(application: ApplicationInstance, serverId: String) {
        self.application = application
        self.serverId = serverId
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        do {
            let configContent = try await GoApplicationService.shared.readConfig(type: .nginx, serverId: serverId)
            let paths = try? await GoApplicationService.shared.getImportantPaths(type: .nginx, serverId: serverId)
            let ports = (try? await GoApplicationService.shared.getListeningPorts(type: .nginx, serverId: serverId)) ?? []
            let blocked = (try? await GoApplicationService.shared.getBlockedIPs(type: .nginx, serverId: serverId)) ?? []

            nginxConfig = NginxConfigData(
                rawConfig: configContent,
                configPath: paths?.configPath ?? "Not detected",
                logPath: paths?.logPath ?? "Not detected",
                dataPath: paths?.dataPath ?? "Not detected",
                listeningPorts: ports,
                blockedIPs: blocked
            )
        } catch {
            GlobalToastManager.shared.showError("Failed to load Nginx data: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Configuration

    func saveConfiguration(_ newConfig: String) async {
        do {
            try await GoApplicationService.shared.updateConfig(newConfig, type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Nginx configuration updated and reloaded successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    func savePort(_ port: Int) async {
        do {
            try await GoApplicationService.shared.updatePort(port, type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Nginx port updated to \(port)")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to update port: \(error.localizedDescription)")
        }
    }

    // MARK: - Security

    func blockIP(_ ip: String, reason: String? = nil, duration: String? = nil) async {
        do {
            try await GoApplicationService.shared.blockIP(ip, reason: reason, duration: duration, type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("IP \(ip) blocked successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to block IP: \(error.localizedDescription)")
        }
    }

    func unblockIP(_ ip: String) async {
        do {
            try await GoApplicationService.shared.unblockIP(ip, type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("IP \(ip) unblocked successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to unblock IP: \(error.localizedDescription)")
        }
    }

    // MARK: - Service Control

    func controlService(action: ServiceControlButtons.ServiceAction) async {
        do {
            switch action {
            case .start: try await GoApplicationService.shared.startService(type: .nginx, serverId: serverId)
            case .stop: try await GoApplicationService.shared.stopService(type: .nginx, serverId: serverId)
            case .restart: try await GoApplicationService.shared.restartService(type: .nginx, serverId: serverId)
            }
            GlobalToastManager.shared.showSuccess("Nginx service \(action.rawValue)ed successfully")
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await loadData()
            }
        } catch {
            GlobalToastManager.shared.showError("Failed to \(action.rawValue) Nginx: \(error.localizedDescription)")
        }
    }

    func reloadService() async {
        do {
            try await GoApplicationService.shared.restartService(type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Nginx service reloaded successfully")
        } catch {
            GlobalToastManager.shared.showError("Failed to reload Nginx: \(error.localizedDescription)")
        }
    }

    func testConfiguration() async {
        do {
            let isValid = try await GoApplicationService.shared.validateConfig(type: .nginx, serverId: serverId)
            if isValid {
                GlobalToastManager.shared.showSuccess("Nginx configuration is valid")
            } else {
                GlobalToastManager.shared.showError("Nginx configuration validation failed")
            }
        } catch {
            GlobalToastManager.shared.showError("Validation error: \(error.localizedDescription)")
        }
    }
}
