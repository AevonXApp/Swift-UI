//
//  PluginConfigurationViewModel.swift
//  AevonX
//
//  UI is a pure display layer — all paths and SSH operations
//  are handled by core-go through PluginManager bridge functions.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class PluginConfigurationViewModel: ObservableObject {
    let plugin: Plugin
    let serverId: String

    @Published var config: PluginConfig = PluginConfig()
    @Published var rawContent: String = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let pluginManager = PluginManager.shared

    init(plugin: Plugin, serverId: String) {
        self.plugin = plugin
        self.serverId = serverId
    }

    func loadConfig() async {
        isLoading = true
        errorMessage = nil

        do {
            let remoteConfig = try await pluginManager.readRemoteConfig(pluginSlug: plugin.slug, on: serverId)
            self.config = remoteConfig
            self.rawContent = try await pluginManager.readRemoteRawConfig(pluginSlug: plugin.slug, on: serverId)
            isLoading = false
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func saveConfig() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            try await pluginManager.writeRemoteConfig(pluginSlug: plugin.slug, config: config, on: serverId)
            successMessage = "Configuration saved successfully"
            isSaving = false
            await loadConfig()
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
            isSaving = false
        }
    }

    func executeAction(command: String) async {
        errorMessage = nil
        successMessage = nil

        do {
            let output = try await pluginManager.executeAction(
                pluginSlug: plugin.slug, command: command, on: serverId
            )
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

            if let data = trimmed.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                let message = json["message"] as? String ?? trimmed
                if status == "ok" || status == "success" {
                    successMessage = message
                } else {
                    errorMessage = message
                }
            } else {
                successMessage = trimmed.isEmpty ? "Action completed successfully" : trimmed
            }
        } catch {
            errorMessage = "Failed to execute action: \(error.localizedDescription)"
        }
    }

    func saveRawConfig() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            if let data = rawContent.data(using: .utf8) {
                _ = try JSONDecoder().decode(PluginConfig.self, from: data)
            }
            try await pluginManager.writeRemoteRawConfig(
                pluginSlug: plugin.slug, rawJSON: rawContent, on: serverId
            )
            successMessage = "Raw configuration saved successfully"
            isSaving = false
            await loadConfig()
        } catch {
            errorMessage = "Invalid JSON or save failed: \(error.localizedDescription)"
            isSaving = false
        }
    }
}
