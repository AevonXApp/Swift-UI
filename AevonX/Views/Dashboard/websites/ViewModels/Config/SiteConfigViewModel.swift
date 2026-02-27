//
//  SiteConfigViewModel.swift
//  AevonX
//
//  ViewModel for per-site Nginx config editing — delegates to SiteNginxConfigService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class SiteConfigViewModel: ObservableObject {
    @Published var configContent = ""
    @Published var configPath = ""
    @Published var configBackups: [ConfigBackupItem] = []
    @Published var validationResult: String?
    @Published var validationPassed = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isValidating = false
    @Published var hasUnsavedChanges = false

    let serverId: String
    let domain: String
    private var originalContent = ""
    private let service = SiteNginxConfigService.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadConfig() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await service.loadConfig(domain: domain, serverId: serverId)
            configContent = result.content
            configPath = result.path
            originalContent = result.content
            hasUnsavedChanges = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func validateConfig() async {
        isValidating = true
        defer { isValidating = false }
        do {
            let result = try await service.validateConfig(serverId: serverId)
            validationResult = result.output
            validationPassed = result.passed
        } catch {
            validationResult = error.localizedDescription
            validationPassed = false
        }
    }

    func saveConfig() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let result = try await service.saveConfig(domain: domain, content: configContent, serverId: serverId)
            validationResult = result.output
            validationPassed = result.passed
            if result.passed {
                originalContent = configContent
                hasUnsavedChanges = false
                GlobalToastManager.shared.showSuccess("Config saved & Nginx reloaded")
                await loadBackups()
            } else {
                errorMessage = "Validation failed — config rolled back"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBackups() async {
        do {
            let backups = try await service.listBackups(domain: domain, serverId: serverId)
            configBackups = backups.map { ConfigBackupItem(filename: $0.filename, formattedDate: $0.date) }
        } catch {
            configBackups = []
        }
    }

    func restoreBackup(_ backup: ConfigBackupItem) async {
        do {
            try await service.restoreBackup(domain: domain, backupFilename: backup.filename, serverId: serverId)
            await loadConfig()
            GlobalToastManager.shared.showSuccess("Backup restored")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyTemplate(_ template: SiteConfigTemplate, docRoot: String) {
        configContent = service.generateTemplateConfig(
            template: template.rawValue.lowercased(),
            domain: domain,
            docRoot: docRoot,
            serverId: serverId
        )
        hasUnsavedChanges = true
    }

    func contentDidChange() {
        hasUnsavedChanges = configContent != originalContent
    }
}

// MARK: - UI Models

struct ConfigBackupItem: Identifiable {
    let id = UUID()
    let filename: String
    let formattedDate: String
}
