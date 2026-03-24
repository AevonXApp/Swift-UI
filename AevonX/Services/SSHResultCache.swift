//
//  SSHResultCache.swift
//  AevonX
//
//  Generic TTL-based cache for SSH command results.
//  Prevents redundant SSH calls when switching tabs or refreshing data.
//

import Foundation

/// Thread-safe, TTL-based cache for SSH command results.
/// Use `shared` singleton or create domain-specific instances.
actor SSHResultCache {

    static let shared = SSHResultCache()

    // MARK: - Types

    private struct CacheEntry {
        let value: Any
        let expiresAt: Date
    }

    // MARK: - Storage

    private var entries: [String: CacheEntry] = [:]

    // MARK: - Default TTLs

    /// Default TTL for website list data.
    static let websiteListTTL: TimeInterval = 30

    /// Default TTL for database list data.
    static let databaseListTTL: TimeInterval = 30

    /// Default TTL for application discovery data.
    static let appDiscoveryTTL: TimeInterval = 300

    /// Default TTL for server paths (rarely changes).
    static let serverPathsTTL: TimeInterval = 600

    // MARK: - API

    /// Get a cached value, or nil if expired/missing.
    func get<T>(_ key: String) -> T? {
        guard let entry = entries[key] else { return nil }
        if Date() > entry.expiresAt {
            entries.removeValue(forKey: key)
            return nil
        }
        return entry.value as? T
    }

    /// Store a value with a TTL.
    func set(_ key: String, value: Any, ttl: TimeInterval) {
        entries[key] = CacheEntry(
            value: value,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }

    /// Remove a specific key (use after CRUD operations).
    func invalidate(_ key: String) {
        entries.removeValue(forKey: key)
    }

    /// Remove all entries matching a prefix (e.g. "websites:" for a server).
    func invalidatePrefix(_ prefix: String) {
        entries = entries.filter { !$0.key.hasPrefix(prefix) }
    }

    /// Remove all entries for a server.
    func invalidateServer(_ serverId: String) {
        invalidatePrefix("\(serverId):")
    }

    /// Clear all cached data.
    func clearAll() {
        entries.removeAll()
    }

    /// Check if a key exists and is not expired.
    func isFresh(_ key: String) -> Bool {
        guard let entry = entries[key] else { return false }
        return Date() <= entry.expiresAt
    }

    // MARK: - Convenience Keys

    /// Build a cache key for a server + domain combination.
    static func key(_ serverId: String, _ domain: String) -> String {
        "\(serverId):\(domain)"
    }
}
