//
//  PluginsViewModel.swift
//  AevonX
//

import SwiftUI
import AevonXCore
import Combine

@MainActor
class PluginsViewModel: ObservableObject {
    @Published var plugins: [Plugin] = []
    @Published var categories: [PluginCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedPricing: String? = nil
    @Published var selectedCategory: String? = nil   // slug
    
    @Published var installedPlugins: [Plugin] = []
    @Published var installationProgress: [String: Double] = [:] // pluginId: progress
    @Published var installationStatus: [String: String] = [:] // pluginId: status message
    
    private let apiService = PluginAPIService.shared
    private let pluginManager = PluginManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Setup search debouncing if needed
    }
    
    func loadMarketplace() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchPlugins(
                search: searchQuery.isEmpty ? nil : searchQuery,
                pricing: selectedPricing,
                category: selectedCategory
            )
            self.plugins = response.data
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load plugins: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func loadCategories() async {
        do {
            self.categories = try await apiService.fetchCategories()
        } catch {
            CoreLogger.shared.error("Failed to load categories: \(error.localizedDescription)", module: "PluginsViewModel")
        }
    }
    
    func installPlugin(_ plugin: Plugin, version: PluginVersion? = nil, on serverId: String) async {
        guard !installationProgress.keys.contains(plugin.id) else { return }
        
        let targetVersion = version ?? plugin.activeVersion
        let versionLabel = targetVersion?.versionNumber ?? "latest"
        
        installationStatus[plugin.id] = "Starting v\(versionLabel)..."
        installationProgress[plugin.id] = 0.1
        
        do {
            // 1. Get one-time download token from API
            installationStatus[plugin.id] = "Requesting download..."
            let downloadInfo = try await apiService.getDownloadInfo(
                id: plugin.id,
                versionId: targetVersion?.id,
                serverId: serverId
            )
            installationProgress[plugin.id] = 0.2
            
            // 2. Download ZIP locally (Mac can reach the API, remote server may not)
            installationStatus[plugin.id] = "Downloading package..."
            guard let url = URL(string: downloadInfo.downloadUrl) else {
                throw NSError(domain: "PluginsViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
            }
            let localZipURL = try await apiService.downloadPluginFile(url: url)
            installationProgress[plugin.id] = 0.5
            
            // 3. Upload ZIP to server + extract + run setup via SSH
            installationStatus[plugin.id] = "Installing on server..."
            try await pluginManager.installPlugin(
                plugin: plugin,
                version: targetVersion,
                zipURL: localZipURL,
                on: serverId
            )
            installationProgress[plugin.id] = 1.0
            installationStatus[plugin.id] = "Installed"
            
            // Refresh installed plugins list
            await loadInstalledPlugins(on: serverId)
            
            // Reload hooks so plugin UI (dashboard, tabs, actions) appears immediately
            await HookLoader.shared.load(serverId: serverId, force: true)
            
            // Clear progress after short delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            installationProgress.removeValue(forKey: plugin.id)
            installationStatus.removeValue(forKey: plugin.id)
            
        } catch {
            CoreLogger.shared.error("Plugin installation failed: \(error.localizedDescription)", module: "PluginsViewModel")
            errorMessage = "Installation failed: \(error.localizedDescription)"
            installationStatus[plugin.id] = "Failed"
            installationProgress.removeValue(forKey: plugin.id)
        }
    }
    
    func loadInstalledPlugins(on serverId: String) async {
        do {
            // If we don't have marketplace data yet, load it so we can map slugs to plugins
            if plugins.isEmpty {
                await loadMarketplace()
            }
            
            let installedSlugs = try await pluginManager.listInstalledPluginSlugs(on: serverId)
            
            var matchedPlugins: [Plugin] = []
            for slug in installedSlugs {
                if let existing = plugins.first(where: { $0.slug == slug }) {
                    matchedPlugins.append(existing)
                } else {
                    // Create a stub Plugin for installed plugins not in marketplace
                    // so they still appear in the installed list
                    let stub = Plugin(
                        id: slug,
                        name: slug,
                        slug: slug,
                        description: "Installed plugin",
                        imageUrl: nil,
                        status: "installed",
                        isOfficial: false,
                        downloadsCount: 0,
                        rating: nil,
                        activeVersion: nil,
                        pricing: nil,
                        user: nil,
                        versions: nil
                    )
                    matchedPlugins.append(stub)
                    CoreLogger.shared.info("Installed plugin \(slug) not in marketplace — showing as stub.", module: "PluginsViewModel")
                }
            }
            
            self.installedPlugins = matchedPlugins
            CoreLogger.shared.info("Loaded \(matchedPlugins.count) installed plugins for server \(serverId)", module: "PluginsViewModel")
            
        } catch {
            CoreLogger.shared.error("Failed to load installed plugins: \(error.localizedDescription)", module: "PluginsViewModel")
        }
    }
    
    func uninstallPlugin(_ plugin: Plugin, on serverId: String) async {
        guard !installationProgress.keys.contains(plugin.id) else { return }
        
        installationStatus[plugin.id] = "Uninstalling..."
        installationProgress[plugin.id] = 0.5
        
        do {
            try await pluginManager.uninstallPlugin(plugin: plugin, on: serverId)
            
            installationStatus[plugin.id] = "Uninstalled"
            installationProgress[plugin.id] = 1.0
            
            // Refresh installed plugins list
            await loadInstalledPlugins(on: serverId)
            
            // Reload hooks to remove plugin UI elements
            await HookLoader.shared.load(serverId: serverId, force: true)
            
            // Clear progress after short delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            installationProgress.removeValue(forKey: plugin.id)
            installationStatus.removeValue(forKey: plugin.id)
            
        } catch {
            CoreLogger.shared.error("Plugin uninstallation failed: \(error.localizedDescription)", module: "PluginsViewModel")
            errorMessage = "Uninstallation failed: \(error.localizedDescription)"
            installationStatus[plugin.id] = "Failed"
            installationProgress.removeValue(forKey: plugin.id)
        }
    }
}
