//
//  CacheManager.swift
//  AevonXCore
//
//  Generic caching layer with TTL support for reducing SSH command overhead.
//  Supports different cache categories with configurable expiration.
//

import Foundation

// MARK: - Cache Entry

/// A cache entry with value, creation time, and TTL.
private struct CacheEntry<T: Sendable>: Sendable {
    let value: T
    let createdAt: Date
    let ttl: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince(createdAt) > ttl
    }
}

// MARK: - Cache Category

/// Predefined cache categories with default TTLs.
public enum CacheCategory: Sendable {
    /// Static data that rarely changes (OS info, installed software, paths).
    /// Default TTL: 24 hours.
    case `static`
    
    /// Semi-static data (service status, versions, configuration).
    /// Default TTL: 5 minutes.
    case semiStatic
    
    /// Dynamic data (CPU/memory/disk usage, connections).
    /// Default TTL: 30 seconds.
    case dynamic
    
    /// Custom TTL in seconds.
    case custom(TimeInterval)
    
    /// The TTL in seconds for this category.
    public var ttl: TimeInterval {
        switch self {
        case .static:             return 86400   // 24 hours
        case .semiStatic:         return 300     // 5 minutes
        case .dynamic:            return 30      // 30 seconds
        case .custom(let ttl):    return ttl
        }
    }
}

// MARK: - Cache Manager

/// Thread-safe, generic caching layer for server data.
///
/// Supports per-server and per-key caching with automatic TTL-based expiration.
/// All remote queries should go through this cache to minimize SSH round-trips.
///
/// **Usage**:
/// ```swift
/// let cache = CacheManager.shared
///
/// // Store a value
/// await cache.set("server-1:cpu", value: 45.2, category: .dynamic)
///
/// // Retrieve a value
/// let cpu: Double? = await cache.get("server-1:cpu")
///
/// // Invalidate all data for a server
/// await cache.invalidateAll(forServer: "server-1")
/// ```
public actor CacheManager {
    
    // MARK: - Singleton
    
    public static let shared = CacheManager()
    
    // MARK: - Storage
    
    /// Type-erased cache storage
    private var storage: [String: AnyCacheEntry] = [:]
    
    /// Tracks which keys belong to which server for bulk invalidation
    private var serverKeys: [String: Set<String>] = [:]
    
    /// Total number of cache entries
    public var count: Int { storage.count }
    
    // MARK: - Type Erasure
    
    /// Type-erased wrapper for CacheEntry
    private struct AnyCacheEntry: Sendable {
        let createdAt: Date
        let ttl: TimeInterval
        private let _getValue: @Sendable () -> any Sendable
        
        init<T: Sendable>(_ entry: CacheEntry<T>) {
            self.createdAt = entry.createdAt
            self.ttl = entry.ttl
            self._getValue = { entry.value }
        }
        
        var isExpired: Bool {
            return Date().timeIntervalSince(createdAt) > ttl
        }
        
        func value<T: Sendable>(as type: T.Type) -> T? {
            return _getValue() as? T
        }
    }
    
    // MARK: - Public API
    
    /// Store a value in the cache.
    ///
    /// - Parameters:
    ///   - key: Cache key (recommended format: "serverId:category:identifier")
    ///   - value: The value to cache
    ///   - category: Cache category determining TTL
    ///   - serverId: Optional server ID for bulk invalidation support
    public func set<T: Sendable>(_ key: String, value: T, category: CacheCategory, serverId: String? = nil) {
        let entry = CacheEntry(value: value, createdAt: Date(), ttl: category.ttl)
        storage[key] = AnyCacheEntry(entry)
        
        if let serverId = serverId {
            serverKeys[serverId, default: []].insert(key)
        }
    }
    
    /// Retrieve a value from the cache.
    ///
    /// Returns nil if the key doesn't exist or the entry has expired.
    ///
    /// - Parameter key: Cache key
    /// - Returns: The cached value, or nil
    public func get<T: Sendable>(_ key: String) -> T? {
        guard let entry = storage[key] else { return nil }
        
        if entry.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }
        
        return entry.value(as: T.self)
    }
    
    /// Check if a non-expired entry exists for the given key.
    public func has(_ key: String) -> Bool {
        guard let entry = storage[key] else { return false }
        if entry.isExpired {
            storage.removeValue(forKey: key)
            return false
        }
        return true
    }
    
    /// Invalidate a specific cache entry.
    public func invalidate(_ key: String) {
        storage.removeValue(forKey: key)
    }
    
    /// Invalidate all cache entries for a specific server.
    public func invalidateAll(forServer serverId: String) {
        if let keys = serverKeys[serverId] {
            for key in keys {
                storage.removeValue(forKey: key)
            }
            serverKeys.removeValue(forKey: serverId)
        }
    }
    
    /// Invalidate all entries in a specific category for a server.
    public func invalidateCategory(_ prefix: String, forServer serverId: String) {
        let fullPrefix = "\(serverId):\(prefix)"
        let keysToRemove = storage.keys.filter { $0.hasPrefix(fullPrefix) }
        for key in keysToRemove {
            storage.removeValue(forKey: key)
            serverKeys[serverId]?.remove(key)
        }
    }
    
    /// Remove all expired entries.
    public func cleanup() {
        let expiredKeys = storage.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            storage.removeValue(forKey: key)
        }
    }
    
    /// Clear the entire cache.
    public func clearAll() {
        storage.removeAll()
        serverKeys.removeAll()
    }
    
    // MARK: - Convenience
    
    /// Get or compute a cached value. If the cache misses, the compute closure
    /// is called, and the result is stored before being returned.
    ///
    /// - Parameters:
    ///   - key: Cache key
    ///   - category: Cache category for TTL
    ///   - serverId: Optional server ID
    ///   - compute: Closure to compute the value if not cached
    /// - Returns: The cached or computed value
    public func getOrCompute<T: Sendable>(
        _ key: String,
        category: CacheCategory,
        serverId: String? = nil,
        compute: () async throws -> T
    ) async rethrows -> T {
        if let cached: T = get(key) {
            return cached
        }
        
        let value = try await compute()
        set(key, value: value, category: category, serverId: serverId)
        return value
    }
    
    // MARK: - Disk Persistence (M5)
    
    /// Directory for disk-cached entries
    private static var diskCacheDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("AevonXCache", isDirectory: true)
    }
    
    /// Persist a value to disk (for static/semi-static entries).
    /// Values are stored as JSON files keyed by a sanitized filename.
    private func writeToDisk(_ key: String, data: Data) {
        guard let dir = Self.diskCacheDirectory else { return }
        
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let fileURL = dir.appendingPathComponent(diskKey(key))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            CoreLogger.shared.debug("Disk cache write failed for \(key): \(error.localizedDescription)", module: "Cache")
        }
    }
    
    /// Read a value from disk cache.
    private func readFromDisk(_ key: String) -> Data? {
        guard let dir = Self.diskCacheDirectory else { return nil }
        let fileURL = dir.appendingPathComponent(diskKey(key))
        return try? Data(contentsOf: fileURL)
    }
    
    /// Sanitize a cache key into a safe filename.
    private func diskKey(_ key: String) -> String {
        let safe = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return "\(safe).cache"
    }
    
    /// Persist all static and semi-static entries to disk.
    /// Call this when the app enters background to preserve long-lived cache.
    public func persistToDisk() {
        guard Self.diskCacheDirectory != nil else { return }
        
        for (key, entry) in storage {
            // Only persist entries with TTL >= 5 minutes (semi-static or static)
            guard entry.ttl >= 300 else { continue }
            
            // Store as simple JSON: { "value": <string>, "ttl": <seconds>, "created": <timestamp> }
            let metadata: [String: Any] = [
                "value": String(describing: entry.value(as: Any.self) ?? ""),
                "ttl": entry.ttl,
                "created": entry.createdAt.timeIntervalSince1970
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: metadata) {
                writeToDisk(key, data: data)
            }
        }
        
        CoreLogger.shared.debug("Persisted \(storage.count) cache entries to disk", module: "Cache")
    }
    
    /// Clear the disk cache directory.
    public func clearDiskCache() {
        guard let dir = Self.diskCacheDirectory else { return }
        try? FileManager.default.removeItem(at: dir)
        CoreLogger.shared.debug("Disk cache cleared", module: "Cache")
    }
}
