//
//  SecureSettingsStore.swift
//  AevonX
//
//  Keychain-backed storage for security-critical settings.
//  Prevents attackers from disabling biometric auth or injecting proxy
//  settings via `defaults write` on UserDefaults plist.
//

import Foundation
import Security

final class SecureSettingsStore {

    static let shared = SecureSettingsStore()
    private let service = "com.aevonx.secure-settings"

    private init() {}

    // MARK: - Bool Settings

    func getBool(_ key: String, default defaultValue: Bool) -> Bool {
        guard let data = getData(key),
              let value = String(data: data, encoding: .utf8) else {
            return defaultValue
        }
        return value == "true"
    }

    func setBool(_ key: String, value: Bool) {
        setData(key, data: Data((value ? "true" : "false").utf8))
    }

    // MARK: - String Settings

    func getString(_ key: String, default defaultValue: String) -> String {
        guard let data = getData(key),
              let value = String(data: data, encoding: .utf8) else {
            return defaultValue
        }
        return value
    }

    func setString(_ key: String, value: String) {
        setData(key, data: Data(value.utf8))
    }

    // MARK: - Int Settings

    func getInt(_ key: String, default defaultValue: Int) -> Int {
        guard let data = getData(key),
              let str = String(data: data, encoding: .utf8),
              let value = Int(str) else {
            return defaultValue
        }
        return value
    }

    func setInt(_ key: String, value: Int) {
        setData(key, data: Data(String(value).utf8))
    }

    // MARK: - Keychain Operations

    private func getData(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }

    private func setData(_ key: String, data: Data) {
        // Delete existing entry
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new entry
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    // MARK: - Migration from UserDefaults

    /// Migrate security-critical settings from UserDefaults to Keychain.
    /// Only migrates if values exist in UserDefaults and not yet in Keychain.
    func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        let boolKeys = [
            "settings.security.requireAuthOnConnect",
            "settings.security.requireAuthOnEdit",
            "settings.security.requireAuthOnDelete",
            "settings.network.useProxy",
        ]

        for key in boolKeys {
            if defaults.object(forKey: key) != nil && getData(key) == nil {
                setBool(key, value: defaults.bool(forKey: key))
            }
        }

        let stringKeys = [
            "settings.network.proxyHost",
            "settings.network.proxyType",
        ]

        for key in stringKeys {
            if let val = defaults.string(forKey: key), getData(key) == nil {
                setString(key, value: val)
            }
        }

        let intKeys = [
            "settings.network.proxyPort",
        ]

        for key in intKeys {
            if defaults.object(forKey: key) != nil && getData(key) == nil {
                setInt(key, value: defaults.integer(forKey: key))
            }
        }
    }
}
