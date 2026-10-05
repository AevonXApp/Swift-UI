//
//  DeviceKeyBridge.swift
//  AevonXCoreBridge
//
//  Manages per-device Ed25519 public keys lifecycle:
//  1. Fetches device keys from backend via ECDH secure channel
//  2. Loads them into Go Core's key store (for token verification)
//  3. Caches in Keychain (survives app restart)
//  4. Auto-refreshes when keys are close to rotation
//

import Foundation
import Security
import AevonXCoreLib

/// Manages per-device Ed25519 key delivery and caching.
public actor DeviceKeyManager {

    public static let shared = DeviceKeyManager()

    // MARK: - Properties

    /// Injectable API fetcher for secure channel requests.
    /// Takes (endpoint, deviceFingerprint) → JSON response string.
    public var apiFetcher: (@Sendable (String, String) async -> String)?

    /// Current device fingerprint (set during login).
    private var deviceFingerprint: String?

    /// Last time keys were fetched from backend.
    private var lastFetch: Date?

    /// Cache validity: 1 hour (keys rotate every 7 days, so hourly refresh is plenty).
    private let cacheValidity: TimeInterval = 3600

    private init() {}

    // MARK: - Configuration

    /// Set the API fetcher from the app layer.
    public func setApiFetcher(_ fetcher: @escaping @Sendable (String, String) async -> String) {
        self.apiFetcher = fetcher
    }

    /// Set the current device fingerprint (called during login).
    public func setDeviceFingerprint(_ fp: String) {
        self.deviceFingerprint = fp
    }

    // MARK: - Key Fetching

    /// Fetches device keys from backend and loads into Go Core.
    /// Called after login and periodically to pick up rotated keys.
    ///
    /// - Parameter forceRefresh: If true, ignores cache and fetches fresh.
    /// - Returns: Number of keys loaded into Go Core.
    @discardableResult
    public func fetchAndLoadKeys(forceRefresh: Bool = false) async -> Int {
        guard let deviceFP = deviceFingerprint else {
            return 0
        }

        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidity {
            return cachedKeyCount()
        }

        guard let fetcher = apiFetcher else {
            return 0
        }

        // Fetch keys via ECDH secure channel
        let responseJSON = await fetcher("/api/v1/device-keys", deviceFP)

        guard !responseJSON.isEmpty,
              let rawData = responseJSON.data(using: .utf8),
              let wrapper = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              wrapper["success"] as? Bool == true,
              let innerData = wrapper["data"] as? [String: Any],
              let keysArray = innerData["keys"] as? [[String: Any]] else {
            return 0
        }

        // Convert to JSON string for Go Core
        guard let keysData = try? JSONSerialization.data(withJSONObject: keysArray),
              let keysString = String(data: keysData, encoding: .utf8) else {
            return 0
        }

        // Load into Go Core key store
        let loaded = loadKeysIntoCore(keysJSON: keysString)

        if loaded > 0 {
            lastFetch = Date()

            // Also cache in Keychain for offline/restart
            cacheKeysToKeychain(keysJSON: keysString)
        }

        return loaded
    }

    /// Loads keys from Keychain cache into Go Core.
    /// Called on app launch before the first API call completes.
    /// Cached keys may be stale — backend rotates every 7 days with a 24h overlap,
    /// so we mark `lastFetch` as already past the cache window. The next
    /// `fetchAndLoadKeys` call will hit the API and pick up any rotated kids.
    /// A small grace period prevents back-to-back fetches during launch.
    public func loadCachedKeys() -> Int {
        guard let keysJSON = loadKeysFromKeychain() else {
            return 0
        }
        let count = loadKeysIntoCore(keysJSON: keysJSON)
        if count > 0 {
            lastFetch = Date().addingTimeInterval(-cacheValidity + 30)
        }
        return count
    }

    /// Clears all device keys from Go Core and Keychain.
    /// Called on logout or device revocation.
    public func clearKeys() {
        AevonXCoreLib.CoreClearDeviceKeys()
        removeKeysFromKeychain()
        lastFetch = nil
    }

    /// Returns the number of keys currently loaded in Go Core.
    public func keyCount() -> Int {
        cachedKeyCount()
    }

    // MARK: - Go Core Interface

    private func cachedKeyCount() -> Int {
        Int(AevonXCoreLib.CoreDeviceKeyCount())
    }

    private func loadKeysIntoCore(keysJSON: String) -> Int {
        var count: Int32 = 0
        keysJSON.withMutableCString { cStr in
            let result = AevonXCoreLib.CoreLoadDeviceKeys(cStr)
            defer { CoreFreeString(result) }
            if let result = result {
                let json = String(cString: result)
                if let data = json.data(using: .utf8),
                   let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let loaded = resp["loaded"] as? Int {
                    count = Int32(loaded)
                }
            }
        }
        return Int(count)
    }

    // MARK: - Keychain Cache

    private let keychainService = "app.aevonx.device-keys"
    private let keychainAccount = "per-device-public-keys"

    private func cacheKeysToKeychain(keysJSON: String) {
        guard let data = keysJSON.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadKeysFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }

    private func removeKeysFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
