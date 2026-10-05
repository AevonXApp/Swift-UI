//
//  CryptoModels.swift
//  AevonXCoreBridge
//
//  Swift wrappers for Go Core cryptographic operations.
//  Provides async, type-safe APIs over the C bridge.
//

import Foundation
import AevonXCoreLib

// MARK: - Crypto Bridge

/// Bridge to Go Core cryptographic functions.
public final class CryptoBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = CryptoBridge()
    private init() {}

    // MARK: - AES-256-GCM

    /// Encrypts a string using AES-256-GCM.
    /// - Parameters:
    ///   - plaintext: The string to encrypt
    ///   - keyBase64: Base64-encoded 256-bit key
    /// - Returns: Base64-encoded ciphertext
    public func encrypt(_ plaintext: String, keyBase64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = plaintext.withMutableCString { p in keyBase64.withMutableCString { k in CryptoEncrypt(p, k) } }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "ciphertext")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Decrypts base64-encoded AES-256-GCM ciphertext.
    public func decrypt(_ ciphertextBase64: String, keyBase64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = ciphertextBase64.withMutableCString { c in keyBase64.withMutableCString { k in CryptoDecrypt(c, k) } }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "plaintext")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Key Derivation

    /// Derives a 256-bit key from a password using Argon2id.
    public func deriveKey(password: String, saltBase64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = password.withMutableCString { p in saltBase64.withMutableCString { s in CryptoDeriveKey(p, s) } }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "key")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Generates a cryptographically secure random salt.
    public func generateSalt() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = CryptoGenerateSalt()
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "salt")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - ECDH Key Exchange

    /// Generates an ephemeral key pair for ECDH.
    public func ecdhGenerateKeyPair() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = CryptoECDHGenerateKeyPair()
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "public_key")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Derives a shared session key from server's public key.
    public func ecdhDeriveSharedSecret(serverPublicKeyBase64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = serverPublicKeyBase64.withMutableCString { CryptoECDHDeriveSharedSecret($0) }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "session_key")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Clears all ephemeral ECDH key material from memory.
    public func ecdhClear() {
        CryptoECDHClear()
    }

    // MARK: - API Payload Encryption

    /// Encrypts a JSON payload for zero-knowledge API transmission.
    public func encryptAPIPayload(_ jsonString: String, keyBase64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = jsonString.withMutableCString { j in keyBase64.withMutableCString { k in CryptoEncryptAPIPayload(j, k) } }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "payload")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Decrypts a base64 API response payload.
    public func decryptAPIPayload(_ payloadBase64: String, keyBase64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = payloadBase64.withMutableCString { p in keyBase64.withMutableCString { k in CryptoDecryptAPIPayload(p, k) } }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseStringField(result, field: "payload")
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers

    private func parseStringField(_ cStr: UnsafeMutablePointer<CChar>?, field: String) throws -> String {
        guard let cStr = cStr else {
            throw CoreBridgeError.nullResponse
        }

        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8) else {
            throw CoreBridgeError.invalidJSON
        }

        let response = try JSONDecoder().decode(BridgeResponse.self, from: data)
        guard response.success, let responseData = response.data else {
            throw CoreBridgeError.executionFailed(response.error ?? "Unknown crypto error")
        }

        guard let dict = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let value = dict[field] as? String else {
            throw CoreBridgeError.invalidJSON
        }

        return value
    }
}

// MARK: - Encrypted Payload

/// Structure for encrypted API communication.
public struct BridgeEncryptedPayload: Codable, Sendable {
    public let data: String
    public let sessionKey: String?
    public let timestamp: Int

    private enum CodingKeys: String, CodingKey {
        case data
        case sessionKey = "session_key"
        case timestamp
    }
}
