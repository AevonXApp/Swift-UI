//
//  UnifiedServiceDetailViewModel.swift
//  AevonX
//
//  Unified ViewModel for all service detail views.
//  Replaces NginxDetailViewModel, ApacheDetailViewModel, and PHPDetailViewModel.
//  Routes data loading and actions through GoApplicationService based on app type.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
final class UnifiedServiceDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isLoading = true
    @Published var errorMessage: String?

    // Shared data
    @Published var rawConfig: String = ""
    @Published var configPath: String = "Not detected"
    @Published var logPath: String = "Not detected"
    @Published var logPaths: [String] = []

    // Nginx-specific
    @Published var listeningPorts: [Int] = []
    @Published var blockedIPs: [AXBlockedIP] = []
    @Published var dataPath: String = "Not detected"

    // Apache-specific
    @Published var modules: [ApacheModule] = []
    @Published var virtualHosts: [ApacheVHost] = []
    @Published var documentRoot: String = "Not detected"

    // PHP-specific
    @Published var installedExtensions: [PHPExtension] = []
    @Published var availableExtensions: [PHPExtension] = []
    @Published var disabledFunctions: [String] = []
    @Published var fpmPools: [PHPFPMPool] = []
    @Published var fpmStatus = PHPFPMStatus()
    @Published var opcacheStatus = PHPOPcacheStatus()

    // MARK: - Constants

    let application: ApplicationInstance
    let serverId: String

    private var appType: ApplicationType { application.type }
    private var displayName: String { application.name }
    private let service = GoApplicationService.shared

    init(application: ApplicationInstance, serverId: String) {
        self.application = application
        self.serverId = serverId
    }

    // MARK: - Data Loading (routes by type)

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            switch appType {
            case .nginx:    try await loadNginxData()
            case .apache:   try await loadApacheData()
            case .phpFpm:   try await loadPHPData()
            default:        try await loadGenericData()
            }
        } catch {
            errorMessage = "Failed to load \(displayName) data: \(error.localizedDescription)"
            GlobalToastManager.shared.showError(errorMessage!)
        }

        isLoading = false
    }

    // MARK: - Type-Specific Loaders

    private func loadNginxData() async throws {
        let configContent = try await service.readConfig(type: .nginx, serverId: serverId)
        let paths = try? await service.getImportantPaths(type: .nginx, serverId: serverId)
        let ports = (try? await service.getListeningPorts(type: .nginx, serverId: serverId)) ?? []
        let blocked = (try? await service.getBlockedIPs(type: .nginx, serverId: serverId)) ?? []

        rawConfig = configContent
        configPath = paths?.configPath ?? "Not detected"
        logPath = paths?.logPath ?? "Not detected"
        dataPath = paths?.dataPath ?? "Not detected"
        listeningPorts = ports
        blockedIPs = blocked
    }

    private func loadApacheData() async throws {
        let configContent = try await service.readConfig(type: .apache, serverId: serverId)
        let installed = (try? await service.getInstalledApacheModules(serverId: serverId)) ?? []
        let available = (try? await service.getAvailableApacheModules(serverId: serverId)) ?? []
        let vhosts = (try? await service.getApacheVirtualHosts(serverId: serverId)) ?? []
        let cPath = (try? await service.getConfigPath(type: .apache, serverId: serverId)) ?? "Not detected"
        let docRoot = (try? await service.getDocumentRoot(serverId: serverId)) ?? "Not detected"

        rawConfig = configContent
        configPath = cPath
        documentRoot = docRoot
        modules = installed + available
        virtualHosts = vhosts
    }

    private func loadPHPData() async throws {
        let configContent = try await service.readConfig(type: .phpFpm, serverId: serverId)
        let instExts = (try? await service.getInstalledPHPExtensions(serverId: serverId)) ?? []
        let availExts = (try? await service.getAvailablePHPExtensions(serverId: serverId)) ?? []
        let disabled = (try? await service.getDisabledPHPFunctions(serverId: serverId)) ?? []
        let pools = (try? await service.getPHPFPMPools(serverId: serverId)) ?? []
        let cPath = (try? await service.getConfigPath(type: .phpFpm, serverId: serverId)) ?? "Not detected"
        let logs = (try? await service.getLogPaths(type: .phpFpm, serverId: serverId)) ?? []
        let fpmStat = (try? await service.getPHPFPMStatus(serverId: serverId)) ?? PHPFPMStatus()
        let opStat = (try? await service.getPHPOPcacheStatus(serverId: serverId)) ?? PHPOPcacheStatus()

        rawConfig = configContent
        configPath = cPath
        logPath = logs.first ?? "Not detected"
        logPaths = logs
        installedExtensions = instExts
        availableExtensions = availExts
        disabledFunctions = disabled
        fpmPools = pools
        fpmStatus = fpmStat
        opcacheStatus = opStat
    }

    private func loadGenericData() async throws {
        let cPath = (try? await service.getConfigPath(type: appType, serverId: serverId)) ?? "Not detected"
        let logs = (try? await service.getLogPaths(type: appType, serverId: serverId)) ?? []
        configPath = cPath
        logPath = logs.first ?? "Not detected"
        logPaths = logs
    }

    // MARK: - Service Control (unified)

    func controlService(action: ServiceControlButtons.ServiceAction) async {
        do {
            switch action {
            case .start:   try await service.startService(type: appType, serverId: serverId)
            case .stop:    try await service.stopService(type: appType, serverId: serverId)
            case .restart: try await service.restartService(type: appType, serverId: serverId)
            }
            GlobalToastManager.shared.showSuccess("\(displayName) service \(action.rawValue)ed successfully")
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s — verification already waited 1.5s
                await loadData()
            }
        } catch {
            GlobalToastManager.shared.showError("Failed to \(action.rawValue) \(displayName): \(error.localizedDescription)")
        }
    }

    func reloadService() async {
        do {
            try await service.restartService(type: appType, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(displayName) service reloaded successfully")
        } catch {
            GlobalToastManager.shared.showError("Failed to reload \(displayName): \(error.localizedDescription)")
        }
    }

    // MARK: - Configuration (unified)

    func saveConfiguration(_ newConfig: String) async {
        do {
            try await service.updateConfig(newConfig, type: appType, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(displayName) configuration updated and reloaded successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    func testConfiguration() async {
        do {
            let isValid = try await service.validateConfig(type: appType, serverId: serverId)
            if isValid {
                GlobalToastManager.shared.showSuccess("\(displayName) configuration is valid")
            } else {
                GlobalToastManager.shared.showError("\(displayName) configuration validation failed")
            }
        } catch {
            GlobalToastManager.shared.showError("Validation error: \(error.localizedDescription)")
        }
    }

    // MARK: - Nginx-Specific Actions

    func blockIP(_ ip: String, reason: String? = nil, duration: String? = nil) async {
        guard appType == .nginx else { return }
        do {
            try await service.blockIP(ip, reason: reason, duration: duration, type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("IP \(ip) blocked successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to block IP: \(error.localizedDescription)")
        }
    }

    func unblockIP(_ ip: String) async {
        guard appType == .nginx else { return }
        do {
            try await service.unblockIP(ip, type: .nginx, serverId: serverId)
            GlobalToastManager.shared.showSuccess("IP \(ip) unblocked successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to unblock IP: \(error.localizedDescription)")
        }
    }

    func savePort(_ port: Int) async {
        do {
            try await service.updatePort(port, type: appType, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(displayName) port updated to \(port)")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to update port: \(error.localizedDescription)")
        }
    }
}
