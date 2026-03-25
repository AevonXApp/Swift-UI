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
        
        browserCacheRules = [
            BrowserCacheRule(fileTypes: "*.jpg, *.png, *.gif, *.webp", duration: "30 days", cacheControl: "public"),
            BrowserCacheRule(fileTypes: "*.css, *.js", duration: "7 days", cacheControl: "public, no-transform"),
            BrowserCacheRule(fileTypes: "*.woff, *.woff2", duration: "1 year", cacheControl: "public, immutable"),
            BrowserCacheRule(fileTypes: "*.svg, *.ico", duration: "30 days", cacheControl: "public"),
        ]
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

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
