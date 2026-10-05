//
//  BridgeTypeStubs.swift
//  AevonXCoreBridge
//
//  Stub types for bridge compilation — small types from AevonXCore.
//

import Foundation

// MARK: - Detection Error

public enum DetectionError: Error, LocalizedError, Sendable {
    case unknownOS(output: String)
    case unknownInitSystem(output: String)
    case unknownPackageManager(output: String)
    case detectionFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .unknownOS(let output): return "Unknown OS: \(output)"
        case .unknownInitSystem(let output): return "Unknown init system: \(output)"
        case .unknownPackageManager(let output): return "Unknown package manager: \(output)"
        case .detectionFailed(let reason): return "Detection failed: \(reason)"
        }
    }
}

// MARK: - Encryption Models

public struct EncryptionMetadata: Codable {
    public let version: String
    public let kdfAlgorithm: String
    public let cipherSuite: String
    public let keyPurpose: String
    public let derivationVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case version
        case kdfAlgorithm = "kdf_algorithm"
        case cipherSuite = "cipher_suite"
        case keyPurpose = "key_purpose"
        case derivationVersion = "derivation_version"
    }
    
    public init(version: String = "1.0", kdfAlgorithm: String = "HKDF-SHA256", cipherSuite: String = "AES-256-GCM", keyPurpose: String = "server_encryption", derivationVersion: String? = nil) {
        self.version = version
        self.kdfAlgorithm = kdfAlgorithm
        self.cipherSuite = cipherSuite
        self.keyPurpose = keyPurpose
        self.derivationVersion = derivationVersion
    }
}

public struct EncryptedServerPayload: Codable {
    public let encryptedData: String
    public let nonce: String
    public let authTag: String
    public let metadata: EncryptionMetadata
    
    public init(encryptedData: String, nonce: String, authTag: String, metadata: EncryptionMetadata) {
        self.encryptedData = encryptedData
        self.nonce = nonce
        self.authTag = authTag
        self.metadata = metadata
    }
}

// MARK: - Server Encryption Service
// Full implementation moved to Security/ServerEncryptionService.swift

// MARK: - Server Response

public struct ServerResponse: Codable, Identifiable {
    public let id: String
    public let serverName: String?
    public let encryptedPayload: String
    public let payloadNonce: String
    public let payloadAuthTag: String
    public let encryptionMetadata: EncryptionMetadata
    public let createdAt: Date
    public let updatedAt: Date?
    public let lastAccessedAt: Date?
    public let isAccessible: Bool
    public let displayOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case serverName = "server_name"
        case encryptedPayload = "encrypted_payload"
        case payloadNonce = "payload_nonce"
        case payloadAuthTag = "payload_auth_tag"
        case encryptionMetadata = "encryption_metadata"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastAccessedAt = "last_accessed_at"
        case isAccessible = "is_accessible"
        case displayOrder = "display_order"
    }
    
    /// Converts to EncryptedServerPayload for decryption
    public func toEncryptedPayload() -> EncryptedServerPayload {
        return EncryptedServerPayload(
            encryptedData: encryptedPayload,
            nonce: payloadNonce,
            authTag: payloadAuthTag,
            metadata: encryptionMetadata
        )
    }
}

// MARK: - Subscription Status

public struct SubscriptionStatus: Codable {
    public let plan: String
    public let serverLimit: Int
    public let currentServerCount: Int
    public let accessibleServerIds: [String]
    public let subscription: SubscriptionInfo
    public let permitJSON: String?
    public let permitSignature: String?
    
    public init(plan: String, serverLimit: Int, currentServerCount: Int, accessibleServerIds: [String], subscription: SubscriptionInfo, permitJSON: String? = nil, permitSignature: String? = nil) {
        self.plan = plan
        self.serverLimit = serverLimit
        self.currentServerCount = currentServerCount
        self.accessibleServerIds = accessibleServerIds
        self.subscription = subscription
        self.permitJSON = permitJSON
        self.permitSignature = permitSignature
    }
    
    enum CodingKeys: String, CodingKey {
        case plan
        case serverLimit = "server_limit"
        case currentServerCount = "current_server_count"
        case accessibleServerIds = "accessible_server_ids"
        case subscription
        case permitJSON = "permit_json"
        case permitSignature = "permit_signature"
    }
}

public struct SubscriptionInfo: Codable {
    public let active: Bool
    public let expiredAt: Date?
    public let mostRecentServerId: String?
    
    public init(active: Bool, expiredAt: Date? = nil, mostRecentServerId: String? = nil) {
        self.active = active
        self.expiredAt = expiredAt
        self.mostRecentServerId = mostRecentServerId
    }
    
    enum CodingKeys: String, CodingKey {
        case active
        case expiredAt = "expired_at"
        case mostRecentServerId = "most_recent_server_id"
    }
}
