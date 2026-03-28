//
//  SSLCertificateDetails.swift
//  AevonX
//
//  SSL certificate types — fully local, no AevonXCore dependency.
//  Originally defined in AevonXCore/CoreWebsiteModels.swift, now local.
//

import Foundation
import SwiftUI

// MARK: - Core Certificate Type

public enum CoreCertificateType: String, Codable, Sendable {
    case single = "Single Domain"
    case wildcard = "Wildcard"
    case multiDomain = "Multi-Domain"

    public var icon: String {
        switch self {
        case .single: return "doc.badge.gearshape"
        case .wildcard: return "star.circle"
        case .multiDomain: return "building.2"
        }
    }
}

// MARK: - SSL Certificate Details

public struct SSLCertificateDetails: Codable, Sendable, Identifiable {
    public let id: UUID
    public var issuer: String
    public var subject: String
    public var validFrom: Date
    public var validUntil: Date
    public var serialNumber: String
    public var sanDomains: [String]
    public var certificateChain: [String]
    public var signatureAlgorithm: String
    public var keySize: Int
    public var protocols: [String]
    public var certificateType: CoreCertificateType
    public var autoRenew: Bool
    public var brand: String

    public init(
        id: UUID = UUID(),
        issuer: String,
        subject: String = "",
        validFrom: Date = Date(),
        validUntil: Date = Date(),
        serialNumber: String = "",
        sanDomains: [String] = [],
        certificateChain: [String] = [],
        signatureAlgorithm: String = "SHA256withRSA",
        keySize: Int = 2048,
        protocols: [String] = [],
        certificateType: CoreCertificateType = .single,
        autoRenew: Bool = true,
        brand: String = "Unknown",
        // Convenience parameters for VM usage
        status: SSLCertificateStatus? = nil,
        domains: [String]? = nil,
        daysUntilExpiry: Int? = nil,
        isExpiringSoon: Bool? = nil,
        isExpired: Bool? = nil
    ) {
        self.id = id
        self.issuer = issuer
        self.subject = subject
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.serialNumber = serialNumber
        self.sanDomains = domains ?? sanDomains
        self.certificateChain = certificateChain
        self.signatureAlgorithm = signatureAlgorithm
        self.keySize = keySize
        self.protocols = protocols
        self.certificateType = certificateType
        self.autoRenew = autoRenew
        self.brand = brand
    }

    /// Days until expiration
    public var daysUntilExpiry: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
        return max(0, days)
    }

    /// Whether certificate is expiring soon (< 30 days)
    public var isExpiringSoon: Bool {
        daysUntilExpiry < 30 && daysUntilExpiry > 0
    }

    /// Whether certificate has expired
    public var isExpired: Bool {
        Date() > validUntil
    }

    /// Whether certificate is valid
    public var isValid: Bool {
        let now = Date()
        return now >= validFrom && now <= validUntil
    }

    /// Certificate status
    public var status: SSLCertificateStatus {
        if isExpired {
            return .expired
        } else if isExpiringSoon {
            return .expiringSoon
        } else if isValid {
            return .valid
        } else {
            return .notYetValid
        }
    }

    /// Formatted expiry date
    public var formattedExpiry: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: validUntil)
    }

    /// Whether this is a Let's Encrypt certificate
    public var isLetsEncrypt: Bool {
        issuer.lowercased().contains("let's encrypt")
    }

    /// Whether this supports modern TLS
    public var supportsModernTLS: Bool {
        protocols.contains("TLSv1.3") || protocols.contains("TLSv1.2")
    }

    /// Whether this uses ECDSA (key sizes are much smaller than RSA but equally secure)
    public var isECDSA: Bool {
        signatureAlgorithm.lowercased().contains("ecdsa") ||
        signatureAlgorithm.lowercased().contains("ec") ||
        (keySize > 0 && keySize <= 521) // ECDSA keys are 256, 384, or 521 bits
    }

    /// Security grade based on key size, algorithm, and protocols.
    /// When protocols are unknown (empty), grade is based on key strength alone
    /// without the TLS 1.3 bonus — avoids inflating grade when data is incomplete.
    public var securityGrade: String {
        // ECDSA 256-bit ≈ RSA 3072-bit, ECDSA 384-bit ≈ RSA 7680-bit
        let effectiveStrength: Int
        if isECDSA {
            effectiveStrength = keySize >= 384 ? 7680 : keySize >= 256 ? 3072 : 2048
        } else {
            effectiveStrength = keySize
        }

        let hasProtocolInfo = !protocols.isEmpty

        if effectiveStrength >= 3072 && hasProtocolInfo && protocols.contains("TLSv1.3") {
            return "A+"
        } else if effectiveStrength >= 3072 {
            return "A"
        } else if effectiveStrength >= 2048 && (!hasProtocolInfo || supportsModernTLS) {
            return "A"
        } else if effectiveStrength >= 2048 {
            return "B"
        } else {
            return "C"
        }
    }
}

// MARK: - SSL Certificate Status

public enum SSLCertificateStatus: String, Codable {
    case valid = "Valid"
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
    case notYetValid = "Not Yet Valid"
    case revoked = "Revoked"
    case invalid = "Invalid"
    case unknown = "Unknown"

    public var color: Color {
        switch self {
        case .valid: return .axSuccess
        case .expiringSoon: return .axWarning
        case .expired: return .axError
        case .notYetValid: return .axTextMuted
        case .revoked: return .axError
        case .invalid: return .axError
        case .unknown: return .axTextMuted
        }
    }

    public var icon: String {
        switch self {
        case .valid: return "checkmark.shield.fill"
        case .expiringSoon: return "exclamationmark.shield.fill"
        case .expired: return "xmark.shield.fill"
        case .notYetValid: return "clock.badge.questionmark"
        case .revoked: return "xmark.shield.fill"
        case .invalid: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - SSL Challenge Type

public enum SSLChallengeType: String, Codable, CaseIterable {
    case http01 = "HTTP-01"
    case dns01 = "DNS-01"

    public var description: String {
        switch self {
        case .http01:
            return "Automatic — verifies via your web server (recommended)"
        case .dns01:
            return "Manual — requires adding a DNS TXT record"
        }
    }

    public var detailedDescription: String? {
        switch self {
        case .http01:
            return nil
        case .dns01:
            return "You must add a TXT record to your DNS:\n\nName: _acme-challenge.yourdomain.com\nType: TXT\nValue: (provided by certbot)\n\n⚠️ DNS-01 requires manual steps and is only needed for wildcard certificates. Use HTTP-01 for standard domains."
        }
    }

    public var icon: String {
        switch self {
        case .http01: return "network"
        case .dns01: return "globe"
        }
    }
}

// MARK: - Custom Certificate Upload

public struct CustomCertificateUpload: Codable {
    public var certificate: String
    public var privateKey: String
    public var chainBundle: String?
    public var password: String?

    public init(certificate: String, privateKey: String, chainBundle: String? = nil, password: String? = nil) {
        self.certificate = certificate
        self.privateKey = privateKey
        self.chainBundle = chainBundle
        self.password = password
    }

    public func validate() -> [String] {
        var errors: [String] = []
        if !certificate.contains("BEGIN CERTIFICATE") {
            errors.append("Invalid certificate format")
        }
        if !privateKey.contains("BEGIN") || !privateKey.contains("PRIVATE KEY") {
            errors.append("Invalid private key format")
        }
        if let chain = chainBundle, !chain.contains("BEGIN CERTIFICATE") {
            errors.append("Invalid certificate chain format")
        }
        return errors
    }
}

// MARK: - HSTS Configuration

public struct HSTSConfiguration: Codable {
    public var enabled: Bool
    public var maxAge: Int
    public var includeSubDomains: Bool
    public var preload: Bool

    public init(enabled: Bool = false, maxAge: Int = 31536000, includeSubDomains: Bool = false, preload: Bool = false) {
        self.enabled = enabled
        self.maxAge = maxAge
        self.includeSubDomains = includeSubDomains
        self.preload = preload
    }

    public var headerValue: String {
        var parts = ["max-age=\(maxAge)"]
        if includeSubDomains { parts.append("includeSubDomains") }
        if preload { parts.append("preload") }
        return parts.joined(separator: "; ")
    }

    public var formattedMaxAge: String {
        let days = maxAge / 86400
        if days >= 365 {
            return "\(days / 365) year(s)"
        } else if days >= 30 {
            return "\(days / 30) month(s)"
        } else {
            return "\(days) day(s)"
        }
    }
}

// MARK: - SSL DNS Record

public struct SSLDNSRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public var domainName: String
    public var recordValue: String
    public var recordType: String
    public var isRequired: Bool

    public init(id: UUID = UUID(), domainName: String = "", recordValue: String = "", recordType: String = "TXT", isRequired: Bool = true) {
        self.id = id
        self.domainName = domainName
        self.recordValue = recordValue
        self.recordType = recordType
        self.isRequired = isRequired
    }

    // Convenience init for DNS lookup results
    public init(type: String, name: String, value: String) {
        self.id = UUID()
        self.domainName = name
        self.recordValue = value
        self.recordType = type
        self.isRequired = false
    }
}

// MARK: - SSL Certificate Content (PEM data)

public struct SSLCertificateContent: Codable, Sendable {
    public var certificate: String
    public var privateKey: String
    public var chain: String?

    public init(certificate: String, privateKey: String, chain: String? = nil) {
        self.certificate = certificate
        self.privateKey = privateKey
        self.chain = chain
    }
}
