//
//  ServerEncryptionService.swift
//  AevonXCore
//
//  Simplified encryption service using a single user-provided key.
//  Replaces the old SplitKeyEncryptionService (composite key from 3 sources).
//
//  Architecture:
//    UserKey → HKDF-SHA256 → AES-256-GCM Key → Encrypt/Decrypt
//
//  The key is a UUID string stored in EncryptionKeyStore with biometric protection.
//

import Foundation
import CryptoKit

// MARK: - Errors

public enum ServerEncryptionError: Error, LocalizedError {
    case keyNotAvailable
    case encryptionFailed
    case decryptionFailed
    case invalidEncoding
    case invalidPayloadFormat

    public var errorDescription: String? {
        switch self {
        case .keyNotAvailable:
            return "Encryption key not available. Please unlock or enter your key."
        case .encryptionFailed:
            return "Failed to encrypt server data"
        case .decryptionFailed:
            return "Failed to decrypt server data. Wrong key or corrupted data."
        case .invalidEncoding:
            return "Invalid data encoding"
        case .invalidPayloadFormat:
            return "Invalid encrypted payload format"
        }
    }
}

// MARK: - ServerEncryptionService

/// Simplified encryption service using a single user key + HKDF-SHA256 + AES-256-GCM.
///
/// Usage:
/// ```swift
/// // Encrypt
/// let payload = try await ServerEncryptionService.shared.encryptServer(serverData)
///
/// // Decrypt
/// let serverData = try await ServerEncryptionService.shared.decryptServer(from: payload)
/// ```
public actor ServerEncryptionService {
    
    public static let shared = ServerEncryptionService()
    
    // MARK: - Constants
    
    /// Fixed app-level salt for HKDF key derivation
    /// This is NOT a secret — it's a domain separator to ensure unique key derivation
    private let hkdfSalt = "AevonX-Server-Encryption-Salt-v2".data(using: .utf8)!
    
    /// HKDF info string
    private let hkdfInfo = "AevonX-Server-Credentials-v2".data(using: .utf8)!
    
    private init() {
        CoreLogger.shared.info("ServerEncryptionService initialized", module: "Encryption")
    }
    
    // MARK: - Key Derivation
    
    /// Derives a 256-bit AES key from the user's encryption key using HKDF-SHA256.
    /// - Returns: A SymmetricKey suitable for AES-256-GCM
    /// - Throws: ServerEncryptionError.keyNotAvailable if key not in Keychain
    private func deriveKey() async throws -> SymmetricKey {
        let userKey: String
        do {
            userKey = try await EncryptionKeyStore.shared.getKey()
        } catch {
            CoreLogger.shared.error("Failed to get encryption key: \(error.localizedDescription)", module: "Encryption")
            throw ServerEncryptionError.keyNotAvailable
        }
        
        let inputKeyMaterial = SymmetricKey(data: Data(userKey.utf8))
        
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: hkdfSalt,
            info: hkdfInfo,
            outputByteCount: 32 // 256 bits
        )
        
        return derivedKey
    }
    
    // MARK: - Ready State
    
    /// Whether the encryption service has a key available (cached or in Keychain)
    public var isReady: Bool {
        get async {
            return EncryptionKeyStore.shared.hasKey()
        }
    }
    
    /// Whether the key is unlocked (cached, no biometric needed)
    public var isUnlocked: Bool {
        get async {
            return EncryptionKeyStore.shared.isUnlocked
        }
    }
    
    /// Preloads the encryption key (triggers biometric if needed)
    /// Call this once at app startup to cache the key
    /// - Returns: true if key was successfully loaded
    @discardableResult
    public func preloadKey() async throws -> Bool {
        let _ = try await EncryptionKeyStore.shared.getKey()
        return true
    }
    
    // MARK: - Encrypt
    
    /// Encrypts raw data using AES-256-GCM
    /// - Parameter data: The plaintext data to encrypt
    /// - Returns: EncryptedServerPayload containing ciphertext, nonce, tag, and metadata
    /// - Throws: ServerEncryptionError if encryption fails
    public func encrypt(data: Data) async throws -> EncryptedServerPayload {
        let key = try await deriveKey()
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            guard let combined = sealedBox.combined else {
                throw ServerEncryptionError.encryptionFailed
            }
            
            // AES-GCM combined format: nonce (12) + ciphertext + tag (16)
            let nonceData = sealedBox.nonce.withUnsafeBytes { Data($0) }
            let ciphertext = sealedBox.ciphertext
            let tag = sealedBox.tag
            
            let payload = EncryptedServerPayload(
                encryptedData: Data(ciphertext).base64EncodedString(),
                nonce: nonceData.map { String(format: "%02x", $0) }.joined(),
                authTag: Data(tag).base64EncodedString(),
                metadata: EncryptionMetadata(
                    version: "3.0",
                    kdfAlgorithm: "hkdf-sha256",
                    cipherSuite: "aes-256-gcm",
                    keyPurpose: "server_credentials_v2",
                    derivationVersion: "2.0"
                )
            )
            
            CoreLogger.shared.info("Encrypted \(data.count) bytes successfully", module: "Encryption")
            return payload
            
        } catch let error as ServerEncryptionError {
            throw error
        } catch {
            CoreLogger.shared.error("AES-GCM encryption failed: \(error.localizedDescription)", module: "Encryption")
            throw ServerEncryptionError.encryptionFailed
        }
    }
    
    /// Decrypts an encrypted payload back to raw data
    /// - Parameter payload: The encrypted payload
    /// - Returns: The decrypted plaintext data
    /// - Throws: ServerEncryptionError if decryption fails
    public func decrypt(payload: EncryptedServerPayload) async throws -> Data {
        let key = try await deriveKey()
        
        // Decode components
        guard let ciphertext = Data(base64Encoded: payload.encryptedData),
              let tag = Data(base64Encoded: payload.authTag) else {
            CoreLogger.shared.error("Failed to decode base64 components", module: "Encryption")
            throw ServerEncryptionError.invalidEncoding
        }
        
        // Decode hex nonce
        guard let nonceData = Data(hexString: payload.nonce) else {
            CoreLogger.shared.error("Failed to decode hex nonce", module: "Encryption")
            throw ServerEncryptionError.invalidEncoding
        }
        
        CoreLogger.shared.debug("Decrypting — ciphertext: \(ciphertext.count)B, nonce: \(nonceData.count)B, tag: \(tag.count)B", module: "Encryption")
        
        do {
            // Reconstruct sealed box: nonce + ciphertext + tag
            var combined = Data()
            combined.append(nonceData)
            combined.append(ciphertext)
            combined.append(tag)
            
            let sealedBox = try AES.GCM.SealedBox(combined: combined)
            let plaintext = try AES.GCM.open(sealedBox, using: key)
            
            CoreLogger.shared.info("Decrypted \(plaintext.count) bytes successfully", module: "Encryption")
            return plaintext
            
        } catch {
            CoreLogger.shared.error("AES-GCM decryption failed: \(error.localizedDescription)", module: "Encryption")
            throw ServerEncryptionError.decryptionFailed
        }
    }
    
    // MARK: - Server-Specific Encrypt/Decrypt
    
    /// Encrypts a Codable server data struct
    /// - Parameter server: Any Codable server data (e.g. EncryptedServerData)
    /// - Returns: EncryptedServerPayload ready to send to API
    public func encryptServer<T: Encodable>(_ server: T) async throws -> EncryptedServerPayload {
        let jsonData = try JSONEncoder().encode(server)
        CoreLogger.shared.debug("Encoding server data: \(jsonData.count) bytes", module: "Encryption")
        return try await encrypt(data: jsonData)
    }
    
    /// Decrypts an encrypted payload back to a typed server data struct
    /// - Parameters:
    ///   - type: The Codable type to decode into
    ///   - payload: The encrypted payload from the API
    /// - Returns: The decoded server data
    public func decryptServer<T: Decodable>(_ type: T.Type, from payload: EncryptedServerPayload) async throws -> T {
        let plaintext = try await decrypt(payload: payload)
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: plaintext)
            return decoded
        } catch {
            CoreLogger.shared.error("Failed to decode decrypted data: \(error.localizedDescription)", module: "Encryption")
            throw ServerEncryptionError.invalidPayloadFormat
        }
    }
}
