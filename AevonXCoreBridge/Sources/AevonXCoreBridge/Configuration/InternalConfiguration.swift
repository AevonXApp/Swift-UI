//
//  InternalConfiguration.swift
//  AevonXCoreBridge
//
//  Internal security configuration - compiled constants
//  All sensitive configuration lives here, NOT in Info.plist
//

import Foundation

// MARK: - Internal Configuration

/// Internal configuration for security-sensitive settings
/// These are compiled constants, not exposed through Info.plist
public enum InternalConfiguration {
    
    // MARK: - CAT (Connection Authorization Token)
    
    /// Ed25519 public key for verifying CAT tokens
    /// Base64-encoded 32-byte public key
    /// Generated: 2026-02-03 - Rotated for security hardening
    public static let catPublicKey: String = "c+Lq77vdSo8wxRHR35KB7FazVCynLvbqayfjv0z3/Xg="
    
    // MARK: - API Configuration
    
    /// API base URL - empty by default, configured at build time or runtime
    /// UI layer does NOT know this value
    public static let apiBaseURL: String = ""
    
    /// API version
    public static let apiVersion: String = "v1"
    
    // MARK: - SSH Configuration
    
    /// Default SSH port
    public static let sshDefaultPort: Int = 22
    
    /// SSH connection timeout in seconds (must match Go SSHConnectTimeout = 15s)
    public static let sshConnectionTimeout: TimeInterval = 15.0
    
    /// SSH keep-alive interval in seconds
    public static let sshKeepAliveInterval: TimeInterval = 60.0
    
    /// SSH background TTL in seconds (5 minutes)
    public static let sshBackgroundTTL: TimeInterval = 300.0
    
    // MARK: - Connection Pool Configuration
    
    /// Maximum connection pool size
    public static let connectionPoolMaxSize: Int = 5
    
    /// Connection background TTL in seconds
    public static let connectionBackgroundTTL: TimeInterval = 300.0
    
    /// Server stats polling interval in seconds
    public static let statsPollingInterval: TimeInterval = 15.0
    
    /// API polling interval when in foreground (in seconds)
    public static let apiPollingInterval: TimeInterval = 60.0
    
    /// API polling interval when in background (in seconds)
    public static let apiPollingIntervalBackground: TimeInterval = 300.0
    
    // MARK: - Reconnection Configuration
    
    /// Maximum reconnection attempts before giving up
    public static let reconnectionMaxAttempts: Int = 5
    
    /// Base delay for exponential backoff (seconds)
    public static let reconnectionBaseDelay: TimeInterval = 2.0
    
    /// Maximum delay between reconnection attempts (seconds)
    public static let reconnectionMaxDelay: TimeInterval = 30.0
    
    /// Time before showing the reconnection banner (seconds)
    public static let reconnectionSilentThreshold: TimeInterval = 2.0
    
    /// Time before escalating to the full overlay (seconds)
    public static let reconnectionOverlayThreshold: TimeInterval = 8.0
    
    /// Consecutive keepalive failures before triggering reconnection
    public static let keepAliveFailureThreshold: Int = 2
    
    /// Health check heartbeat interval in seconds
    public static let healthCheckInterval: TimeInterval = 30.0
    
    // MARK: - Security Check Intervals
    
    /// Integrity check interval in seconds
    public static let integrityCheckInterval: TimeInterval = 60.0
    
    /// Jailbreak check interval in seconds
    public static let jailbreakCheckInterval: TimeInterval = 30.0
    
    /// Anti-debug check interval in seconds
    public static let antiDebugCheckInterval: TimeInterval = 5.0
    
    // MARK: - Feature Flags
    
    /// Enable certificate pinning
    public static let enableCertificatePinning: Bool = true
    
    /// Require biometric authentication
    public static let requireBiometricAuth: Bool = true
    
    /// Enable jailbreak detection
    public static let enableJailbreakDetection: Bool = true
    
    /// Enable anti-debug protection
    public static let enableAntiDebug: Bool = true
    
    /// Enable integrity checking
    public static let enableIntegrityChecking: Bool = true
    
    // MARK: - Certificate Pinning
    
    /// Pinned certificate hashes by domain
    /// Dictionary of domain -> [SHA-256 SPKI hashes]
    ///
    /// To generate a pin for your domain:
    /// ```
    /// openssl s_client -connect api.aevonx.app:443 -servername api.aevonx.app 2>/dev/null | \
    ///     openssl x509 -pubkey -noout | \
    ///     openssl pkey -pubin -outform DER | \
    ///     openssl dgst -sha256 -binary | base64
    /// ```
    ///
    /// > **IMPORTANT**: Populate these hashes before production release.
    /// > Include at least 2 pins (primary + backup CA) per domain.
    public static let pinnedCertificateHashes: [String: [String]] = [:]
    // Example entry (uncomment and populate before release):
    // "api.aevonx.app": [
    //     "PRIMARY_SPKI_SHA256_BASE64_HERE",     // Leaf certificate pin
    //     "BACKUP_CA_SPKI_SHA256_BASE64_HERE"     // Backup CA pin (rotation safety)
    // ]
    
    /// Backup pinned certificate hashes by domain
    /// Used for certificate rotation — when primary pins are being rotated,
    /// backup pins prevent lockout during the transition period
    public static let backupPinnedCertificateHashes: [String: [String]] = [:]
    // Example entry:
    // "api.aevonx.app": [
    //     "NEW_CERT_SPKI_SHA256_BASE64_HERE"     // Pre-pinned next certificate
    // ]
    
    // MARK: - Network Timeouts
    
    /// Default request timeout in seconds
    public static let requestTimeout: TimeInterval = 30.0
    
    /// Default resource timeout in seconds
    public static let resourceTimeout: TimeInterval = 300.0
    
    /// Maximum retry attempts for failed requests
    public static let maxRetryAttempts: Int = 3
    
    // MARK: - CAT Token Validation
    
    /// Minimum allowed CAT token TTL in seconds
    public static let catMinTTL: Int = 30
    
    /// Maximum allowed CAT token TTL in seconds
    public static let catMaxTTL: Int = 60
    
    /// Default CAT token TTL in seconds
    public static let catDefaultTTL: Int = 45
    
    /// Nonce storage TTL in seconds (5 minutes)
    public static let catNonceStorageTTL: TimeInterval = 300.0
}

// MARK: - Configuration Helpers

public extension InternalConfiguration {
    
    /// Returns whether a domain has pinned certificates configured
    static func hasPinnedCertificates(for domain: String) -> Bool {
        return pinnedCertificateHashes[domain] != nil
    }
    
    /// Returns pinned certificate hashes for a domain
    static func pinnedHashes(for domain: String) -> [String] {
        return pinnedCertificateHashes[domain] ?? []
    }
    
    /// Returns backup pinned certificate hashes for a domain
    static func backupPinnedHashes(for domain: String) -> [String] {
        return backupPinnedCertificateHashes[domain] ?? []
    }
    
    /// Returns the full API URL for a given endpoint path
    static func apiURL(for path: String) -> URL? {
        guard !apiBaseURL.isEmpty else { return nil }
        let base = apiBaseURL.hasSuffix("/") ? apiBaseURL : apiBaseURL + "/"
        let versionedPath = "\(apiVersion)/\(path)"
        return URL(string: base + versionedPath)
    }
}
