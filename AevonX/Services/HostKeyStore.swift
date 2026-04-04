//
//  HostKeyStore.swift
//  AevonX
//
//  Secure Keychain storage for SSH host key fingerprints.
//  Replaces UserDefaults storage to prevent MITM attacks via
//  planting fake host keys through defaults manipulation.
//

import Foundation
import Security

final class HostKeyStore {

    static let shared = HostKeyStore()
    private let servicePrefix = "com.aevonx.hostkeys."

    private init() {}

    // MARK: - Public API

    /// Save a host key fingerprint to Keychain.
    func save(hostPort: String, fingerprint: String) {
        let key = servicePrefix + hostPort
        let data = Data(fingerprint.utf8)

        // Delete existing entry first (update = delete + add)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            // Non-fatal — log but don't crash
        }
    }

    /// Get a host key fingerprint from Keychain.
    func get(hostPort: String) -> String? {
        let key = servicePrefix + hostPort

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let fingerprint = String(data: data, encoding: .utf8) else {
            return nil
        }

        return fingerprint
    }

    /// Remove a host key fingerprint from Keychain.
    func remove(hostPort: String) {
        let key = servicePrefix + hostPort
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Migration

    /// Migrate host keys from UserDefaults to Keychain (one-time).
    /// Removes from UserDefaults after successful migration.
    func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        for key in allKeys where key.hasPrefix("hostkey:") {
            guard let fingerprint = defaults.string(forKey: key) else { continue }
            let hostPort = String(key.dropFirst("hostkey:".count))

            // Only migrate if not already in Keychain
            if get(hostPort: hostPort) == nil {
                save(hostPort: hostPort, fingerprint: fingerprint)
            }

            // Remove from UserDefaults (no longer needed)
            defaults.removeObject(forKey: key)
        }
    }
}
