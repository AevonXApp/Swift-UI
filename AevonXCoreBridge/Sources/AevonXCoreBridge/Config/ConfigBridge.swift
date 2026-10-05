//
//  ConfigBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core configuration queries.
//

import Foundation
import AevonXCoreLib

// MARK: - Config Bridge

/// Bridge to Go Core configuration.
public final class ConfigBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = ConfigBridge()
    private init() {}

    /// Returns the Go Core version and build mode.
    public func getVersion() -> (version: String, buildMode: String)? {
        let result = ConfigGetVersion()
        defer { CoreFreeString(result) }

        guard let cStr = result else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let response = try? JSONDecoder().decode(BridgeResponse.self, from: data),
              response.success,
              let responseData = response.data,
              let dict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let version = dict["version"] as? String,
              let buildMode = dict["build_mode"] as? String else {
            return nil
        }

        return (version, buildMode)
    }

    /// Returns all security feature flags.
    public func getFeatureFlags() -> BridgeFeatureFlags? {
        let result = ConfigGetFeatureFlags()
        defer { CoreFreeString(result) }

        guard let cStr = result else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let response = try? JSONDecoder().decode(BridgeResponse.self, from: data),
              response.success,
              let responseData = response.data else {
            return nil
        }

        return try? JSONDecoder().decode(BridgeFeatureFlags.self, from: responseData)
    }

    /// Checks if a domain has pinned certificates.
    public func hasPinnedCertificates(for domain: String) -> Bool {
        return withCArgs { c in ConfigHasPinnedCerts(c.str(domain)) == 1 }
    }
}

// MARK: - Feature Flags

/// Security feature flags from Go Core.
public struct BridgeFeatureFlags: Codable, Sendable {
    public let certificatePinning: Bool
    public let biometricAuth: Bool
    public let jailbreakDetection: Bool
    public let antiDebug: Bool
    public let integrityChecking: Bool

    private enum CodingKeys: String, CodingKey {
        case certificatePinning = "certificate_pinning"
        case biometricAuth = "biometric_auth"
        case jailbreakDetection = "jailbreak_detection"
        case antiDebug = "anti_debug"
        case integrityChecking = "integrity_checking"
    }
}
