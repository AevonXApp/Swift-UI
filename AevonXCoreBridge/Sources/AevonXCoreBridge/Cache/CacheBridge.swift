//
//  CacheBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core cache management.
//

import Foundation
import AevonXCoreLib

// MARK: - Cache Category

/// Cache TTL categories matching Go Core.
public enum BridgeCacheCategory: Int32, Sendable {
    /// Static data (OS info, paths). TTL: 24 hours.
    case `static` = 0
    /// Semi-static data (service status, configs). TTL: 5 minutes.
    case semiStatic = 1
    /// Dynamic data (CPU, memory). TTL: 30 seconds.
    case dynamic = 2
}

// MARK: - Cache Bridge

/// Bridge to Go Core cache manager.
public final class CacheBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = CacheBridge()
    private init() {}

    /// Stores a string value in the cache.
    public func set(key: String, value: String, category: BridgeCacheCategory, serverID: String = "") {
        withCArgs { c in CacheSet(c.str(key), c.str(value), category.rawValue, c.str(serverID)) }
    }

    /// Retrieves a cached string value.
    public func get(key: String) -> String? {
        let result = withCArgs { c in CacheGet(c.str(key)) }
        defer { CoreFreeString(result) }

        guard let cStr = result else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let response = try? JSONDecoder().decode(BridgeResponse.self, from: data),
              response.success,
              let responseData = response.data,
              let dict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let value = dict["value"] as? String else {
            return nil
        }
        return value
    }

    /// Invalidates a specific cache key.
    public func invalidate(key: String) {
        withCArgs { c in CacheInvalidate(c.str(key)) }
    }

    /// Invalidates all cache entries for a server.
    public func invalidateServer(_ serverID: String) {
        withCArgs { c in CacheInvalidateServer(c.str(serverID)) }
    }

    /// Removes all expired entries. Returns count removed.
    @discardableResult
    public func cleanup() -> Int {
        return Int(CacheCleanup())
    }

    /// Clears the entire cache.
    public func clearAll() {
        CacheClearAll()
    }

    /// Returns the number of cache entries.
    public var count: Int {
        return Int(CacheCount())
    }
}
