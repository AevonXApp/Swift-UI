//
//  SSLCertificateDetails.swift
//  AevonX
//
//  UI layer extensions for SSL certificate details
//  Core types are defined in AevonXCore
//

import Foundation
import AevonXCore

// MARK: - Type Aliases (Re-export from Core)

public typealias SSLCertificateDetails = AevonXCore.SSLCertificateDetails
public typealias CoreCertificateType = AevonXCore.CoreCertificateType

// MARK: - UI Layer Extensions

extension CoreCertificateType {
    public var icon: String {
        switch self {
        case .single: return "doc.badge.gearshape"
        case .wildcard: return "star.circle"
        case .multiDomain: return "building.2"
        }
    }
}

extension SSLCertificateDetails {
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

    /// Security grade based on key size and protocols
    public var securityGrade: String {
        if keySize >= 4096 && protocols.contains("TLSv1.3") {
            return "A+"
        } else if keySize >= 2048 && supportsModernTLS {
            return "A"
        } else if keySize >= 2048 {
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

    public var color: String {
        switch self {
        case .valid: return "axSuccess"
        case .expiringSoon: return "axWarning"
        case .expired: return "axError"
        case .notYetValid: return "axTextMuted"
        case .revoked: return "axError"
        case .invalid: return "axError"
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
        }
    }
}

// MARK: - SSL Challenge Type

/// Challenge type for Let's Encrypt certificate issuance
public enum SSLChallengeType: String, Codable, CaseIterable {
    case http01 = "HTTP-01"
    case dns01 = "DNS-01"
    case tlsAlpn01 = "TLS-ALPN-01"

    public var description: String {
        switch self {
        case .http01:
            return "Places a verification file on the web server"
        case .dns01:
            return "Adds a TXT record to DNS (supports wildcards)"
        case .tlsAlpn01:
            return "Uses TLS protocol extension for verification"
        }
    }

    public var icon: String {
        switch self {
        case .http01: return "network"
        case .dns01: return "globe"
        case .tlsAlpn01: return "lock.shield"
        }
    }
}

// MARK: - Custom Certificate Upload

/// Data for uploading a custom SSL certificate
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

    /// Validate certificate data format
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

/// HTTP Strict Transport Security configuration
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

    /// HSTS header value
    public var headerValue: String {
        var parts = ["max-age=\(maxAge)"]
        if includeSubDomains {
            parts.append("includeSubDomains")
        }
        if preload {
            parts.append("preload")
        }
        return parts.joined(separator: "; ")
    }

    /// Human-readable max age
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
