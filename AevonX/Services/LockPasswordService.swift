//
//  LockPasswordService.swift
//  AevonX
//
//  Manages the app lock password — stores a SHA-256 hash in the macOS Keychain
//

import Foundation
import Security
import CryptoKit

actor LockPasswordService {
    static let shared = LockPasswordService()

    private let service = "app.aevonx.lockPassword"
    private let account = "appLockHash"

    private init() {}

    // MARK: - Public API

    /// Returns true if a lock password has been set
    func hasPassword() -> Bool {
        return readHash() != nil
    }

    /// Sets a new lock password (stores SHA-256 hash, never plaintext)
    func setPassword(_ password: String) throws {
        let hash = hashPassword(password)
        try storeHash(hash)
    }

    /// Verifies a password against the stored hash
    func verify(_ password: String) -> Bool {
        guard let stored = readHash() else { return false }
        return hashPassword(password) == stored
    }

    /// Removes the stored password
    func removePassword() {
        deleteHash()
    }

    // MARK: - Hashing

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain

    private func storeHash(_ hash: String) throws {
        deleteHash() // Remove existing before writing

        let data = Data(hash.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "LockPasswordService", code: Int(status),
                          userInfo: [NSLocalizedDescriptionKey: "Failed to save password"])
        }
    }

    private func readHash() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteHash() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
