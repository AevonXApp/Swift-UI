//
//  PHPDetailViewModel.swift
//  AevonX
//
//  ViewModel for PHP-FPM detail management
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
final class PHPDetailViewModel: ObservableObject {
    @Published var phpConfig = PHPConfigData()
    @Published var isLoading = true
    @Published var selectedSection: PHPSection = .overview

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
            let configContent = try await GoApplicationService.shared.readConfig(type: .phpFpm, serverId: serverId)
            let installedExts = (try? await GoApplicationService.shared.getInstalledPHPExtensions(serverId: serverId)) ?? []
            let availableExts = (try? await GoApplicationService.shared.getAvailablePHPExtensions(serverId: serverId)) ?? []
            let disabledFuncs = (try? await GoApplicationService.shared.getDisabledPHPFunctions(serverId: serverId)) ?? []
            let pools = (try? await GoApplicationService.shared.getPHPFPMPools(serverId: serverId)) ?? []
            let configPath = (try? await GoApplicationService.shared.getConfigPath(type: .phpFpm, serverId: serverId)) ?? "Not detected"
            let logPaths = (try? await GoApplicationService.shared.getLogPaths(type: .phpFpm, serverId: serverId)) ?? []
            let logPath = logPaths.first ?? "Not detected"
            let fpmStatus = (try? await GoApplicationService.shared.getPHPFPMStatus(serverId: serverId)) ?? PHPFPMStatus()
            let opcacheStatus = (try? await GoApplicationService.shared.getPHPOPcacheStatus(serverId: serverId)) ?? PHPOPcacheStatus()

            phpConfig = PHPConfigData(
                rawConfig: configContent,
                iniPath: configPath,
                logPath: logPath,
                installedExtensions: installedExts,
                availableExtensions: availableExts,
                disabledFunctions: disabledFuncs,
                fpmPools: pools,
                fpmStatus: fpmStatus,
                opcacheStatus: opcacheStatus
            )
        } catch {
            GlobalToastManager.shared.showError("Failed to load PHP data: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Configuration

    func saveConfiguration(_ newConfig: String) async {
        do {
            try await GoApplicationService.shared.updateConfig(newConfig, type: .phpFpm, serverId: serverId)
            GlobalToastManager.shared.showSuccess("PHP configuration updated and reloaded successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    // MARK: - Service Control

    func controlService(action: ServiceControlButtons.ServiceAction) async {
        do {
            switch action {
            case .start: try await GoApplicationService.shared.startService(type: .phpFpm, serverId: serverId)
            case .stop: try await GoApplicationService.shared.stopService(type: .phpFpm, serverId: serverId)
            case .restart: try await GoApplicationService.shared.restartService(type: .phpFpm, serverId: serverId)
            }
            GlobalToastManager.shared.showSuccess("PHP-FPM service \(action.rawValue)ed successfully")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to \(action.rawValue) PHP-FPM: \(error.localizedDescription)")
        }
    }

    func reloadService() async {
        do {
            try await GoApplicationService.shared.restartService(type: .phpFpm, serverId: serverId)
            GlobalToastManager.shared.showSuccess("PHP-FPM service reloaded successfully")
        } catch {
            GlobalToastManager.shared.showError("Failed to reload PHP-FPM: \(error.localizedDescription)")
        }
    }

    func testConfiguration() async {
        do {
            let isValid = try await GoApplicationService.shared.validateConfig(type: .phpFpm, serverId: serverId)
            if isValid {
                GlobalToastManager.shared.showSuccess("PHP configuration is valid")
            } else {
                GlobalToastManager.shared.showError("PHP configuration validation failed")
            }
        } catch {
            GlobalToastManager.shared.showError("Validation error: \(error.localizedDescription)")
        }
    }
}
