//
//  PluginConfigurationViewModel.swift
//  AevonX
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class PluginConfigurationViewModel: ObservableObject {
    let plugin: Plugin
    let serverId: String
    
    @Published var config: [String: String] = [:]
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
            
            // Also get raw content for the text editor
            let path = "/opt/aevonx/plugins/\(plugin.slug)/config.avx"
            let content = try await SSHService.shared.execute("cat \(path)", serverId: serverId).stdout
            self.rawContent = content
            
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
            
            // Reload to ensure sync
            await loadConfig()
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
            isSaving = false
        }
    }
    
    func saveRawConfig() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let path = "/opt/aevonx/plugins/\(plugin.slug)/config.avx"
            let base64Content = Data(rawContent.utf8).base64EncodedString()
            let command = "echo '\(base64Content)' | base64 -d > \(path)"
            _ = try await SSHService.shared.execute(command, serverId: serverId)
            
            successMessage = "Raw configuration saved successfully"
            isSaving = false
            
            // Reload to update the KV view
            await loadConfig()
        } catch {
            errorMessage = "Failed to save raw configuration: \(error.localizedDescription)"
            isSaving = false
        }
    }
}
