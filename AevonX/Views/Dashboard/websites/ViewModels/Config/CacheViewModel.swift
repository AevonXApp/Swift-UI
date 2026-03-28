//
//  CacheViewModel.swift
//  AevonX
//
//  ViewModel for per-site cache management — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class CacheViewModel: ObservableObject {
    @Published var cacheStatuses: [SiteCacheStatus] = []
    @Published var browserCacheRules: [BrowserCacheRule] = []
    @Published var isPurging = false
    @Published var errorMessage: String?

    let serverId: String
    let domain: String
    let engine: String
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, engine: String = "nginx") {
        self.serverId = serverId
        self.domain = domain
        self.engine = engine
    }

    func loadCacheStatus() async {
        // Check if FastCGI cache exists
        let fcgiResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.fastCGICacheStatusCmd())
        let fcgiEnabled = fcgiResult.trimmingCharacters(in: .whitespacesAndNewlines) == "enabled"
        
        cacheStatuses = [
            SiteCacheStatus(type: .fastcgi, enabled: fcgiEnabled),
            SiteCacheStatus(type: .browser, enabled: true),
        ]
        
        // Read real browser cache rules from config
        await detectPathsIfNeeded()
        let configPath = resolveConfigPath()
        let cacheCmd = "sudo grep -A2 'location.*\\.' \(configPath) 2>/dev/null | grep -E 'expires|add_header.*Cache' || true"
        let cacheOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: cacheCmd)
        browserCacheRules = parseBrowserCacheRules(cacheOutput)
    }

    func purgeSpecificCache(_ type: SiteCacheType) async {
        isPurging = true
        defer { isPurging = false }
        let cmd: String
        switch type {
        case .fastcgi:
            cmd = bridge.purgeFastCGICmd()
        default:
            cmd = bridge.purgeAllCachesCmd()
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        GlobalToastManager.shared.showSuccess("\(type.rawValue) cache purged")
    }

    func purgeAllCache() async {
        isPurging = true
        defer { isPurging = false }
        await detectPathsIfNeeded()
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.purgeAllCachesCmdRouted(engine: engine, cacheDir: serverPaths.cacheDir))
        GlobalToastManager.shared.showSuccess("All caches purged")
    }

    private func resolveConfigPath() -> String {
        let sa = engine == "apache" ? serverPaths.apacheSitesAvailable : serverPaths.nginxSitesAvailable
        if engine == "apache" { return "\(sa)/\(domain).conf" }
        if serverPaths.serverType == "bt_panel" || sa.contains("/www/server") || sa.contains("/conf.d") || sa.contains("/vhost") {
            return "\(sa)/\(domain).conf"
        }
        return "\(sa)/\(domain)"
    }

    private func parseBrowserCacheRules(_ output: String) -> [BrowserCacheRule] {
        // Parse lines like "expires 30d;" and "add_header Cache-Control "public";"
        let lines = output.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var rules: [BrowserCacheRule] = []
        var currentDuration = ""
        var currentCacheControl = ""
        for line in lines {
            if line.hasPrefix("expires") {
                let val = line.replacingOccurrences(of: "expires", with: "").trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ";", with: "")
                currentDuration = val
            } else if line.contains("Cache-Control") {
                let parts = line.components(separatedBy: "\"")
                if parts.count >= 2 { currentCacheControl = parts[1] }
            }
            if !currentDuration.isEmpty {
                rules.append(BrowserCacheRule(fileTypes: "static assets", duration: currentDuration, cacheControl: currentCacheControl.isEmpty ? "—" : currentCacheControl))
                currentDuration = ""
                currentCacheControl = ""
            }
        }
        // Fallback: if no rules detected, show a helpful message
        if rules.isEmpty {
            rules.append(BrowserCacheRule(fileTypes: "No cache rules configured", duration: "—", cacheControl: "—"))
        }
        return rules
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
