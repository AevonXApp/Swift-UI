//
//  EncryptionKeyStore.swift
//  AevonXCoreBridge
//
//  Stores the encryption key securely in the macOS Keychain.
//  Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly for device-bound protection.
//
//  Migration: On first launch after update, automatically migrates any existing
//  file-based key (.encryption_key) to Keychain and removes the plaintext file.
//
//  Biometric (Touch ID / Face ID) is handled separately via LAContext when needed
//  (only for viewing backup key in EncryptionKeyDisplayView).
//

import Foundation
import Security
import LocalAuthentication
import CryptoKit

// MARK: - Errors

public enum EncryptionKeyStoreError: Error, LocalizedError {
    case saveFailed(String)
    case readFailed(String)
    case biometricAuthFailed
    case biometricNotAvailable
    case keyNotFound
    case invalidKeyFormat
    case keychainError(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return "Failed to save key: \(reason)"
        case .readFailed(let reason):
            return "Failed to read key: \(reason)"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .keyNotFound:
            return "Encryption key not found. Please enter your encryption key."
        case .invalidKeyFormat:
            return "Invalid encryption key format"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - EncryptionKeyStore

/// Stores the user's encryption key securely in the macOS Keychain.
///
/// Security model:
///   - Key stored in Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
///   - Key is device-bound — cannot be extracted via iCloud Keychain backup
///   - Transparent migration from legacy file-based storage on first access
///   - Biometric available separately via authenticateWithBiometric() for backup viewing
public actor EncryptionKeyStore {
    
    public static let shared = EncryptionKeyStore()
    
    // MARK: - Keychain Constants
    
    private let keychainService = "app.aevonx.encryption"
    private let keychainAccount = "master-encryption-key"
    
    // MARK: - Legacy File Path (for migration only)
    
    nonisolated private var legacyKeyFilePath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let aevonDir = appSupport.appendingPathComponent("AevonX", isDirectory: true)
        return aevonDir.appendingPathComponent(".encryption_key")
    }
    
    // MARK: - In-Memory Cache
    
    private var cachedKey: String?
    private var migrationAttempted: Bool = false
    
    private init() {
        CoreLogger.shared.info("EncryptionKeyStore initialized (Keychain-backed)", module: "Encryption")
    }
    
    // MARK: - Key Generation
    
    /// Generates a new encryption key with 256-bit entropy
    public func generateKey() -> String {
        var randomBytes = [UInt8](repeating: 0, count: 32) // 256-bit entropy
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        let hex = randomBytes.map { String(format: "%02X", $0) }.joined()
        let formatted = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(8))-\(hex.dropFirst(16).prefix(8))-\(hex.dropFirst(24).prefix(8))"
        
        CoreLogger.shared.info("Generated new encryption key (\(formatted.count) chars, 256-bit)", module: "Encryption")
        return formatted
    }
    
    // MARK: - Save Key (Keychain)
    
    /// Saves the encryption key to the Keychain
    public func saveKey(_ key: String) async throws {
        CoreLogger.shared.info("Saving encryption key to Keychain", module: "Encryption")
        
        guard let keyData = key.data(using: .utf8) else {
            throw EncryptionKeyStoreError.invalidKeyFormat
        }
        
        // Delete any existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrLabel as String: "AevonX Encryption Key",
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            CoreLogger.shared.error("Failed to save key to Keychain: \(status)", module: "Encryption")
            throw EncryptionKeyStoreError.keychainError(status)
        }
        
        cachedKey = key
        CoreLogger.shared.info("✅ Encryption key saved to Keychain", module: "Encryption")
    }
    
    // MARK: - Get Key (Keychain + Legacy Migration)
    
    /// Retrieves the encryption key from Keychain (with automatic legacy file migration)
    public func getKey() async throws -> String {
        // Return cached key if available
        if let cached = cachedKey {
            return cached
        }
        
        // Try Keychain first
        if let keychainKey = readFromKeychain() {
            cachedKey = keychainKey
            return keychainKey
        }
        
        // Attempt legacy file migration (only once)
        if !migrationAttempted {
            migrationAttempted = true
            if let migratedKey = try? await migrateFromFileToKeychain() {
                cachedKey = migratedKey
                return migratedKey
            }
        }
        
        CoreLogger.shared.warning("Key not found in Keychain or legacy file", module: "Encryption")
        throw EncryptionKeyStoreError.keyNotFound
    }
    
    // MARK: - Has Key
    
    /// Checks whether an encryption key exists in Keychain or legacy file
    nonisolated public func hasKey() -> Bool {
        // Check Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            CoreLogger.shared.debug("hasKey() → true (Keychain)", module: "Encryption")
            return true
        }
        
        // Fallback: check legacy file (pre-migration)
        let legacyExists = FileManager.default.fileExists(atPath: legacyKeyFilePath.path)
        CoreLogger.shared.debug("hasKey() → \(legacyExists) (legacy file)", module: "Encryption")
        return legacyExists
    }
    
    // MARK: - Keychain Operations (Private)
    
    /// Reads the key directly from Keychain
    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8), !key.isEmpty else {
            return nil
        }
        
        CoreLogger.shared.info("✅ Encryption key loaded from Keychain", module: "Encryption")
        return key
    }
    
    // MARK: - Legacy File Migration
    
    /// Migrates encryption key from legacy plaintext file to Keychain
    /// Returns the migrated key on success, nil if no file exists
    private func migrateFromFileToKeychain() async throws -> String? {
        let filePath = legacyKeyFilePath
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        CoreLogger.shared.info("🔄 Migrating encryption key from file to Keychain...", module: "Encryption")
        
        // Read from legacy file
        let data = try Data(contentsOf: filePath)
        guard let key = String(data: data, encoding: .utf8), !key.isEmpty else {
            CoreLogger.shared.error("Legacy key file is empty or invalid", module: "Encryption")
            return nil
        }
        
        // Save to Keychain
        try await saveKey(key)
        
        // Securely delete the legacy file (overwrite with random data first)
        if let randomData = try? Data((0..<data.count).map { _ in UInt8.random(in: 0...255) }) {
            try? randomData.write(to: filePath, options: .atomic)
        }
        try? FileManager.default.removeItem(at: filePath)
        
        CoreLogger.shared.info("✅ Migration complete: key moved to Keychain, legacy file removed", module: "Encryption")
        return key
    }
    
    // MARK: - Biometric Authentication (Standalone)
    
    /// Authenticates the user with Touch ID / Face ID using NATIVE Apple UI.
    /// Used ONLY for viewing backup key — NOT for key storage/retrieval.
    public func authenticateWithBiometric() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            CoreLogger.shared.warning("Biometric not available: \(error?.localizedDescription ?? "unknown")", module: "Encryption")
            throw EncryptionKeyStoreError.biometricNotAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verify your identity to view your encryption key"
            )
            guard success else {
                throw EncryptionKeyStoreError.biometricAuthFailed
            }
            CoreLogger.shared.info("✅ Biometric authentication succeeded", module: "Encryption")
        } catch {
            CoreLogger.shared.warning("Biometric failed: \(error.localizedDescription)", module: "Encryption")
            throw EncryptionKeyStoreError.biometricAuthFailed
        }
    }
    
    // MARK: - State
    
    /// Thread-safe check using Keychain + legacy file existence
    nonisolated public var isUnlocked: Bool {
        hasKey()
    }
    
    // MARK: - Delete & Lock
    
    /// Deletes the encryption key from Keychain and clears cache
    public func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
        
        // Also remove legacy file if it still exists
        try? FileManager.default.removeItem(at: legacyKeyFilePath)
        
        cachedKey = nil
        CoreLogger.shared.info("Encryption key deleted from Keychain", module: "Encryption")
    }
    
    /// Clears cached key from memory
    public func lock() {
        cachedKey = nil
        CoreLogger.shared.info("Encryption key locked (cache cleared)", module: "Encryption")
    }
    
    // MARK: - Hashing
    
    /// SHA-256 hash for server-side verification (server NEVER sees the key itself)
    public func hashKey(_ key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
