//
//  PluginConfigurationViewModel.swift
//  AevonX
//

import SwiftUI
import Combine
import AevonXCoreBridge
import AevonXCore

@MainActor
class PluginConfigurationViewModel: ObservableObject {
    let plugin: AevonXCore.Plugin
    let serverId: String
    
    @Published var config: AevonXCore.PluginConfig = AevonXCore.PluginConfig()
    @Published var rawContent: String = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let pluginManager = AevonXCore.PluginManager.shared
    
    init(plugin: AevonXCore.Plugin, serverId: String) {
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
            let result = try await SSHBridge.shared.execute("cat \(path)", serverId: serverId)
            self.rawContent = result.stdout
            
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
            // Validate JSON first
            if let data = rawContent.data(using: .utf8) {
                _ = try JSONDecoder().decode(AevonXCore.PluginConfig.self, from: data)
            }
            
            let path = "/opt/aevonx/plugins/\(plugin.slug)/config.avx"
            // Use base64 to avoid escaping issues
            let base64Content = Data(rawContent.utf8).base64EncodedString()
            let command = "echo '\(base64Content)' | base64 -d > \(path)"
            _ = try await SSHBridge.shared.execute(command, serverId: serverId)
            
            successMessage = "Raw configuration saved successfully"
            isSaving = false
            
            // Reload to update the KV view
            await loadConfig()
        } catch {
            errorMessage = "Invalid JSON or save failed: \(error.localizedDescription)"
            isSaving = false
        }
    }
}
