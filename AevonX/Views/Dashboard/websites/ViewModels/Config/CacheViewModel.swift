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
    private let bridge = WebsitesBridge.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadCacheStatus() async {
        do {
            // Check if FastCGI cache exists
            let fcgiResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "[ -d /var/cache/nginx/fastcgi ] && echo enabled || echo disabled")
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purgeSpecificCache(_ type: SiteCacheType) async {
        isPurging = true
        defer { isPurging = false }
        do {
            let cmd: String
            switch type {
            case .fastcgi:
                cmd = bridge.purgeFastCGICmd()
            default:
                cmd = bridge.purgeAllCachesCmd()
            }
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            GlobalToastManager.shared.showSuccess("\(type.rawValue) cache purged")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purgeAllCache() async {
        isPurging = true
        defer { isPurging = false }
        do {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.purgeAllCachesCmd())
            GlobalToastManager.shared.showSuccess("All caches purged")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
