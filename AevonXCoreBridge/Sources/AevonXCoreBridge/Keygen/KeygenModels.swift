//
//  KeygenModels.swift
//  AevonXCoreBridge
//
//  Codable models matching JSON returned by Go bridge/exports_keygen.go.
//  Field names use snake_case to match the Go encoder; CodingKeys translate
//  them into Swift's idiomatic camelCase.
//

import Foundation

// MARK: - Key Type

/// SSH key algorithm. Mirrors Go's keygen.KeyType.
public enum KeygenType: String, Codable, Sendable, CaseIterable {
    case ed25519 = "ed25519"
    case rsa4096 = "rsa-4096"
    case ecdsaP256 = "ecdsa-p256"

    /// Display label suitable for UI buttons / pickers.
    public var displayName: String {
        switch self {
        case .ed25519: return "Ed25519"
        case .rsa4096: return "RSA-4096"
        case .ecdsaP256: return "ECDSA P-256"
        }
    }

    /// One-line description of when to pick this algorithm.
    public var subtitle: String {
        switch self {
        case .ed25519: return "Modern, fast, recommended"
        case .rsa4096: return "Maximum compatibility"
        case .ecdsaP256: return "FIPS-compliant"
        }
    }

    /// SSH wire-format algorithm name (e.g. "ssh-ed25519").
    public var sshAlgorithm: String {
        switch self {
        case .ed25519: return "ssh-ed25519"
        case .rsa4096: return "ssh-rsa"
        case .ecdsaP256: return "ecdsa-sha2-nistp256"
        }
    }
}

// MARK: - Generated Key Pair

/// A freshly generated SSH key pair.
///
/// `privateKey` is OpenSSH PEM-encoded (encrypted if the request had a
/// passphrase). The caller is expected to:
///   1. Persist `privateKey` into the Keychain via `KeygenKeyStorage`.
///   2. Drop the in-memory copy as soon as it is no longer needed.
///
/// `fingerprint` is the SHA256:base64 digest used for de-duplication.
public struct KeygenKeyPair: Codable, Sendable {
    public let type: KeygenType
    public let publicKey: String
    public let privateKey: String
    public let fingerprint: String
    public let comment: String
    public let bitSize: Int

    private enum CodingKeys: String, CodingKey {
        case type
        case publicKey = "public_key"
        case privateKey = "private_key"
        case fingerprint
        case comment
        case bitSize = "bit_size"
    }

    public init(
        type: KeygenType,
        publicKey: String,
        privateKey: String,
        fingerprint: String,
        comment: String,
        bitSize: Int
    ) {
        self.type = type
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.fingerprint = fingerprint
        self.comment = comment
        self.bitSize = bitSize
    }
}

// MARK: - Authorized Key Entry

/// One key parsed out of `~/.ssh/*.pub` or `~/.ssh/authorized_keys`.
public struct KeygenAuthorizedKey: Codable, Sendable, Identifiable {
    /// `Identifiable` synthesised from source + line index — stable for SwiftUI lists.
    public var id: String { "\(source)#\(lineIndex)" }

    /// Origin of the key. Either:
    ///   - `"authorized_keys"` for entries in that file
    ///   - the basename of a public key file (e.g. `"id_ed25519.pub"`)
    public let source: String

    /// Zero-based line index inside `source`. Always 0 for `.pub` files.
    public let lineIndex: Int

    /// Algorithm token, e.g. `"ssh-ed25519"` or `"ssh-rsa"`.
    public let algorithm: String

    /// Full single-line OpenSSH public key.
    public let publicKey: String

    /// Trailing comment from the line (often `"user@host"`). May be empty.
    public let comment: String

    /// SHA256 fingerprint, e.g. `"SHA256:Yz3..."`. Empty if the line was unparseable.
    public let fingerprint: String

    /// Recommended filename for the "Download Key" UI action.
    public let suggestedFilename: String

    private enum CodingKeys: String, CodingKey {
        case source
        case lineIndex = "line_index"
        case algorithm
        case publicKey = "public_key"
        case comment
        case fingerprint
        case suggestedFilename = "suggested_filename"
    }

    /// Pretty algorithm name for the UI (e.g. "Ed25519" instead of "ssh-ed25519").
    public var displayAlgorithm: String {
        switch algorithm {
        case "ssh-ed25519": return "Ed25519"
        case "ssh-rsa": return "RSA"
        case "ecdsa-sha2-nistp256": return "ECDSA P-256"
        case "ecdsa-sha2-nistp384": return "ECDSA P-384"
        case "ecdsa-sha2-nistp521": return "ECDSA P-521"
        case "ssh-dss": return "DSA"
        default:
            return algorithm.replacingOccurrences(of: "ssh-", with: "").uppercased()
        }
    }

    /// True if this entry came from `authorized_keys` (vs a `.pub` file).
    public var isAuthorizedEntry: Bool { source == "authorized_keys" }
}

// MARK: - Inject Outcome

/// Parsed result of running the inject command on the server.
public enum KeygenInjectOutcome: Sendable, Equatable {
    /// Key was appended to authorized_keys.
    case appended
    /// Key was already present — no change.
    case alreadyPresent
    /// Inject failed; the associated string is the server-supplied reason.
    case failed(String)

    /// Parse the single-line result emitted by the inject command.
    public static func parse(_ raw: String) -> KeygenInjectOutcome {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for line in trimmed.split(separator: "\n").reversed() {
            let s = String(line).trimmingCharacters(in: .whitespaces)
            if s == "INJECT_OK:appended" { return .appended }
            if s == "INJECT_OK:already_present" { return .alreadyPresent }
            if s.hasPrefix("INJECT_FAIL:") {
                return .failed(String(s.dropFirst("INJECT_FAIL:".count)))
            }
        }
        return .failed("no_response")
    }

    public var isSuccess: Bool {
        switch self {
        case .appended, .alreadyPresent: return true
        case .failed: return false
        }
    }
}

// MARK: - Verify Outcome

public enum KeygenVerifyOutcome: Sendable, Equatable {
    case present
    case missing
    case unknown

    public static func parse(_ raw: String) -> KeygenVerifyOutcome {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("VERIFY_OK") { return .present }
        if trimmed.contains("VERIFY_MISSING") { return .missing }
        return .unknown
    }
}

// MARK: - Port Detection

/// Detection method that produced the SSH port value. Mirrors Go enum.
public enum KeygenPortMethod: String, Codable, Sendable {
    case sshdEffective = "sshd_effective"
    case listening = "listening"
    case configFile = "config_file"
    case fallback = "fallback"

    /// Short label suitable for tooltips ("from sshd -T", "from listening socket"…).
    public var label: String {
        switch self {
        case .sshdEffective: return "sshd effective config"
        case .listening: return "listening socket"
        case .configFile: return "sshd_config file"
        case .fallback: return "default fallback"
        }
    }
}

/// The detected SSH port plus diagnostics.
public struct KeygenPortDetection: Codable, Sendable {
    public let port: Int
    public let method: KeygenPortMethod
    public let raw: String

    public init(port: Int, method: KeygenPortMethod, raw: String) {
        self.port = port
        self.method = method
        self.raw = raw
    }
}
