//
//  PluginsViewModel.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

import Combine

/// Error with a user-friendly message that does not expose project internals.
struct PluginInstallError: LocalizedError {
    let userMessage: String
    var errorDescription: String? { userMessage }
}

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
        let log = AevonXCoreBridge.CoreLogger.shared

        log.info("[Marketplace] ▶ Loading plugins (search='\(searchQuery)', pricing=\(selectedPricing ?? "all"), category=\(selectedCategory ?? "all"))", module: "PluginsVM")
        let start = CFAbsoluteTimeGetCurrent()

        let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
        let resultJSON = await apiBridge.fetchPluginsAsync(
            baseURL: baseURL, token: token,
            page: 1,
            search: searchQuery.isEmpty ? "" : searchQuery,
            pricing: selectedPricing ?? "",
            category: selectedCategory ?? ""
        )

        let duration = CFAbsoluteTimeGetCurrent() - start

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
            log.info("[Marketplace] ✓ Loaded \(self.plugins.count) plugins in \(String(format: "%.2f", duration))s", module: "PluginsVM")
        } else {
            let err = extractGoError(resultJSON)
            log.error("[Marketplace] ✖ Failed to load plugins after \(String(format: "%.2f", duration))s: \(err)", module: "PluginsVM")
            self.errorMessage = "Unable to load plugins. Please check your connection and try again."
        }
        self.isLoading = false
    }
    
    func loadCategories() async {
        let log = AevonXCoreBridge.CoreLogger.shared
        log.info("[Marketplace] ▶ Loading categories...", module: "PluginsVM")
        let start = CFAbsoluteTimeGetCurrent()

        let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
        let resultJSON = await apiBridge.fetchPluginCategoriesAsync(baseURL: baseURL, token: token)

        let duration = CFAbsoluteTimeGetCurrent() - start

        if let data = parseGoResult(resultJSON),
           let catsArray = data["categories"] as? [[String: Any]],
           let catsJSON = try? JSONSerialization.data(withJSONObject: catsArray) {
            let decoder = JSONDecoder()
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(fmt)
            self.categories = (try? decoder.decode([PluginCategory].self, from: catsJSON)) ?? []
            log.info("[Marketplace] ✓ Loaded \(self.categories.count) categories in \(String(format: "%.2f", duration))s", module: "PluginsVM")
        } else {
            log.error("[Marketplace] ✖ Failed to load categories after \(String(format: "%.2f", duration))s", module: "PluginsVM")
        }
    }
    
    func installPlugin(_ plugin: Plugin, version: PluginVersion? = nil, on serverId: String, serverIP: String = "") async {
        guard !installationProgress.keys.contains(plugin.id) else { return }

        let targetVersion = version ?? plugin.activeVersion
        let versionLabel = targetVersion?.versionNumber ?? "latest"
        let log = AevonXCoreBridge.CoreLogger.shared
        let startTime = CFAbsoluteTimeGetCurrent()
        let pricingType = plugin.pricing?.pricingType ?? "free"

        log.info("[PluginInstall] ▶ Starting install: \(plugin.slug) v\(versionLabel) on server \(serverId)", module: "PluginsVM")
        log.info("[PluginInstall] Pricing: \(pricingType), serverIP: \(serverIP)", module: "PluginsVM")

        installationStatus[plugin.id] = "Starting v\(versionLabel)..."
        installationProgress[plugin.id] = 0.1

        do {
            // ── Step 1: Verify license (ALWAYS) ──
            installationStatus[plugin.id] = "Verifying license..."
            log.info("[PluginInstall] Step 1: Verifying license for \(plugin.slug)...", module: "PluginsVM")

            let licenseResult = await pluginManager.verifyLicense(slug: plugin.slug, on: serverId)
            log.info("[PluginInstall] Step 1 result: valid=\(licenseResult.valid), type=\(licenseResult.pricingType), reason=\(licenseResult.reason ?? "none"), ttl=\(licenseResult.ttl ?? 0)", module: "PluginsVM")

            if !licenseResult.valid {
                let userMsg = licenseResult.userMessage ?? "Plugin license verification failed."
                log.error("[PluginInstall] ✖ License denied: \(userMsg)", module: "PluginsVM")
                throw PluginInstallError(userMessage: userMsg)
            }
            installationProgress[plugin.id] = 0.2

            // ── Step 2: Get download token ──
            installationStatus[plugin.id] = "Requesting download..."
            let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
            log.info("[PluginInstall] Step 2: Requesting download token", module: "PluginsVM")

            let downloadJSON = await apiBridge.getPluginDownloadInfoAsync(
                baseURL: baseURL, token: token,
                pluginID: plugin.id,
                versionID: targetVersion?.id ?? "",
                serverID: serverId,
                serverIP: ""
            )

            guard let dlData = parseGoResult(downloadJSON),
                  let downloadUrl = dlData["download_url"] as? String else {
                let err = extractGoError(downloadJSON)
                log.error("[PluginInstall] ✖ Download token failed: \(err)", module: "PluginsVM")
                throw PluginInstallError(userMessage: "Failed to prepare download. Please try again.")
            }

            let fileSize = dlData["file_size"] as? Int
            log.info("[PluginInstall] Step 2 ✓ Token received, size: \(fileSize.map { "\($0) bytes" } ?? "?")", module: "PluginsVM")
            installationProgress[plugin.id] = 0.25

            // ── Step 3: Secure encrypted install pipeline ──
            installationStatus[plugin.id] = "Preparing secure install..."
            log.info("[PluginInstall] Step 3: Secure encrypted transit pipeline", module: "PluginsVM")

            let installStart = CFAbsoluteTimeGetCurrent()
            try await pluginManager.installSecure(
                plugin: plugin,
                version: targetVersion,
                downloadURL: downloadUrl,
                serverId: serverId,
                serverIP: serverIP,
                baseURL: baseURL,
                token: token,
                licenseToken: licenseResult.licenseToken,
                tokenSignature: licenseResult.tokenSignature,
                nonce: licenseResult.nonce,
                onProgress: { [weak self] status, progress in
                    Task { @MainActor in
                        self?.installationStatus[plugin.id] = status
                        self?.installationProgress[plugin.id] = progress
                    }
                }
            )
            let installDuration = CFAbsoluteTimeGetCurrent() - installStart
            log.info("[PluginInstall] Step 3 ✓ Secure install in \(String(format: "%.1f", installDuration))s", module: "PluginsVM")

            installationProgress[plugin.id] = 0.9
            installationStatus[plugin.id] = "Finalizing..."

            // Step 4: Post-install
            log.info("[PluginInstall] Step 4: Refreshing installed plugins list...", module: "PluginsVM")
            await loadInstalledPlugins(on: serverId)

            log.info("[PluginInstall] Step 5: Reloading hooks...", module: "PluginsVM")
            await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)

            installationProgress[plugin.id] = 1.0
            installationStatus[plugin.id] = "Installed"

            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.info("[PluginInstall] ✅ \(plugin.slug) installed in \(String(format: "%.1f", totalDuration))s", module: "PluginsVM")

            // Clear progress after short delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            installationProgress.removeValue(forKey: plugin.id)
            installationStatus.removeValue(forKey: plugin.id)

        } catch let error as PluginInstallError {
            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("[PluginInstall] ✖ FAILED after \(String(format: "%.1f", totalDuration))s: \(error.userMessage)", module: "PluginsVM")
            errorMessage = error.userMessage
            installationStatus[plugin.id] = "Failed"
            installationProgress.removeValue(forKey: plugin.id)
        } catch {
            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("[PluginInstall] ✖ FAILED after \(String(format: "%.1f", totalDuration))s: \(error.localizedDescription)", module: "PluginsVM")
            errorMessage = "Installation failed. Please try again later."
            installationStatus[plugin.id] = "Failed"
            installationProgress.removeValue(forKey: plugin.id)
        }
    }
    
    func loadInstalledPlugins(on serverId: String) async {
        let log = AevonXCoreBridge.CoreLogger.shared
        log.info("[InstalledPlugins] ▶ Loading installed plugins for server \(serverId)...", module: "PluginsVM")
        let start = CFAbsoluteTimeGetCurrent()

        do {
            if plugins.isEmpty {
                log.info("[InstalledPlugins] Marketplace empty — loading first...", module: "PluginsVM")
                await loadMarketplace()
            }

            async let slugsTask   = pluginManager.listInstalledPluginSlugs(on: serverId)
            async let sourcesTask = pluginManager.listInstalledSources(on: serverId)

            let (installedSlugs, sources) = try await (slugsTask, sourcesTask)
            self.installSources = sources
            log.info("[InstalledPlugins] Found \(installedSlugs.count) installed slugs: \(installedSlugs.joined(separator: ", "))", module: "PluginsVM")
            
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
            let duration = CFAbsoluteTimeGetCurrent() - start
            log.info("[InstalledPlugins] ✓ Loaded \(matchedPlugins.count) installed plugins in \(String(format: "%.2f", duration))s", module: "PluginsVM")

        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - start
            log.error("[InstalledPlugins] ✖ Failed after \(String(format: "%.2f", duration))s: \(error.localizedDescription)", module: "PluginsVM")
        }
    }
    
    func uninstallPlugin(_ plugin: Plugin, on serverId: String) async {
        guard !installationProgress.keys.contains(plugin.id) else { return }

        let log = AevonXCoreBridge.CoreLogger.shared
        let startTime = CFAbsoluteTimeGetCurrent()
        log.info("[PluginUninstall] ▶ Starting uninstall: \(plugin.slug) from server \(serverId)", module: "PluginsVM")

        installationStatus[plugin.id] = "Uninstalling..."
        installationProgress[plugin.id] = 0.5

        do {
            try await pluginManager.uninstallPlugin(plugin: plugin, on: serverId)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            log.info("[PluginUninstall] ✓ Removed \(plugin.slug) in \(String(format: "%.1f", duration))s", module: "PluginsVM")

            installationStatus[plugin.id] = "Uninstalled"
            installationProgress[plugin.id] = 1.0

            log.info("[PluginUninstall] Refreshing installed plugins list...", module: "PluginsVM")
            await loadInstalledPlugins(on: serverId)

            log.info("[PluginUninstall] Reloading hooks...", module: "PluginsVM")
            await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)

            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.info("[PluginUninstall] ✅ \(plugin.slug) fully uninstalled in \(String(format: "%.1f", totalDuration))s", module: "PluginsVM")

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            installationProgress.removeValue(forKey: plugin.id)
            installationStatus.removeValue(forKey: plugin.id)

        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("[PluginUninstall] ✖ FAILED after \(String(format: "%.1f", duration))s: \(error.localizedDescription)", module: "PluginsVM")
            errorMessage = "Uninstallation failed. Please try again later."
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
