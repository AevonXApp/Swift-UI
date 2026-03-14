//
//  PluginsViewModel.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge
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
    @Published var installationStatus: [String: String] = [:]   // pluginId: status message
    @Published var installSources: [String: InstallSource] = [:] // slug: source
    
    private let apiService = PluginAPIService.shared   // only for downloadPluginFile
    private let pluginManager = PluginManager.shared
    private let apiBridge = APIBridge.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var baseURL: String {
        AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }
    
    init() {}
    
    func loadMarketplace() async {
        isLoading = true
        errorMessage = nil
        
        let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
        let resultJSON = await apiBridge.fetchPluginsAsync(
            baseURL: baseURL, token: token,
            page: 1,
            search: searchQuery.isEmpty ? "" : searchQuery,
            pricing: selectedPricing ?? "",
            category: selectedCategory ?? ""
        )
        
        if let data = parseGoResult(resultJSON),
           let pluginsData = data["plugins"] as? [String: Any],
           let pluginsArray = pluginsData["data"] as? [[String: Any]],
           let pluginsJSON = try? JSONSerialization.data(withJSONObject: pluginsArray) {
            let decoder = JSONDecoder()
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(fmt)
            self.plugins = (try? decoder.decode([Plugin].self, from: pluginsJSON)) ?? []
        } else {
            self.errorMessage = "Failed to load plugins: \(extractGoError(resultJSON))"
        }
        self.isLoading = false
    }
    
    func loadCategories() async {
        let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
        let resultJSON = await apiBridge.fetchPluginCategoriesAsync(baseURL: baseURL, token: token)
        
        if let data = parseGoResult(resultJSON),
           let catsArray = data["categories"] as? [[String: Any]],
           let catsJSON = try? JSONSerialization.data(withJSONObject: catsArray) {
            let decoder = JSONDecoder()
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(fmt)
            self.categories = (try? decoder.decode([PluginCategory].self, from: catsJSON)) ?? []
        } else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to load categories via Go", module: "PluginsViewModel")
        }
    }
    
    func installPlugin(_ plugin: Plugin, version: PluginVersion? = nil, on serverId: String) async {
        guard !installationProgress.keys.contains(plugin.id) else { return }
        
        let targetVersion = version ?? plugin.activeVersion
        let versionLabel = targetVersion?.versionNumber ?? "latest"
        
        installationStatus[plugin.id] = "Starting v\(versionLabel)..."
        installationProgress[plugin.id] = 0.1
        
        do {
            // 1. Get one-time download token via Go HTTP
            installationStatus[plugin.id] = "Requesting download..."
            let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
            let downloadJSON = await apiBridge.getPluginDownloadInfoAsync(
                baseURL: baseURL, token: token,
                pluginID: plugin.id,
                versionID: targetVersion?.id ?? "",
                serverID: serverId
            )
            
            guard let dlData = parseGoResult(downloadJSON),
                  let downloadUrl = dlData["download_url"] as? String else {
                throw NSError(domain: "PluginsViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: extractGoError(downloadJSON)])
            }
            installationProgress[plugin.id] = 0.2
            
            // 2. Download ZIP locally (stays in Swift — needs URLSession.download)
            installationStatus[plugin.id] = "Downloading package..."
            guard let url = URL(string: downloadUrl) else {
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
            await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)
            
            // Clear progress after short delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            installationProgress.removeValue(forKey: plugin.id)
            installationStatus.removeValue(forKey: plugin.id)
            
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Plugin installation failed: \(error.localizedDescription)", module: "PluginsViewModel")
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
            
            // Fetch installed slugs and install sources concurrently
            async let slugsTask   = pluginManager.listInstalledPluginSlugs(on: serverId)
            async let sourcesTask = pluginManager.listInstalledSources(on: serverId)
            
            let (installedSlugs, sources) = try await (slugsTask, sourcesTask)
            self.installSources = sources
            
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
                    // Stubs are always dev-build (server-owner installs)
                    if self.installSources[slug] == nil {
                        self.installSources[slug] = .devBuild
                    }
                    AevonXCoreBridge.CoreLogger.shared.info("Installed plugin \(slug) not in marketplace — showing as dev build.", module: "PluginsViewModel")
                }
            }
            
            self.installedPlugins = matchedPlugins
            AevonXCoreBridge.CoreLogger.shared.info("Loaded \(matchedPlugins.count) installed plugins for server \(serverId)", module: "PluginsViewModel")
            
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to load installed plugins: \(error.localizedDescription)", module: "PluginsViewModel")
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
            await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)
            
            // Clear progress after short delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            installationProgress.removeValue(forKey: plugin.id)
            installationStatus.removeValue(forKey: plugin.id)
            
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Plugin uninstallation failed: \(error.localizedDescription)", module: "PluginsViewModel")
            errorMessage = "Uninstallation failed: \(error.localizedDescription)"
            installationStatus[plugin.id] = "Failed"
            installationProgress.removeValue(forKey: plugin.id)
        }
    }
    
    // MARK: - Go Bridge Helpers
    
    private func parseGoResult(_ json: String) -> [String: Any]? {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              result["success"] as? Bool == true,
              let dataVal = result["data"] as? [String: Any] else { return nil }
        return dataVal
    }
    
    private func extractGoError(_ json: String) -> String {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              let error = result["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return "An unexpected error occurred"
        }
        return message
    }
}
