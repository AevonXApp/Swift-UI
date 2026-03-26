//
//  AXPluginGateView.swift
//  AevonX
//
//  Reusable gate view for first-party AXPlugins.
//  Checks if the plugin is installed on the server:
//    - Installed → renders the plugin's custom content view
//    - Not installed (free) → shows install button
//    - Not installed (paid) → shows purchase prompt
//
//  Usage:
//    AXPluginGateView(slug: "axcerberus-waf", serverId: serverId) {
//        CerberusRootView(serverId: serverId)
//    }
//

import SwiftUI
import Combine
import AevonXCoreBridge

struct AXPluginGateView<Content: View>: View {
    let slug: String
    let serverId: String
    @ViewBuilder let content: () -> Content

    @StateObject private var gate = AXPluginGateViewModel()

    var body: some View {
        Group {
            switch gate.state {
            case .loading:
                loadingSkeleton
            case .installed:
                content()
            case .notInstalled:
                notInstalledView
            case .licenseRequired(let message):
                licenseRequiredView(message)
            case .error(let message):
                errorView(message)
            }
        }
        .task {
            await gate.check(slug: slug, serverId: serverId)
        }
    }

    // MARK: - Loading

    private var loadingSkeleton: some View {
        VStack(spacing: AXSpacing.lg) {
            AXSkeletonStatCard()
            AXSkeletonBlock(lines: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xxxxl)
    }

    // MARK: - Not Installed

    private var notInstalledView: some View {
        VStack(spacing: AXSpacing.xxl) {
            Spacer()

            pluginIcon

            Text(gate.pluginInfo?.name ?? slug)
                .font(AXTypography.title2)
                .foregroundStyle(Color.axTextPrimary)

            Text(gate.pluginInfo?.description ?? "This plugin is not installed on this server.")
                .font(AXTypography.body)
                .foregroundStyle(Color.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            pricingBadge

            installAction

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }

    private var pluginIcon: some View {
        Image(systemName: "puzzlepiece.extension")
            .font(.system(size: 48))
            .foregroundStyle(Color.axAccentBlue)
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.1))
            )
    }

    @ViewBuilder
    private var pricingBadge: some View {
        if let pricing = gate.pluginInfo?.pricing {
            if pricing.isFree {
                AXBadge(text: "Free", color: .axSuccess, style: .soft)
            } else if pricing.isPaid {
                AXBadge(text: pricing.price ?? "Paid", color: .axAccentBlue, style: .soft)
            } else if pricing.isSubscribers {
                AXBadge(text: "Pro", color: .axWarning, style: .soft)
            }
        }
    }

    @ViewBuilder
    private var installAction: some View {
        if let pricing = gate.pluginInfo?.pricing,
           (pricing.isPaid || pricing.isSubscribers),
           gate.pluginInfo?.isPurchased != true {
            // Paid / Subscribers and NOT purchased → link to purchase
            VStack(spacing: AXSpacing.sm) {
                AXPrimaryButton(
                    title: "Get Plugin",
                    icon: "cart",
                    action: { gate.openPurchasePage() }
                )
                Text("Opens in browser")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
        } else {
            // Free → direct install
            VStack(spacing: AXSpacing.sm) {
                AXPrimaryButton(
                    title: "Install Plugin",
                    icon: "arrow.down.circle",
                    action: {
                        Task { await gate.install(slug: slug, serverId: serverId) }
                    },
                    isLoading: gate.isInstalling
                )

                if let status = gate.installStatus {
                    HStack(spacing: AXSpacing.xs) {
                        if gate.isInstalling {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        }
                        Text(status)
                            .font(AXTypography.caption)
                            .foregroundStyle(Color.axTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - License Required (free→paid transition)

    private func licenseRequiredView(_ message: String) -> some View {
        VStack(spacing: AXSpacing.xxl) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(Color.axWarning)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.axWarning.opacity(0.1))
                )

            Text(gate.pluginInfo?.name ?? slug)
                .font(AXTypography.title2)
                .foregroundStyle(Color.axTextPrimary)

            Text(message)
                .font(AXTypography.body)
                .foregroundStyle(Color.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            pricingBadge

            VStack(spacing: AXSpacing.sm) {
                AXPrimaryButton(
                    title: "Get License",
                    icon: "cart",
                    action: { gate.openPurchasePage() }
                )
                Text("Opens in browser")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.axWarning)

            Text("Failed to check plugin status")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)

            Text(message)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            AXPrimaryButton(
                title: L10n.Button.retry,
                icon: "arrow.clockwise",
                action: {
                    Task { await gate.check(slug: slug, serverId: serverId) }
                },
                style: .secondary
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - ViewModel

@MainActor
class AXPluginGateViewModel: ObservableObject {

    enum GateState {
        case loading
        case installed
        case notInstalled
        case licenseRequired(String) // installed but license invalid — message
        case error(String)
    }

    @Published var state: GateState = .loading
    @Published var pluginInfo: Plugin?
    @Published var isInstalling = false
    @Published var installStatus: String?

    private let pluginManager = PluginManager.shared
    private let apiBridge = APIBridge.shared

    private var baseURL: String {
        AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }

    // MARK: - Check Installation

    func check(slug: String, serverId: String) async {
        state = .loading
        do {
            let installedSlugs = try await pluginManager.listInstalledPluginSlugs(on: serverId)
            let isInstalled = installedSlugs.contains(slug)

            if isInstalled {
                // Plugin is on the server — verify license is still valid
                // (handles free→paid transitions, expired subscriptions, etc.)
                let licenseResult = await pluginManager.verifyLicense(slug: slug, on: serverId)

                if licenseResult.valid {
                    state = .installed
                } else {
                    // Installed but license no longer valid
                    AevonXCoreBridge.CoreLogger.shared.warning(
                        "[PluginGate] \(slug) installed but license invalid: \(licenseResult.reason ?? "unknown")",
                        module: "PluginGate"
                    )
                    await fetchPluginInfo(slug: slug)
                    let message = licenseResult.userMessage ?? "A valid license is required to use this plugin."
                    state = .licenseRequired(message)
                }
                return
            }

            // Not installed — fetch plugin info from API for pricing/description
            await fetchPluginInfo(slug: slug)
            state = .notInstalled
        } catch {
            state = .error("Unable to check plugin status. Please try again.")
        }
    }

    // MARK: - Fetch Plugin Info

    private func fetchPluginInfo(slug: String) async {
        let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
        let json = await apiBridge.fetchPluginsAsync(
            baseURL: baseURL, token: token,
            page: 1, search: slug, pricing: "", category: ""
        )

        guard let data = parseGoResult(json) else {
            AevonXCoreBridge.CoreLogger.shared.error("[PluginGate] parseGoResult failed for slug: \(slug)", module: "PluginGate")
            return
        }

        guard let pluginsData = data["plugins"] as? [String: Any] else {
            AevonXCoreBridge.CoreLogger.shared.error("[PluginGate] 'plugins' key missing. Keys: \(Array(data.keys))", module: "PluginGate")
            return
        }

        guard let pluginsArray = pluginsData["data"] as? [[String: Any]] else {
            AevonXCoreBridge.CoreLogger.shared.error("[PluginGate] 'data' array missing in plugins. Keys: \(Array(pluginsData.keys))", module: "PluginGate")
            return
        }

        guard let pluginsJSON = try? JSONSerialization.data(withJSONObject: pluginsArray) else {
            AevonXCoreBridge.CoreLogger.shared.error("[PluginGate] JSON serialization failed", module: "PluginGate")
            return
        }

        let decoder = JSONDecoder()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(fmt)

        do {
            let plugins = try decoder.decode([Plugin].self, from: pluginsJSON)
            AevonXCoreBridge.CoreLogger.shared.info("[PluginGate] Decoded \(plugins.count) plugins, looking for slug: \(slug)", module: "PluginGate")
            pluginInfo = plugins.first { $0.slug == slug }
            if pluginInfo == nil {
                let slugs = plugins.map { $0.slug }
                AevonXCoreBridge.CoreLogger.shared.error("[PluginGate] Slug '\(slug)' not found. Available: \(slugs)", module: "PluginGate")
            }
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("[PluginGate] Decode failed: \(error)", module: "PluginGate")
        }
    }

    // MARK: - Install

    func install(slug: String, serverId: String) async {
        guard let plugin = pluginInfo else {
            // If we don't have info, try to fetch it first
            await fetchPluginInfo(slug: slug)
            guard let plugin = pluginInfo else {
                GlobalToastManager.shared.showError("Plugin info not available")
                return
            }
            await performInstall(plugin: plugin, serverId: serverId)
            return
        }
        await performInstall(plugin: plugin, serverId: serverId)
    }

    private func performInstall(plugin: Plugin, serverId: String) async {
        isInstalling = true
        installStatus = "Verifying license..."

        let log = AevonXCoreBridge.CoreLogger.shared
        let startTime = CFAbsoluteTimeGetCurrent()
        let isDevMode = PluginManager.isDevBuild

        log.info("[PluginGate] ▶ Starting install: \(plugin.slug) on server \(serverId)", module: "PluginGate")
        log.info("[PluginGate] Mode: \(isDevMode ? "DEV" : "PROD")", module: "PluginGate")

        do {
            // ── Step 1: Verify license (ALWAYS) ──
            log.info("[PluginGate] Step 1: Verifying license...", module: "PluginGate")
            let licenseResult = await pluginManager.verifyLicense(slug: plugin.slug, on: serverId)
            log.info("[PluginGate] License: valid=\(licenseResult.valid), type=\(licenseResult.pricingType), reason=\(licenseResult.reason ?? "none")", module: "PluginGate")

            if !licenseResult.valid {
                throw PluginInstallError(userMessage: licenseResult.userMessage ?? "Plugin license verification failed.")
            }

            // ── Step 2: Install via secure path (blind relay or legacy) ──
            installStatus = "Preparing secure install..."
            let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
            let targetVersion = plugin.activeVersion

            // Get download info for legacy fallback path
            let downloadJSON = await apiBridge.getPluginDownloadInfoAsync(
                baseURL: baseURL, token: token,
                pluginID: plugin.id,
                versionID: targetVersion?.id ?? "",
                serverID: serverId,
                serverIP: ""
            )
            let dlData = parseGoResult(downloadJSON)
            let downloadUrl = dlData?["download_url"] as? String ?? ""

            log.info("[PluginGate] Step 2: Secure install (blind relay if license token available)", module: "PluginGate")
            try await pluginManager.installSecure(
                plugin: plugin,
                version: targetVersion,
                downloadURL: downloadUrl,
                serverId: serverId,
                serverIP: "",
                baseURL: baseURL,
                token: token,
                licenseToken: licenseResult.licenseToken,
                tokenSignature: licenseResult.tokenSignature,
                nonce: licenseResult.nonce
            ) { status, progress in
                Task { @MainActor in
                    self.installStatus = status
                }
            }

            // Step 3: Reload hooks
            installStatus = "Finalizing..."
            log.info("[PluginGate] Reloading hooks...", module: "PluginGate")
            await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)

            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.info("[PluginGate] ✅ \(plugin.slug) installed in \(String(format: "%.1f", totalDuration))s", module: "PluginGate")

            GlobalToastManager.shared.showSuccess("\(plugin.name) installed successfully")
            state = .installed

        } catch let error as PluginInstallError {
            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("[PluginGate] ✖ FAILED after \(String(format: "%.1f", totalDuration))s: \(error.userMessage)", module: "PluginGate")
            GlobalToastManager.shared.showError(error.userMessage)
            installStatus = nil
        } catch {
            let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("[PluginGate] ✖ FAILED after \(String(format: "%.1f", totalDuration))s: \(error.localizedDescription)", module: "PluginGate")
            GlobalToastManager.shared.showError("Installation failed. Please try again later.")
            installStatus = nil
        }

        isInstalling = false
    }

    // MARK: - Purchase

    func openPurchasePage() {
        guard let plugin = pluginInfo else { return }
        let urlString = "\(baseURL)/plugins/\(plugin.slug)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - JSON Helpers

    private func parseGoResult(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["success"] as? Bool == true,
              let inner = obj["data"] as? [String: Any] else { return nil }
        return inner
    }

    private func extractGoError(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return "Unknown error" }
        return obj["error"] as? String ?? "Unknown error"
    }
}
