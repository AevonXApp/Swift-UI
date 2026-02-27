//
//  CacheConfig.swift
//  AevonX
//
//  Models for per-site cache management (FastCGI, Proxy, Browser, Redis, OPcache)
//

import Foundation
import SwiftUI

// MARK: - Cache Type

enum SiteCacheType: String, CaseIterable, Identifiable {
    case fastcgi = "FastCGI Cache"
    case proxy = "Proxy Cache"
    case browser = "Browser Cache"
    case redis = "Redis Object Cache"
    case opcache = "OPcache"
    case staticFiles = "Static File Cache"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fastcgi: return "bolt.circle.fill"
        case .proxy: return "arrow.left.arrow.right.circle.fill"
        case .browser: return "clock.fill"
        case .redis: return "cylinder.fill"
        case .opcache: return "memorychip.fill"
        case .staticFiles: return "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .fastcgi: return .orange
        case .proxy: return .blue
        case .browser: return .green
        case .redis: return .red
        case .opcache: return .purple
        case .staticFiles: return .cyan
        }
    }

    var description: String {
        switch self {
        case .fastcgi: return "Cache PHP responses via Nginx FastCGI"
        case .proxy: return "Cache proxied responses from backend"
        case .browser: return "Set Cache-Control and Expires headers"
        case .redis: return "In-memory object cache for WordPress/Laravel"
        case .opcache: return "PHP bytecode cache for faster execution"
        case .staticFiles: return "Cache static assets (CSS, JS, images)"
        }
    }
}

// MARK: - Cache Status

struct SiteCacheStatus: Identifiable {
    let id = UUID()
    let type: SiteCacheType
    var enabled: Bool
    var hitRate: Double?
    var size: String?
    var entries: Int?
}

// MARK: - Browser Cache Rule

struct BrowserCacheRule: Identifiable, Hashable {
    let id = UUID()
    var fileTypes: String   // e.g., "css|js|png|jpg"
    var duration: String    // e.g., "30d", "1y"
    var cacheControl: String // e.g., "public, no-transform"

    static var defaults: [BrowserCacheRule] {
        [
            BrowserCacheRule(fileTypes: "css|js", duration: "30d", cacheControl: "public, no-transform"),
            BrowserCacheRule(fileTypes: "png|jpg|jpeg|gif|ico|svg|webp", duration: "1y", cacheControl: "public, immutable"),
            BrowserCacheRule(fileTypes: "woff|woff2|ttf|eot", duration: "1y", cacheControl: "public, immutable"),
        ]
    }
}
