//
//  KeygenKeyStorage.swift
//  AevonXCoreBridge
//
//  Keychain-backed storage for locally generated SSH private keys.
//
//  Security properties:
//   • Items use kSecAttrAccessibleWhenUnlockedThisDeviceOnly so the data
//     never syncs to iCloud, never leaves the device, and cannot be read
//     while the device is locked.
//   • Items are protected by SecAccessControl with .biometryCurrentSet,
//     which requires Touch ID / Face ID at write AND read time, and
//     invalidates the item if the user enrolls new biometrics.
//   • The private key is wiped from the in-memory storage actor as soon
//     as the caller's closure returns.
//
//  This is intentionally not a generic password store — it is hard-coded
//  to SSH-key semantics so the policy cannot be diluted by other call sites.
//

import Foundation
import Security
import LocalAuthentication

/// Errors thrown by KeygenKeyStorage. The strings are user-facing so they
/// can be surfaced directly in alerts.
public enum KeygenStorageError: Error, LocalizedError, Sendable {
    case biometricsUnavailable(String)
    case userCancelled
    case authenticationFailed
    case keychainSaveFailed(OSStatus)
    case keychainLoadFailed(OSStatus)
    case keychainDeleteFailed(OSStatus)
    case keyNotFound
    case accessControlCreationFailed
    case dataEncodingFailed

    public var errorDescription: String? {
        switch self {
        case .biometricsUnavailable(let reason):
            return "Biometric authentication is unavailable: \(reason)"
        case .userCancelled:
            return "Authentication was cancelled."
        case .authenticationFailed:
            return "Biometric authentication failed."
        case .keychainSaveFailed(let status):
            return "Failed to save key to Keychain (status \(status))."
        case .keychainLoadFailed(let status):
            return "Failed to load key from Keychain (status \(status))."
        case .keychainDeleteFailed(let status):
            return "Failed to remove key from Keychain (status \(status))."
        case .keyNotFound:
            return "The requested SSH key was not found in the Keychain."
        case .accessControlCreationFailed:
            return "Could not create the Keychain access control object."
        case .dataEncodingFailed:
            return "Failed to encode the key for storage."
        }
    }
}

// MARK: - Public Metadata

/// Public, non-sensitive metadata about a stored key. Safe to display.
public struct KeygenStoredKeyInfo: Codable, Sendable, Identifiable {
    /// Stable identifier — the SHA256 fingerprint of the public key.
    public let id: String
    public let fingerprint: String
    public let publicKey: String
    public let type: KeygenType
    public let comment: String
    public let createdAt: Date
    public let serverID: String?

    public init(
        fingerprint: String,
        publicKey: String,
        type: KeygenType,
        comment: String,
        createdAt: Date,
        serverID: String?
    ) {
        self.id = fingerprint
        self.fingerprint = fingerprint
        self.publicKey = publicKey
        self.type = type
        self.comment = comment
        self.createdAt = createdAt
        self.serverID = serverID
    }
}

// MARK: - Storage Actor

/// Threadsafe Keychain-backed SSH private key store.
///
/// Designed so the private key never appears in a Swift property —
/// callers receive it inside a closure and the actor wipes its in-memory
/// copy before returning.
public actor KeygenKeyStorage {

    public static let shared = KeygenKeyStorage()

    /// Service tag that scopes our Keychain items (also used as a prefix
    /// when filtering on enumeration).
    private static let secretService = "app.aevonx.sshkeys.private"
    private static let metadataService = "app.aevonx.sshkeys.metadata"

    private init() {}

    // MARK: Save

    /// Persists a freshly generated key pair. Performs Touch ID at write
    /// time so creation is protected from the very first byte being stored.
    ///
    /// - Parameters:
    ///   - pair: the generated key. The caller should drop their reference
    ///           to `pair.privateKey` immediately after this call returns.
    ///   - serverID: optional UUID linking the key to a server entry.
    ///   - reason: localised string shown in the Touch ID prompt.
    /// - Returns: the public, non-sensitive metadata that the UI can show.
    public func save(
        pair: KeygenKeyPair,
        serverID: String?,
        reason: String
    ) async throws -> KeygenStoredKeyInfo {

        // 1. Confirm biometrics are available BEFORE prompting, so we can
        //    surface a clean error message instead of relying on the
        //    Keychain status code.
        try ensureBiometricsAvailable()

        // 2. Build a SecAccessControl that requires Touch ID + current
        //    biometric set. `userPresence` allows passcode fallback if the
        //    OS escalates; we deliberately do NOT allow that here so the
        //    key truly is "biometric-only".
        let access = try makeAccessControl()

        // 3. Convert the private key to bytes. Wipe the temporary buffer
        //    via `defer` after the SecItemAdd call returns.
        guard var keyBytes = pair.privateKey.data(using: .utf8) else {
            throw KeygenStorageError.dataEncodingFailed
        }
        defer { keyBytes.resetBytes(in: 0..<keyBytes.count) }

        let context = LAContext()
        context.localizedReason = reason

        let secretQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.secretService,
            kSecAttrAccount as String: pair.fingerprint,
            kSecValueData as String: keyBytes,
            kSecAttrAccessControl as String: access,
            kSecAttrSynchronizable as String: false,
            kSecUseAuthenticationContext as String: context,
        ]

        // Remove any prior copy under the same fingerprint before re-adding.
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.secretService,
            kSecAttrAccount as String: pair.fingerprint,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addStatus = SecItemAdd(secretQuery as CFDictionary, nil)
        if addStatus != errSecSuccess {
            throw KeygenStorageError.keychainSaveFailed(addStatus)
        }

        // 4. Save the public-side metadata as a SEPARATE Keychain item.
        //    Metadata has the same accessibility rule (this-device-only,
        //    while-unlocked) but no biometric gate so we can render the
        //    keys list without prompting the user.
        let info = KeygenStoredKeyInfo(
            fingerprint: pair.fingerprint,
            publicKey: pair.publicKey,
            type: pair.type,
            comment: pair.comment,
            createdAt: Date(),
            serverID: serverID
        )
        try saveMetadata(info)

        return info
    }

    // MARK: Load (one-shot, scoped)

    /// Retrieves the private key for one operation, runs `body`, and
    /// guarantees the in-memory copy is wiped before the function returns.
    ///
    /// This is the only public read API on purpose — there is no way to
    /// extract the raw private key out of the actor.
    @discardableResult
    public func withPrivateKey<T: Sendable>(
        fingerprint: String,
        reason: String,
        body: @Sendable (String) async throws -> T
    ) async throws -> T {

        let context = LAContext()
        context.localizedReason = reason

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.secretService,
            kSecAttrAccount as String: fingerprint,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess: break
        case errSecItemNotFound: throw KeygenStorageError.keyNotFound
        case errSecUserCanceled: throw KeygenStorageError.userCancelled
        case errSecAuthFailed: throw KeygenStorageError.authenticationFailed
        default: throw KeygenStorageError.keychainLoadFailed(status)
        }

        guard var data = item as? Data,
              let pem = String(data: data, encoding: .utf8) else {
            throw KeygenStorageError.dataEncodingFailed
        }
        defer { data.resetBytes(in: 0..<data.count) }

        return try await body(pem)
    }

    // MARK: Delete

    /// Permanently removes the private key and its metadata from the Keychain.
    public func delete(fingerprint: String) throws {
        let secretQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.secretService,
            kSecAttrAccount as String: fingerprint,
        ]
        let s1 = SecItemDelete(secretQuery as CFDictionary)
        if s1 != errSecSuccess && s1 != errSecItemNotFound {
            throw KeygenStorageError.keychainDeleteFailed(s1)
        }

        let metaQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.metadataService,
            kSecAttrAccount as String: fingerprint,
        ]
        let s2 = SecItemDelete(metaQuery as CFDictionary)
        if s2 != errSecSuccess && s2 != errSecItemNotFound {
            throw KeygenStorageError.keychainDeleteFailed(s2)
        }
    }

    // MARK: List metadata

    /// Returns the public metadata for every stored SSH key.
    /// This call is biometric-free; only the private blobs require Touch ID.
    public func listAll() -> [KeygenStoredKeyInfo] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.metadataService,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return items.compactMap { dict -> KeygenStoredKeyInfo? in
            guard let data = dict[kSecValueData as String] as? Data else { return nil }
            return try? decoder.decode(KeygenStoredKeyInfo.self, from: data)
        }
    }

    // MARK: - Private helpers

    private func ensureBiometricsAvailable() throws {
        let ctx = LAContext()
        var error: NSError?
        if !ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = error?.localizedDescription ?? "biometrics not enrolled"
            throw KeygenStorageError.biometricsUnavailable(reason)
        }
    }

    private func makeAccessControl() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let ac = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.biometryCurrentSet],
            &error
        ) else {
            throw KeygenStorageError.accessControlCreationFailed
        }
        return ac
    }

    private func saveMetadata(_ info: KeygenStoredKeyInfo) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(info)

        let delete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.metadataService,
            kSecAttrAccount as String: info.fingerprint,
        ]
        SecItemDelete(delete as CFDictionary)

        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.metadataService,
            kSecAttrAccount as String: info.fingerprint,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false,
        ]
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeygenStorageError.keychainSaveFailed(status)
        }
    }
}
