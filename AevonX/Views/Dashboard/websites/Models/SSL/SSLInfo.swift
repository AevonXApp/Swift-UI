//
//  SSLInfo.swift
//  AevonX
//
//  SSL certificate information model
//

import Foundation

// MARK: - SSL Info

/// Represents SSL/TLS certificate information
public struct SSLInfo: Codable, Hashable {
    public var provider: SSLProvider
    public var status: SSLStatus
    public var issuer: String?
    public var validFrom: Date?
    public var validUntil: Date?
    public var autoRenew: Bool
    public var domains: [String]
    public var certificateType: CertificateType

    public init(
        provider: SSLProvider = .other,
        status: SSLStatus = .pending,
        issuer: String? = nil,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        autoRenew: Bool = true,
        domains: [String] = [],
        certificateType: CertificateType = .single
    ) {
        self.provider = provider
        self.status = status
        self.issuer = issuer
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.autoRenew = autoRenew
        self.domains = domains
        self.certificateType = certificateType
    }

    /// Days until certificate expires
    public var daysUntilExpiry: Int? {
        guard let validUntil = validUntil else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day
        return days
    }

    /// Whether certificate is about to expire (< 30 days)
    public var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days < 30
    }

    /// Whether certificate has expired
    public var isExpired: Bool {
        guard let validUntil = validUntil else { return false }
        return Date() > validUntil
    }

    /// Detect SSL provider from issuer string
    public static func detectProvider(from issuer: String) -> SSLProvider {
        let lower = issuer.lowercased()
        if lower.contains("let's encrypt") || lower.contains("letsencrypt") {
            return .letsEncrypt
        } else if lower.contains("cloudflare") {
            return .cloudflare
        } else if lower.contains("digicert") || lower.contains("comodo") || lower.contains("sectigo") ||
                    lower.contains("geotrust") || lower.contains("globalsign") || lower.contains("godaddy") ||
                    lower.contains("rapidssl") || lower.contains("thawte") || lower.contains("entrust") ||
                    lower.contains("buypass") || lower.contains("certum") || lower.contains("ssl.com") {
            return .other
        } else {
            return .customCertificate
        }
    }
}

// MARK: - SSL Provider

public enum SSLProvider: String, Codable, CaseIterable {
    case letsEncrypt = "Let's Encrypt"
    case customCertificate = "Custom Certificate"
    case cloudflare = "Cloudflare"
    case other = "Other"
}

// MARK: - SSL Status

public enum SSLStatus: String, Codable, CaseIterable {
    case active = "active"
    case pending = "pending"
    case expired = "expired"
    case invalid = "invalid"
    case revoked = "revoked"
    case unknown = "unknown"
}

// MARK: - Certificate Type

public enum CertificateType: String, Codable, CaseIterable {
    case single = "Single Domain"
    case wildcard = "Wildcard"
    case multiDomain = "Multi-Domain"
}
