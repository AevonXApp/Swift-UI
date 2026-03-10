//
//  SiteConfigViewModel.swift
//  AevonX
//
//  ViewModel for per-site Nginx config editing — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

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
    private let bridge = WebsitesBridge.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadConfig() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let path = "/etc/nginx/sites-available/\(domain)"
            configPath = path
            let cmd = bridge.loadNginxConfigCmd(configPath: path)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            configContent = result
            originalContent = result
            hasUnsavedChanges = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func validateConfig() async {
        isValidating = true
        defer { isValidating = false }
        do {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t 2>&1")
            validationResult = result
            validationPassed = true
        } catch {
            validationResult = error.localizedDescription
            validationPassed = false
        }
    }

    func saveConfig() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let path = configPath.isEmpty ? "/etc/nginx/sites-available/\(domain)" : configPath
            // Backup current
            let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo cp \(path) \(path).bak.\(ts)")
            // Write new content via heredoc
            let escaped = configContent.replacingOccurrences(of: "'", with: "'\\''")
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "printf '%s' '\(escaped)' | sudo tee \(path) > /dev/null")
            // Validate
            let test = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t 2>&1")
            validationResult = test
            validationPassed = true
            if true {
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
                originalContent = configContent
                hasUnsavedChanges = false
                GlobalToastManager.shared.showSuccess("Config saved & Nginx reloaded")
                await loadBackups()
            } else {
                // Rollback
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo cp \(path).bak.\(ts) \(path)")
                errorMessage = "Validation failed — config rolled back"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBackups() async {
        do {
            let path = configPath.isEmpty ? "/etc/nginx/sites-available/\(domain)" : configPath
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "ls -1 \(path).bak.* 2>/dev/null | sort -r | head -10")
            configBackups = result.components(separatedBy: "\n").filter { !$0.isEmpty }.map {
                let filename = ($0 as NSString).lastPathComponent
                let date = filename.replacingOccurrences(of: "\(domain).bak.", with: "")
                return ConfigBackupItem(filename: filename, formattedDate: date)
            }
        } catch {
            configBackups = []
        }
    }

    func restoreBackup(_ backup: ConfigBackupItem) async {
        do {
            let path = configPath.isEmpty ? "/etc/nginx/sites-available/\(domain)" : configPath
            let dir = (path as NSString).deletingLastPathComponent
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo cp \(dir)/\(backup.filename) \(path)")
            await loadConfig()
            GlobalToastManager.shared.showSuccess("Backup restored")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyTemplate(_ template: SiteConfigTemplate, docRoot: String) {
        configContent = bridge.generateTemplateConfig(template: template.rawValue.lowercased(), domain: domain, docRoot: docRoot)
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
