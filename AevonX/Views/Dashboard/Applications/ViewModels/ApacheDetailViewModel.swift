//
//  ApacheDetailViewModel.swift
//  AevonX
//
//  ViewModel for Apache detail management
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
final class ApacheDetailViewModel: ObservableObject {
    @Published var apacheConfig = ApacheConfigData()
    @Published var isLoading = true
    @Published var selectedSection: ApacheSection = .overview

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
            let configContent = try await ApplicationManager.shared.readConfig(type: .apache, serverId: serverId)
            let installedModules = (try? await ApplicationManager.shared.getInstalledApacheModules(serverId: serverId)) ?? []
            let availableModules = (try? await ApplicationManager.shared.getAvailableApacheModules(serverId: serverId)) ?? []
            let vhosts = (try? await ApplicationManager.shared.getApacheVirtualHosts(serverId: serverId)) ?? []
            let configPath = (try? await ApplicationManager.shared.getConfigPath(type: .apache, serverId: serverId)) ?? "Not detected"
            let documentRoot = (try? await ApplicationManager.shared.getDocumentRoot(serverId: serverId)) ?? "Not detected"

            apacheConfig = ApacheConfigData(
                rawConfig: configContent,
                configPath: configPath,
                documentRoot: documentRoot,
                modules: installedModules + availableModules,
                virtualHosts: vhosts
            )
        } catch {
            GlobalToastManager.shared.showError("Failed to load Apache data: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Configuration

    func saveConfiguration(_ newConfig: String) {
        Task {
            do {
                try await ApplicationManager.shared.updateConfig(newConfig, type: .apache, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Apache configuration updated and reloaded successfully")
                await loadData()
            } catch {
                GlobalToastManager.shared.showError("Failed to save configuration: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Service Control

    func controlService(action: ServiceControlButtons.ServiceAction) async {
        do {
            switch action {
            case .start: try await ApplicationManager.shared.startService(type: .apache, serverId: serverId)
            case .stop: try await ApplicationManager.shared.stopService(type: .apache, serverId: serverId)
            case .restart: try await ApplicationManager.shared.restartService(type: .apache, serverId: serverId)
            }
            GlobalToastManager.shared.showSuccess("Apache service \(action.rawValue)ed successfully")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed to \(action.rawValue) Apache: \(error.localizedDescription)")
        }
    }

    func reloadService() async {
        do {
            try await ApplicationManager.shared.restartService(type: .apache, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Apache service reloaded successfully")
        } catch {
            GlobalToastManager.shared.showError("Failed to reload Apache: \(error.localizedDescription)")
        }
    }

    func testConfiguration() async {
        do {
            let isValid = try await ApplicationManager.shared.validateConfig(type: .apache, serverId: serverId)
            if isValid {
                GlobalToastManager.shared.showSuccess("Apache configuration is valid")
            } else {
                GlobalToastManager.shared.showError("Apache configuration validation failed")
            }
        } catch {
            GlobalToastManager.shared.showError("Validation error: \(error.localizedDescription)")
        }
    }
}
