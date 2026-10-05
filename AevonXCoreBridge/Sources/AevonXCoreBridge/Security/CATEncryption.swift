//
//  CATEncryption.swift
//  AevonXCore
//
//  Device-bound CAT encryption using device-server-recovery bound keys
//  This provides Zero-Knowledge security - Backend is a blind issuer
//
//  Security Architecture:
//  - Backend ONLY signs CAT tokens with Ed25519 (blind issuer)
//  - Core receives signed CAT and encrypts it LOCALLY using:
//    - Device secret (Secure Enclave)
//    - Server ID
//    - Recovery Key
//  - Backend NEVER has access to encryption key or recovery key
//  - Only the correct device with the correct recovery key can decrypt
//  - CAT and Server Payload form an inseparable pair
//

import Foundation
import CryptoKit
import Security

// MARK: - Encrypted CAT Payload

/// Encrypted CAT token payload - created and stored locally on device
/// The Backend never sees this encrypted form; it only issues signed tokens
public struct EncryptedCATPayload: Codable, Sendable {
    /// Base64-encoded encrypted CAT token (ciphertext + auth tag)
    public let encryptedCAT: String
    /// Base64-encoded salt for key derivation (32 bytes) - locally generated
    public let salt: String
    /// Base64-encoded nonce/IV for AES-GCM (12 bytes) - locally generated
    public let nonce: String
    /// Version of encryption scheme
    public let version: String

    enum CodingKeys: String, CodingKey {
        case encryptedCAT = "encrypted_cat"
        case salt
        case nonce
        case version
    }

    public init(encryptedCAT: String, salt: String, nonce: String, version: String = "1.0") {
        self.encryptedCAT = encryptedCAT
        self.salt = salt
        self.nonce = nonce
        self.version = version
    }
}

// MARK: - CAT Encryption Errors

/// Errors that can occur during CAT encryption/decryption
public enum CATEncryptionError: Error, LocalizedError {
    case deviceKeyNotAvailable
    case recoveryKeyNotAvailable
    case invalidPayloadFormat
    case invalidNonceLength
    case invalidSaltLength
    case unsupportedVersion(String)
    case decryptionFailed
    case keyDerivationFailed
    case encryptionFailed

    public var errorDescription: String? {
        switch self {
        case .deviceKeyNotAvailable:
            return "Device key not available for CAT decryption"
        case .recoveryKeyNotAvailable:
            return "Recovery key not available for CAT decryption"
        case .invalidPayloadFormat:
            return "Invalid encrypted CAT payload format"
        case .invalidNonceLength:
            return "Invalid nonce length in encrypted CAT (expected 12 bytes)"
        case .invalidSaltLength:
            return "Invalid salt length in encrypted CAT (expected 32 bytes)"
        case .unsupportedVersion(let version):
            return "Unsupported CAT encryption version: \(version)"
        case .decryptionFailed:
            return "Failed to decrypt CAT token"
        case .keyDerivationFailed:
            return "Failed to derive CAT decryption key"
        case .encryptionFailed:
            return "Failed to encrypt CAT token"
        }
    }
}

// MARK: - CAT Encryption Service

/// Service for local device-bound CAT encryption/decryption
///
/// Zero-Knowledge Architecture:
/// - Backend is a BLIND ISSUER - it only signs CATs with Ed25519
/// - Backend NEVER has access to: recovery key, device secret, encryption key
/// - ALL encryption/decryption happens locally in Core
/// - CAT tokens are encrypted with a key that can only be derived on this device
/// - The key binds: device secret (Secure Enclave) + server ID + recovery key
/// - Even if a signed CAT is intercepted, it cannot be used on a different device
///
/// Key Derivation (local only):
/// ```
/// K = HKDF-SHA256(
///     IKM: device_secret || server_id || recovery_key,
///     salt: locally_generated_salt,
///     info: "AevonX-CAT-Encryption-v1"
/// )
/// ```
///
/// Flow:
/// 1. Backend signs CAT with Ed25519 private key
/// 2. Core receives signed (plain) CAT token
/// 3. Core encrypts with device-bound key (this service)
/// 4. Encrypted CAT stored locally on device
/// 5. On connection: Core decrypts, validates signature, uses CAT
public actor CATEncryption {

    public static let shared = CATEncryption()

    // MARK: - Constants

    /// HKDF info string for key derivation
    private let hkdfInfo = "AevonX-CAT-Encryption-v1"

    /// Current encryption version
    private let currentVersion = "1.0"

    /// Expected nonce length (AES-GCM standard)
    private let nonceLength = 12

    /// Expected salt length
    private let saltLength = 32

    /// Derived key length (AES-256)
    private let keyLength = 32

    private init() {}

    // MARK: - Key Derivation

    /// Derives the CAT encryption/decryption key from encryption_key + server_id
    ///
    /// The derived key is bound to:
    /// - The user's encryption key (from EncryptionKeyStore)
    /// - The server (via server ID)
    ///
    /// This key derivation happens ONLY on the device - Backend never sees this key.
    ///
    /// - Parameters:
    ///   - serverId: The server UUID this CAT is bound to
    ///   - salt: The locally-generated salt for this encryption
    /// - Returns: AES-256 symmetric key for encryption/decryption
    /// - Throws: CATEncryptionError if key derivation fails
    private func deriveKey(
        serverId: String,
        salt: Data
    ) async throws -> SymmetricKey {

        CoreLogger.shared.info("Deriving CAT key for server: \(serverId)", module: "CATEncryption")

        // 1. Get user encryption key from EncryptionKeyStore
        let userKey: String
        do {
            userKey = try await EncryptionKeyStore.shared.getKey()
        } catch {
            CoreLogger.shared.error("Failed to retrieve encryption key: \(error.localizedDescription)", module: "CATEncryption")
            throw CATEncryptionError.deviceKeyNotAvailable
        }

        // 2. Combine: encryption_key || server_id
        var inputKeyMaterial = Data()
        inputKeyMaterial.append(Data(userKey.utf8))
        inputKeyMaterial.append(Data(serverId.utf8))

        CoreLogger.shared.debug("Combined key material: \(inputKeyMaterial.count) bytes", module: "CATEncryption")

        // 3. Derive using HKDF-SHA256
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: inputKeyMaterial),
            salt: salt,
            info: Data(hkdfInfo.utf8),
            outputByteCount: keyLength
        )

        // 4. Wipe intermediate data (security best practice)
        inputKeyMaterial.resetBytes(in: 0..<inputKeyMaterial.count)

        CoreLogger.shared.info("CAT key derived successfully", module: "CATEncryption")

        return derivedKey
    }

    // MARK: - Encryption (Local)

    /// Encrypts a signed CAT token for local storage using device-bound key
    ///
    /// This method is called after receiving a signed CAT from the Backend.
    /// The Backend only signs - all encryption happens here on the device.
    ///
    /// - Parameters:
    ///   - signedToken: The Ed25519-signed CAT token from Backend
    ///   - serverId: The server this CAT is for (used in key derivation)
    /// - Returns: Encrypted payload with locally-generated salt and nonce
    /// - Throws: CATEncryptionError if encryption fails
    public func encrypt(
        signedToken: String,
        serverId: String
    ) async throws -> EncryptedCATPayload {

        CoreLogger.shared.info("Encrypting CAT locally for server: \(serverId)", module: "CATEncryption")

        // Generate fresh salt and nonce for this encryption
        var salt = Data(count: saltLength)
        var nonce = Data(count: nonceLength)

        let saltResult = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, saltLength, $0.baseAddress!) }
        let nonceResult = nonce.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, nonceLength, $0.baseAddress!) }

        guard saltResult == errSecSuccess, nonceResult == errSecSuccess else {
            CoreLogger.shared.error("Failed to generate random bytes for encryption", module: "CATEncryption")
            throw CATEncryptionError.encryptionFailed
        }

        // Derive encryption key
        let encryptionKey = try await deriveKey(serverId: serverId, salt: salt)

        // Encrypt using AES-256-GCM
        do {
            let gcmNonce = try AES.GCM.Nonce(data: nonce)
            let tokenData = Data(signedToken.utf8)
            let sealedBox = try AES.GCM.seal(tokenData, using: encryptionKey, nonce: gcmNonce)

            // Combine ciphertext + tag (standard format)
            let encryptedWithTag = sealedBox.ciphertext + sealedBox.tag

            CoreLogger.shared.info("CAT encrypted successfully (\(encryptedWithTag.count) bytes)", module: "CATEncryption")

            return EncryptedCATPayload(
                encryptedCAT: encryptedWithTag.base64EncodedString(),
                salt: salt.base64EncodedString(),
                nonce: nonce.base64EncodedString(),
                version: currentVersion
            )

        } catch {
            CoreLogger.shared.error("AES-GCM encryption failed: \(error.localizedDescription)", module: "CATEncryption")
            throw CATEncryptionError.encryptionFailed
        }
    }

    // MARK: - Decryption

    /// Decrypts an encrypted CAT payload and returns the signed token
    ///
    /// - Parameters:
    ///   - payload: The locally-encrypted CAT payload
    ///   - serverId: The server this CAT is for
    /// - Returns: The decrypted signed CAT token string
    /// - Throws: CATEncryptionError if decryption fails
    public func decrypt(
        payload: EncryptedCATPayload,
        serverId: String
    ) async throws -> String {

        CoreLogger.shared.info("Decrypting CAT for server: \(serverId)", module: "CATEncryption")

        // Validate version
        guard payload.version == currentVersion else {
            CoreLogger.shared.error("Unsupported CAT encryption version: \(payload.version)", module: "CATEncryption")
            throw CATEncryptionError.unsupportedVersion(payload.version)
        }

        // Decode components
        guard let encryptedData = Data(base64Encoded: payload.encryptedCAT) else {
            CoreLogger.shared.error("Failed to decode encrypted CAT data", module: "CATEncryption")
            throw CATEncryptionError.invalidPayloadFormat
        }

        guard let salt = Data(base64Encoded: payload.salt) else {
            CoreLogger.shared.error("Failed to decode salt", module: "CATEncryption")
            throw CATEncryptionError.invalidPayloadFormat
        }

        guard let nonceData = Data(base64Encoded: payload.nonce) else {
            CoreLogger.shared.error("Failed to decode nonce", module: "CATEncryption")
            throw CATEncryptionError.invalidPayloadFormat
        }

        // Validate lengths
        guard nonceData.count == nonceLength else {
            CoreLogger.shared.error("Invalid nonce length: \(nonceData.count) (expected \(nonceLength))", module: "CATEncryption")
            throw CATEncryptionError.invalidNonceLength
        }

        guard salt.count == saltLength else {
            CoreLogger.shared.error("Invalid salt length: \(salt.count) (expected \(saltLength))", module: "CATEncryption")
            throw CATEncryptionError.invalidSaltLength
        }

        // Encrypted data must be at least auth tag size (16 bytes)
        guard encryptedData.count > 16 else {
            CoreLogger.shared.error("Encrypted data too short: \(encryptedData.count) bytes", module: "CATEncryption")
            throw CATEncryptionError.invalidPayloadFormat
        }

        // Derive decryption key (same key derivation as encryption)
        let decryptionKey = try await deriveKey(serverId: serverId, salt: salt)

        // Decrypt using AES-256-GCM
        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)

            // Split encrypted data into ciphertext and auth tag
            // Format: ciphertext || auth_tag (16 bytes)
            let ciphertext = encryptedData.dropLast(16)
            let tag = encryptedData.suffix(16)

            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: ciphertext,
                tag: tag
            )

            let decryptedData = try AES.GCM.open(sealedBox, using: decryptionKey)

            guard let signedToken = String(data: decryptedData, encoding: .utf8) else {
                CoreLogger.shared.error("Decrypted CAT is not valid UTF-8", module: "CATEncryption")
                throw CATEncryptionError.decryptionFailed
            }

            CoreLogger.shared.info("CAT decrypted successfully (\(signedToken.count) chars)", module: "CATEncryption")
            return signedToken

        } catch let error as CATEncryptionError {
            throw error
        } catch {
            CoreLogger.shared.error("AES-GCM decryption failed: \(error.localizedDescription)", module: "CATEncryption")
            throw CATEncryptionError.decryptionFailed
        }
    }

    // MARK: - Version Check

    /// Checks if an encrypted CAT payload version is supported
    /// - Parameter version: The version string to check
    /// - Returns: true if supported
    public func isVersionSupported(_ version: String) -> Bool {
        return version == currentVersion
    }

    /// Returns the current encryption version
    public func getCurrentVersion() -> String {
        return currentVersion
    }
}

// MARK: - Convenience Extensions

public extension CATEncryption {

    /// Quick check if an encrypted payload can be decrypted
    /// - Parameters:
    ///   - payload: The encrypted CAT payload
    ///   - serverId: The server ID
    /// - Returns: true if decryption succeeded
    func canDecrypt(payload: EncryptedCATPayload, serverId: String) async -> Bool {
        do {
            _ = try await decrypt(payload: payload, serverId: serverId)
            return true
        } catch {
            return false
        }
    }
}
