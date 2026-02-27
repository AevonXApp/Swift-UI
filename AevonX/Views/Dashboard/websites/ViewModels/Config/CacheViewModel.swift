//
//  CacheViewModel.swift
//  AevonX
//
//  ViewModel for per-site cache management — delegates to SiteCacheService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class CacheViewModel: ObservableObject {
    @Published var cacheStatuses: [SiteCacheStatus] = []
    @Published var browserCacheRules: [BrowserCacheRule] = []
    @Published var isPurging = false
    @Published var errorMessage: String?

    let serverId: String
    let domain: String
    private let service = SiteCacheService.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadCacheStatus() async {
        do {
            let statuses = try await service.detectCacheStatus(domain: domain, serverId: serverId)
            cacheStatuses = statuses.map {
                SiteCacheStatus(
                    type: SiteCacheType(rawValue: $0.type.capitalized) ?? .browser,
                    enabled: $0.enabled
                )
            }
            // Default browser rules
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
            let message = try await service.purgeCache(type: type.rawValue.lowercased(), domain: domain, serverId: serverId)
            GlobalToastManager.shared.showSuccess(message)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purgeAllCache() async {
        isPurging = true
        defer { isPurging = false }
        do {
            let message = try await service.purgeAllCaches(domain: domain, serverId: serverId)
            GlobalToastManager.shared.showSuccess(message)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
